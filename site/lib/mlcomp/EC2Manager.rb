# The EC2 manager is in charge of automatically starting/terminating ec2 instances based on load.
# Worker handles are the instance IDs.
# Policy:
#  - Create a new instance/worker if the longest wait time for any job in the queue (status ready) has exceeded maxWaitTime.
#    Don't start two instances more than minStartInstanceInterval apart.
#  - Terminate an existing instance/worker if it has been running idle for more than maxIdleTime.

class EC2Manager
  def EC2Manager.main(*args)
    manager = EC2Manager.new(args)
    manager.loop
  end

  #def clearKeys
  #  # Get rid of stale keys (just get rid of all of them)
  #  path = ENV['HOME']+'/.ssh/known_hosts'
  #  puts "Removing #{path}"
  #  File.delete(path) if File.exists?(path)
  #end

  def systemAndLog(cmd, numAttempts=1)
    log "RUNNING: #{cmd}"
    waitTime = 10
    if not system(cmd)
      if numAttempts <= 1
        Notification.notify_error(:message => "EC2Manager failed on: #{cmd}")
        raise "ERROR on command: #{cmd}"
      else
        log "FAILED #{cmd}, waiting #{waitTime} second before trying again..."
        sleep waitTime
        #clearKeys
        systemAndLog(cmd, numAttempts-1)
      end
    end
  end
  def systemAndLogReturnOutput(cmd) # Returns output but doesn't display stdout
    log "RUNNING (returning output): #{cmd}"
    output = `#{cmd}`
    if $? != 0
      Notification.notify_error(:message => "EC2Manager failed on: #{cmd}")
      raise "ERROR on command: #{cmd}"
    end
    output
  end

  def initialize(args)
    @verbose, @ami, @zone, @instanceType, @minWorkers, @maxWorkers,
    @maxWaitTime, @minStartInstanceInterval, @maxIdleTime,
        = extractArgs(:args => args, :spec => [
      ['verbose', Fixnum, 0],
      ['ami', String, 'ami-a630cbcf'], # worker5 (worker version 30)
      ['zone', String, 'us-east-1a'],
      ['instanceType', String, 'm1.small'],
      ['minWorkers', Fixnum, 0],
      ['maxWorkers', Fixnum, 10],
      ['maxWaitTime', Fixnum, 2 * 60], # Launch worker after job has waited this amount of time
      ['minStartInstanceInterval', Fixnum, 20], # Don't start up too many instances at once
      ['maxIdleTime', Fixnum, 1 * 60 * 60], # Bring down worker after this much time (Don't waste EC2 credits)
    nil])

    @badWorkerHandles = {}
    @lastStartedTime = 0
    log "EC2 manager started"
  end

  def loop
    while true
      break if File.exists?('STOP')
      checkWorkers
      checkIfShouldStart
      checkIfShouldTerminate
      sleep 5
    end
  end

  def checkWorkers
    newBadWorkerHandles = []
    Worker.find(:all).each { |worker|
      if (not worker.active?) && (not @badWorkerHandles[worker.handle])
        @badWorkerHandles[worker.handle] = true
        newBadWorkerHandles << worker.handle
      end
    }
    if newBadWorkerHandles.size > 0
      Notification.notify_error(:message => "EC2Manager: found inactive workers: #{newBadWorkerHandles.join(' ')}")
    end
  end

  def printDivider
    log "============================== #{Time.now.strftime("%Y-%m-%d %H:%M:%S")}"
  end

  def shouldStart
    #numWorkers = Worker.countActive # Not reliable!
    #numWorkers = Worker.countActiveManual # Dangerous - could start too many workers
    numWorkers = Worker.count # All workers (active and inactive)

    # Don't start too many workers
    if Time.now.to_i < @lastStartedTime + @minStartInstanceInterval
      log "checkIfShouldStart: started instance recently, so holding off" if @verbose >= 2
      return false
    end
    if numWorkers >= @maxWorkers
      log "checkIfShouldStart: already have #{numWorkers}, no more" if @verbose >= 1
      return false
    end

    # If have fewer than requisite number, then should definitely start
    if numWorkers < @minWorkers
      Notification.notify_error(:message => "EC2Manager has #{numWorkers} < #{@minWorkers} running (anomaly)")
      log "checkIfShouldStart: numWorkers=#{numWorkers} fewer than minWorkers=#{@minWorkers}, must start now"
      # TODO: Sometimes countActive = 0 when there's clearly a worker; what's going on here???
      #puts "  DEBUG countActive = #{Worker.countActive}"
      #n = 0
      #Worker.find(:all).each { |worker|
        #puts "  DEBUG #{worker.handle}: updated_at = #{worker.updated_at}, now = #{Time.now}, active = #{worker.active?}"
        #n += 1 if worker.active?
      #}
      #puts "  DEBUG manual countActive = #{n}"
      #numWorkers = n
      return true
    end

    # Theoretical number (cases were some workers not responsive for a while, and some runs have crashed and are still marked running)
    numFreeWorkers = numWorkers - Run.countByStatus('running')

    if numWorkers == 0 # If no workers, don't ever wait to start one!
      numReadyRuns = Run.count(:all, :include => :status, :conditions => ['run_statuses.status = (?)', 'ready'])
    else # Only consider jobs that have waited a while
      numReadyRuns = Run.count(:all, :include => :status, :conditions => ['run_statuses.status = (?) AND now() > runs.created_at + (?)', 'ready', @maxWaitTime])
    end

    if numReadyRuns > numFreeWorkers # More runs than workers that can take them
      printDivider
      log "checkIfShouldStart: #{numReadyRuns} ready runs that have waited for more than #{@maxWaitTime} seconds, so starting new instance..."
      return true
    end

    log "checkIfShouldStart: No long-waiting queued jobs, no need to start instance" if @verbose >= 2
    return
  end
  def checkIfShouldStart
    return unless shouldStart
    # Start instance now
    systemAndLogReturnOutput("ec2-run-instances #{@ami} -z #{@zone} -t #{@instanceType} -k pliang-key").split(/\n/).each { |line|
      # INSTANCE i-3ea74257 ami-6ba54002 pending
      next unless line =~ /^INSTANCE\s+(i-\S+)/
      instance_id = $1

      # Create a worker
      log "checkIfShouldStart: Starting instance #{instance_id}"
      
      # Wait until the worker is ready
      host = nil
      while host == nil
        log "Waiting for #{instance_id} to be ready..."
        found = false
        systemAndLogReturnOutput("ec2-describe-instances").split(/\n/).each { |line|
          # INSTANCE        i-b71674df      ami-48aa4921    ec2-75-101-184-106.compute-1.amazonaws.com      domU-12-31-39-07-54-31.compute-1.internal      running  pliang-key      0               c1.medium       2009-11-18T11:11:28+0000        us-east-1c      aki-6eaa4907    ari-42b95a2b           monitoring-disabled      75.101.184.106  10.209.87.191
          next unless line =~ /^INSTANCE\s+#{instance_id}/
          found = true
          log line if @verbose >= 2
          if line =~ /\spending/
            sleep 5
          else
            host = line.split[3]
          end
        }
        if not found
          raise "Launched #{instance_id}, but doesn't show up in ec2-describe-instances"
        end
      end
      log "checkIfShouldStart: Instance #{instance_id} is ready on #{host}"

      #clearKeys

      log "checkIfShouldStart: Copying files to worker"
      begin
        systemAndLog("ssh -o StrictHostKeyChecking=no #{host} hostname", 50) # Just wait for server to be ssh'able
        systemAndLog("echo #{instance_id} | ssh -o StrictHostKeyChecking=no #{host} bash -c 'cat > worker/workerHandle'", 10)
        systemAndLog("hostname -f | ssh -o StrictHostKeyChecking=no #{host} bash -c 'cat > worker/server'", 10)
      rescue Exception => e
        log "checkIfShouldStart: failed to initialize worker, terminating the instance #{instance_id}"
        systemAndLog("ec2-terminate-instances #{instance_id}")
        return
      end

      # Actually create the worker entry in the database
      log "checkIfShouldStart: Creating worker DB entry"
      worker = Worker.new
      worker.handle = instance_id
      worker.host = host
      worker.user = User.internalUser
      worker.last_run_time = Time.now # Used to measure idle time of worker
      worker.save!
      @lastStartedTime = Time.now.to_i

      log "checkIfShouldStart: Starting actual worker #{instance_id}"
      systemAndLog("ssh #{host} 'cd worker && (./worker >& worker.log &)'")
      log "checkIfShouldStart: Done starting worker #{instance_id}"
      printDivider
      log
    }
  end

  def checkIfShouldTerminate
    # Get workers that haven't run anything in a while
    # Runs might be deleted leaving id not null (when worker crashes), so we need to test worker.current_run != nil in Ruby code
    workers = Worker.find(:all, :conditions => ['now() > last_run_time + (?)', @maxIdleTime]).delete_if { |worker| worker.current_run != nil }

    # Save any minWorkers active workers
    saveWorkers = workers.map { |worker| worker.active? ? worker : nil }.compact
    saveWorkers = saveWorkers[0...@minWorkers]

    if workers.size == 0
      log "checkIfShouldTerminate: No workers that have been idle for a long time" if @verbose >= 2
      return
    end
    workers.each { |worker|
      if saveWorkers.index(worker)
        log "checkIfShouldTerminate: keeping active worker #{worker.handle} (one of #{saveWorkers.size} workers to save)" if @verbose >= 2
        next
      end
      log "checkIfShouldTerminate: Found worker #{worker.handle} that has been idle for more than #{@maxIdleTime}"
      if worker.handle =~ /^i-/
        log "checkIfShouldTerminate: terminating instance #{worker.handle} and deleting worker"
        terminateAndDestroy(worker)
        printDivider
        log
      else
        log "checkIfShouldTerminate: can't terminate because #{worker.handle} is not an ec2 instance number"
      end
    }
  end

  def terminateAndDestroy(worker)
    systemAndLog("ec2-terminate-instances #{worker.handle}")
    worker.destroy
  end
end
