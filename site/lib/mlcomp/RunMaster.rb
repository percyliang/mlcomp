# MLcomp: website for automatic and standarized execution of algorithms on datasets.
# Copyright (C) 2010 by Percy Liang and Jake Abernethy
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# The run master dispatches runs from the databases to workers.
# The workers pull the master for stuff to do.
# The master must make a self-contained package for the workers
# which doesn't reference runs at all.

# IMPORTANT: must be able to ssh into the worker without a password!

require 'xmlrpc/server'

class RunMaster
  def RunMaster.main(*args)
    RunMaster.new(args)
  end

  # Return response
  def performSafely(&block)
    # Need to synchronize; otherwise two requests to the same server causes problems
    begin
      @mutex.lock
      result = block.call
      @mutex.unlock
      result
    rescue Exception => e
      @mutex.unlock if @mutex.locked?
      log "EXCEPTION: #{e.message}\n#{e.backtrace.join("\n")}"
      # Mysql::Error: Lost connection to MySQL server during query: SELECT * FROM `workers`
      # If a really bad error occurred, then we shutdown the server 
      if not [ProgramException, DatasetException, RunException, WorkerException].find { |t| e.is_a?(t) } then
        if not @shutdown_server
          @shutdown_server = true # Remember, so we don't try to shutdown too many times
          Notification::notify_error(:message => "RunMaster exception: #{e.message}")
          puts "Shutting down server..."
          @server.shutdown
          puts "Server shutdown."
        end
      end
      failedResponse(e.message)
    end
  end

  def initialize(args)
    # TODO: this doesn't work as intended
    #puts "Starting thread to maintain connectivity to MySQL..."
    #@active = true
    #@pingThread = Thread.new {
    #  while @active
    #    puts "ping #{Program.count}"
    #    sleep 10
    #  end
    #}

    @mutex = Mutex.new

    # local: accept connections only locally (hack for master to work for Macs, because * works)
    port, local, @verbose = extractArgs(:args => args, :spec => [
      ['port', Fixnum, 8712],
      ['local', TrueClass, false],
      ['verbose', Fixnum, 0],
    nil])

    log "Starting http server on port #{port}..."
    @server = XMLRPC::Server.new(port, local ? IPSocket.getaddress(Socket.gethostname) : "*", 1000)

    @server.add_handler("GetNewWorkerHandle") { |username,password|
      performSafely { getNewWorkerHandle(username, password) }
    }

    @server.add_handler('GetJob') { |workerHandle,opts|
      performSafely { getJob(workerHandle,opts) }
    }

    @server.add_handler("SetWorkerStatus") { |workerHandle,status|
      performSafely { setWorkerStatus(workerHandle, status) }
    }

    @server.add_handler("GiveUpOnJob") { |workerHandle|
      performSafely { giveUpOnJob(workerHandle) }
    }

    @server.add_handler("SetJobResult") { |workerHandle,result|
      performSafely { setJobResult(workerHandle, result) }
    }

    # If this happens, the worker is messed up
    @server.set_default_handler { |name, *args|
      raise XMLRPC::FaultException.new(-99, "Method '#{name}' missing or wrong number of parameters!")
    }

    @server.serve

    #puts "Joining thread...."
    #@active = false
    #@pingThread.join if @pingThread
  end

  def getNewWorkerHandle(username, password)
    user = User.authenticate(username, password)
    if user # Good
      worker = Worker.new
      worker.handle = rand(1000000000)
      #worker.handle = Guid.new.to_s
      worker.host = "unknown" # FUTURE: how to get the host from the request
      worker.user = user
      worker.saveOrRaise(true)
      response = successResponse('message' => 'New worker created')
      response['handle'] = worker.handle
      response
    else
      failedResponse('Invalid username/password')
    end
  end

  def systemAndLog(cmdArgs, numAttempts=1)
    cmd = cmdArgs.join(' ')
    log "RUNNING: #{cmd}"
    waitTime = 10
    if not system(*cmdArgs)
      if numAttempts <= 1
        Notification.notify_error(:message => "RunMaster failed on: #{cmd}")
        return false
      else
        log "FAILED #{cmd}, waiting #{waitTime} second before trying again..."
        sleep waitTime
        systemAndLog(cmdArgs, numAttempts-1)
      end
    end
    return true
  end

  # Return whether it was successful
  def copyContents(source, dest, numTrials)
    convert = lambda { |x|
      if x.is_a?(Run)
        x.path
      elsif x.is_a?(Hash)
        contentsHost = getField(x, 'contentsHost')
        contentsLocation = getField(x, 'contentsLocation')
        "#{contentsHost}:#{contentsLocation}"
      elsif x.is_a?(String)
        x
      else
        raise "Unexpected object: #{x.inspect}"
      end
    }
    source = convert.call(source)
    dest = convert.call(dest)

    cmdArgs = ['scp', '-o', 'StrictHostKeyChecking=no', '-r', source, dest]
    #cmdArgs = ['rsync', '-Lr', '-e', 'ssh -o StrictHostKeyChecking=no', source+'/*', dest]
    systemAndLog(cmdArgs, numTrials)

    #log "Copying contents: #{cmd.join(' ')}"
    #if not system(*cmd)
      #s = "Copying contents failed (#{cmd.join(' ')})"
      #Notification::notify_error(:message => s)
      #return s
    #end
    #nil
  end

  def getJob(workerHandle, opts)
    log "getJob: #{workerHandle} #{opts.inspect}" if @verbose >= 1
    worker = Worker.findByHandle(workerHandle)
    if worker.current_run
      Notification::notify_error(:message => "Worker #{worker.handle} not done with run #{worker.current_run.id} but is asking for new one, assuming gave up")
      ensureNoRun(worker)
      return failedResponse("You haven't finished run #{worker.current_run.id}, assuming gave up")
    end

    # See if we have a run to execute
    run = getRun(worker)
    if run # Yes
      log "Creating new job for run #{run.id}"
      command = nil
      begin
        command = run.startRun
      rescue Exception
        run.status.status = "failed" 
        run.status.save!
        run.result = YAML.dump('success' => false, 'message' => "Unable to start run: #{$!}")
        run.save!
        log $!.backtrace.join("\n") # Something screwed up
      end
      if command
        # Copy contents over first
        if not copyContents(run, opts, 5)
          # Really should set status to an error status not 'failed' - error due to internal badness; for now, just leave 'running'
          #self.status.status = 'ready'
          #self.status.save
          return successResponse("No job available (copy failed)")
        end

        job = successResponse('Got job')
        setField(job, 'id', run.id) # run id
        setIntField(job, 'allowedTime', run.allowed_time) if run.allowed_time
        setIntField(job, 'allowedMemory', run.allowed_memory) if run.allowed_memory
        setIntField(job, 'allowedDisk', run.allowed_disk) if run.allowed_disk
        setField(job, 'command', command)
        #log "  zipping up #{run.path}..."
        #setBase64Field(job, 'contents', zipDirContents(run.path))
        setField(job, 'returnContents', run.processed_dataset != nil) # Return contents if data-processing run

        worker.current_run = run
        worker.save!
        run.worker = worker
        run.save!
        job
      else
        #failedResponse('Available job already failed') # Don't give worker a hard time
        successResponse('No job available (job already failed during init)')
      end
    else # No
      successResponse('No job available')
    end
  end

  def setWorkerStatus(workerHandle, status)
    worker = Worker.findByHandle(workerHandle)

    # Populate worker fields
    worker.host = getField(status, 'host')
    worker.num_cpus = getIntField(status, 'numCPUs')
    worker.cpu_speed = getIntField(status, 'cpuSpeed')
    worker.max_memory = getIntField(status, 'maxMemory')
    worker.max_disk = getIntField(status, 'maxDisk')
    worker.version = getIntField(status, 'workerVersion')
    worker.last_run_time = Time.new if worker.current_run
    worker.save!

    run = worker.current_run

    if run
      # Write log file (optional)
      if status['jobLog']
        contents = getBase64Field(status, 'jobLog')
        #log "Appending #{contents.size} bytes to #{run.path}/log"
        out = open(run.path+"/log", "a")
        out.write(contents)
        out.close
      end

      # Update status
      if status['jobMemory'] # Any field
        runStatus = run.status
        runStatus.memory_usage = getIntField(status, 'jobMemory')
        runStatus.max_memory_usage = [runStatus.max_memory_usage || 0, runStatus.memory_usage].max
        runStatus.disk_usage = getIntField(status, 'jobDisk')
        runStatus.max_disk_usage = [runStatus.max_disk_usage || 0, runStatus.disk_usage].max
        runStatus.real_time = getIntField(status, 'jobRealTime')
        runStatus.user_time = getIntField(status, 'jobUserTime')
        runStatus.save
      end
    end
    
    # Send the command (e.g., to kill the job) if there is one
    response = successResponse('Acknowledged')
    if worker.command
      log "COMMAND TO WORKER #{worker.handle}: #{worker.command}"
      setField(response, 'command', worker.command)
      worker.command = nil
      worker.save!
    else
      workerPath = "#{ENV['MLCOMP_SOURCE_PATH']}/worker"
      currentWorkerVersion = IO.readlines("#{workerPath}/version")[0].to_i
      if worker.version != currentWorkerVersion
        log "COMMAND TO WORKER #{worker.handle}: update from version #{worker.version} to #{currentWorkerVersion}"
        setField(response, 'command', 'updateVersion')
        setBase64Field(response, 'contents', zipDirContents(workerPath))
      end
    end

    response
  end

  def ensureNoRun(worker)
    if worker.current_run
      if worker.current_run.status.status == 'running'
        log "Worker #{worker.handle} hasn't finished old run #{worker.current_run.id} yet, assume giving up"
        worker.current_run.giveUp
      else
        log "Worker #{worker.handle} was working on old run #{worker.current_run.id}, but it's somehow no longer running"
      end
      worker.current_run = nil
      worker.save!
    end
  end

  def giveUpOnJob(workerHandle)
    worker = Worker.findByHandle(workerHandle)
    run = worker.current_run
    if run
      ensureNoRun(worker)
      successResponse("Ok, you gave up on run #{run.id}")
    else
      successResponse("You didn't have any runs anyway")
    end
  end

  def setJobResult(workerHandle, result)
    worker = Worker.findByHandle(workerHandle)
    id = getField(result, 'id') # What worker says he's working on
    run = worker.current_run # What master says the worker is working on
    if not run
      return failedResponse("Worker claimed to have finished run #{id}, but master says worker was working on nothing (probably run was deleted); ignoring worker's result")
    end
    oldId = run.id
    if oldId != id
      return failedResponse("Worker claimed to have finished run #{id}, but master says worker was working on run #{oldId}; ignoring worker's result")
    end

    exitCode = getField(result, 'exitCode')

    # Get contents from zip file
    #if result['contents'] # This is typically too big, so only set for data processing runs (deprecated)
      #log "Installing contents of results..."
      #contents = getBase64Field(result, 'contents')
      #zipPath = MyFileUtils.getTmpPath(".zip")
      #out = open(zipPath, "w")
      #out.write(contents)
      #out.close
      #contentsPath = MyFileUtils.getTmpPath("")
      #Dir.mkdir(contentsPath)
      #systemOrFail('unzip', '-q', zipPath, '-d', contentsPath)
      #File.unlink(zipPath)
      #systemOrFail('rm', '-rf', run.path) # Delete old run directory
      #File.rename(contentsPath, run.path) # Replace with new one
    #end
    if result['contentsHost'] && result['contentsLocation']
      tmpPath = MyFileUtils.getTmpPath("")
      log "Installing contents of results... (-> #{tmpPath} -> #{run.path})"
      if copyContents(result, tmpPath, 1)
        systemOrFail('rm', '-rf', run.path) # Delete old run directory
        File.rename(tmpPath, run.path) # Replace with new one
      end
    end
    if result['status']
      log "Installing status file..."
      status = getBase64Field(result, 'status')
      out = open(run.path+'/status', 'w') # Note: don't write it into program0/status because program0 is a symlink
      out.puts status
      out.close
    end
    if result['log']
      log "Installing log file..."
      log = getBase64Field(result, 'log')
      out = open(run.path+'/log', 'w')
      out.puts log
      out.close
    end

    run.finishRun(exitCode) # Update database with the run status

    worker.current_run = nil
    worker.save!

    successResponse('Job completed')
  end

  # Return a string representing the contents of a zip file of path
  def zipDirContents(path)
    zipPath = MyFileUtils.getTmpPath(".zip")
    changePath(path) {
      systemOrFail('zip', '-q', '-r', File.expand_path(zipPath), '.')
    }
    contents = File.read(zipPath)
    File.unlink(zipPath)
    contents
  end

  # Return a run for this worker or nil if none is available/suitable.
  def getRun(worker)
    # Select the run belonging to the user that has the smallest recent_spent_time
    # Break ties by run.id (runs of same user created earlier go first - FIFO)
    sql = ActiveRecord::Base.connection
    id = (sql.execute("select runs.id from (runs inner join run_statuses on runs.id = run_statuses.run_id) inner join user_vresults on runs.user_id = user_vresults.user_id where run_statuses.status = 'ready' order by user_vresults.recent_spent_time, runs.id limit 1").fetch_row || [])[0]
    id && Run.find(id)
  end

  # Every response is one of these two
  def successResponse(message)
    response = {}
    response['success'] = true
    response['message'] = message
    response
  end
  def failedResponse(message)
    response = {}
    response['success'] = false
    response['message'] = message
    response
  end

  # Get/set fields
  # Note: we need to convert integers to string because
  # integers might be too big (Bignum) for XMLRPC
  def getField(map, key); map[key] or raise "Missing field '#{key}'" end
  def getIntField(map, key); getField(map, key).to_i end
  def getBase64Field(map, key); XMLRPC::Base64.decode(getField(map, key)) end
  def setField(map, key, value); raise "Empty value not allowed for '#{key}'" if value == nil; map[key] = value end
  def setIntField(map, key, value); setField(map, key, value.to_s) end
  def setBase64Field(map, key, value); setField(map, key, XMLRPC::Base64.encode(value)) end
end
