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

# The one script that accesses all the functionality.
# Allows programtically adding/deleting of programs and datasets
# to the database without going through the web interface.
class ResourceManager
  def initialize(*args)
    @pretend, @useZipFiles, @replaceFiles, @allowRepeatRuns, username, addArgs, deleteArgs, listArgs, killArgs, processArgs, =
        extractArgs(:args => args, :spec => [
      ['pretend', TrueClass, false],
      ['useZipFiles', TrueClass, false],
      ['replace', TrueClass, false],
      ['allowRepeatRuns', TrueClass, false],
      ['user', String],
      ['add', [String], []],
      ['delete', [String], []],
      ['list', [String], []],
      ['kill', [String], []],
      ['process', [String], []],
    nil])
    #puts "ResourceManager: #{args.join(' ')}"
    @user = username ? User.find_by_username(username) : User.internalUser
    addArgs.each { |arg| add(arg) }
    deleteArgs.each { |arg| delete(arg) }
    listArgs.each { |arg| list(arg) }
    killArgs.each { |arg| kill(arg) }
    processArgs.each { |arg| process(arg) }
  end

  def getFiles(path)
    if File.directory?(path)
      Dir.entries(path)
    else
      `unzip -t '#{path}'`.split(/\n/).map { |x|
        x =~ /testing: ([^ ]+) +OK/ ? $1 : nil
      }.compact
    end
  end
  
  # Hard-coded for supervised learning right now
  def isDataset(files)
    files = files.map { |f| File.basename(f) }
    files.index('metadata') &&
      (files.index('raw') || (files.index('train') || files.index('test')))
  end
  def isProgram(files)
    files = files.map { |f| File.basename(f) }
    files.index('metadata') && files.index('run')
  end

  def add(arg)
    if arg =~ /^([^\/]+)(\/\/\/?)([^\/]+)$/ # learner//dataset (learner///dataset for hyperparameter tuning)
      programs = $1 == "*" ? Program.find(:all) : [Program.findByName($1, RunException)]
      datasets = $3 == '*' ? Dataset.find(:all) : [Dataset.findByName($3, RunException)]
      tuneHyperparameters = $2.size == 3

      programs.each { |program|
        next if program.is_helper
        datasets.each { |dataset|
          next unless Reduction.isTaskTypeDatasetFormatCompatible(program, dataset)
          domain = Domain.get(dataset.format)
          info_spec_obj = domain.runInfoClass.defaultRunInfoSpecObj(domain, program, dataset, tuneHyperparameters)
          str = "run(#{program.name}, #{dataset.name}, hyper=#{tuneHyperparameters})"
          if not @allowRepeatRuns
            runs = Run.findAllByInfoSpecObj(info_spec_obj)
            ids = runs.map{|r| r.id}.join(' ')
            if runs.size > 0
              log "Run(s) #{ids} already exists for #{str}, not adding again (-allowRepeatRuns to override)"
              next
            end
          end
          if @pretend
            puts "ADD #{str}"
            next
          end
          run = Run.new
          begin
            run.init(@user, info_spec_obj)
            run.checkAllProcessed
            log "Added run #{run.id}: #{str}"
          rescue Exception
            log "#{$!} [#{program.name}, #{dataset.name}]"
            log $!.backtrace.join("\n") unless $!.is_a?(RunException) # Something screwed up
            run.destroy
          end
        }
      }
    elsif File.exists?(arg)
      addPath(arg)
    else
      raise "Unknown argument: '#{arg}'; should be either learner//dataset or a path to programs and datasets"
    end
  end

  # Recursively add any directory that looks like it might be a program or dataset
  # (i.e., it has metadata and run/raw file)
  def addPath(path)
    if @useZipFiles
      if File.file?(path) && path =~ /\.zip$/ then # Should use MyFileUtils.zipFile? but that might take too long
        addResource(path)
      end
    end

    if File.directory?(path)
      if @useZipFiles
        Dir["#{path}/*"].each { |subPath| add(subPath) }
      else
        Dir["#{path}/*"].each { |subPath| add(subPath) } if not addResource(path)
      end
    end
  end

  # Return whether any resource got added
  # WARNING: replace is an unsafe operation!  Basically copy the files over and pretend nothing happened.
  # Should be only done internally for evaluators/processors which preserve functionality.
  def addResource(path)
    files = getFiles(path)
    if isDataset(files) then addDataset(path, @replaceFiles)
    elsif isProgram(files) then addProgram(path, @replaceFiles)
    else false
    end
  end
  def getName(path)
    begin
      if File.directory?(path)
        YAML::load(File.read("#{path}/metadata"))['name']
      else if File.file?(path) && path =~ /\.zip$/
        YAML::load(`unzip -cq #{path} metadata`)['name']
      else
        nil
      end
    end
    rescue Exception
      log "Unable to get name of program/dataset [#{path}]"
      nil
    end
  end

  def addDataset(path, replace)
    begin
      if replace
        name = getName(path)
        return unless name
        dataset = Dataset.findByName(name, DatasetException)
        log "REPLACE: #{path} -> #{dataset.path} [#{name}]"
        systemOrFail('rm', '-rf', dataset.path)
      else
        dataset = Dataset.new
      end
      dataset.init(@user, path)
      errors = dataset.checkProper
      if errors.size == 0
        dataset.process
        log "Added dataset #{dataset.name} [#{path}]"
      else
        log "ERROR: " + errors.join('; ') + " [#{path}]"
        dataset.destroy
      end
    rescue Exception
      log "#{$!.message} [#{path}]"
      log $!.backtrace.join("\n") unless $!.is_a?(DatasetException) # Something screwed up
      dataset.destroy if dataset
    end
  end
  def addProgram(path, replace)
    begin
      if replace
        name = getName(path)
        return unless name
        program = Program.findByName(name, ProgramException)
        log "REPLACE: #{path} -> #{program.path} [#{name}]"
        systemOrFail('rm', '-rf', program.path)
      else
        program = Program.new
      end
      program.init(@user, path)
      errors = program.checkProper
      if errors.size == 0
        program.process
        log "Added program #{program.name} [#{path}]"
      else
        log "ERROR: " + errors.join('; ') + " [#{path}]"
        program.destroy
      end
    rescue Exception
      log "#{$!.message} [#{path}]"
      log $!.backtrace.join("\n") unless $!.is_a?(ProgramException) # Something screwed up
      program.destroy if program
    end
  end

  def find(table, spec, defaultKey, &handler)
    key = defaultKey
    joins = []
    if spec =~ /^(.+)=(.+)$/
      key = $1
      spec = $2
      if key == 'status'
        joins << :status
        key = 'run_statuses.status'
      elsif key == 'program'
        joins << :core_program
        key = 'programs.name'
      elsif key == 'dataset'
        joins << :core_dataset
        key = 'datasets.name'
      end
    end
    if spec == '*' then
      matches = table.find(:all)
    elsif spec =~ /^\d+$/
      matches = [table.find(spec.to_i)].compact
    elsif key
      matches = table.find(:all, :joins => joins, :conditions => ["#{key} = (?)", spec])
    else
      matches = []
    end
    matches.each { |obj| handler.call(obj) }
    $stderr.puts "#{matches.size} matches"
  end

  def delete(arg); filter(arg) { |name,x|
    log "Deleting #{name} #{x.id} '#{x.name}'"
    if x.is_a?(Worker)
      EC2Manager.new.terminateAndDestroy(x)
    else
      x.destroy
    end
  } end
  def list(arg); filter(arg) { |name,x| puts x.inspect } end

  def filter(arg, &op)
    arg =~ /^(\w+):(.+)$/ or return
    type, spec = $1, $2
    # OLD: Recursively delete the runs for a program and dataset;
    # OLD: Note: can't use the same instance because (Program|Dataset).runs doesn't get updated!
    # OLD: There must be a way to fix this...
    case type
      when 'user' then find(User, spec, 'username') { |u| u.destroy }
      when 'program' then
        find(Program, spec, 'name') { |p|
          op.call("program", p)
        }
      when 'dataset' then
        find(Dataset, spec, 'name') { |d|
          op.call("dataset", d)
        }
      when 'run' then
        if spec == 'oldRepeats'
          Run.find(:all).each { |r|
            next if r.running?
            others = Run.findAllByInfoSpec(r.info_spec)
            rr = others.find { |rr| rr.id > r.id }
            if rr
              info = r.info
              $stderr.puts "Run #{r.id} is older than #{rr.id} and has same info spec (#{info.coreProgram.name},#{info.coreDataset.name})"
              op.call('run', r)
            end
          }
        else
          find(Run, spec, nil) { |r| op.call('run', r) }
        end
      when 'worker' then find(Worker, spec, 'handle') { |w| op.call(w) }
    end
  end

  def kill(arg)
    find(Run, arg, nil) { |r|
      if r.status.status != 'running'
        log "Run #{r.id} not running"
      else
        w = r.worker
        if not w
          log "ERROR: status is running but has no worker"
        elsif w.current_run != r
          log "ERROR: Assigned worker is working on #{w.current_run ? w.current_run.id : '(none)'} not #{r.id}"
        else
          log "Killing run #{r.id} on worker #{w.id} (on #{w.host})"
          w.killCurrentRun
        end
      end
    }
  end

  # Process a program or dataset
  def process(arg)
    find(Program, arg, 'name') { |p|
      run = p.process
      log "Added run #{run.id} to process dataset #{p.name} (#{p.id})"
    }
    find(Dataset, arg, 'name') { |d|
      run = d.process
      log "Added run #{run.id} to process dataset #{d.name} (#{d.id})"
    }
  end

  def self.checkDomains(*args)
    Domain.names.each { |name|
      puts "Checking domain #{name}..."
      domain = Domain.get(name)
      domain.verify
    }
  end

  def self.main(*args)
    script = "resource"
    if args.size == 0
      puts "Programmatically adds or deletes or lists the database."
      puts
      puts "--- Usages ---"
      puts "#{script} [-zip] [-replace] [-allowRepeatRuns] [-user <user>] -add <path> ..."
      puts "  If path is a zip file, adds it if it is a program or a dataset"
      puts "  If path is a directory, recurse on everything in the directory"
      puts "  -replace: replace the files of a program/dataset without creating a new program."
      puts "#{script} -add (<program name>|*)//(<dataset name>|*) ..."
      puts "  Adds a supervised learning run with this pair (* means all)"
      puts "#{script} (-delete|-list) (dataset|program|run|user|worker):(*|<id>|<name>|<handle>|<field>=<value>|oldRepeats) ..."
      puts "  Example of field/value: run:program=simple-naive-bayes OR run:status=running"
      puts "#{script} -kill <run id> ..."
      puts "#{script} -process <dataset name> ..."
      puts "#{script} checkDomains"
      puts "#{script} validateState"
      puts "#{script} refreshFromSpec"
      puts "#{script} master"
      puts "#{script} commandServer"
      puts "#{script} ec2manager"
      puts "#{script} rateAll"
      puts "#{script} runHighlyRated"
      puts "#{script} periodicUpdate"
      puts
      puts "--- Examples ---"
      puts "#{script} delete dataset:* program:* run:*"
      puts "  wipes the database (be careful!)"
      basePath = ENV['MLCOMP_SOURCE_PATH']
      if basePath
        puts "#{script} add #{basePath}/programs #{basePath}/datasets"
        puts "  populates the database with programs (some vital) and datasets to get started"
      end
      exit 1
    end

    cmd, *restArgs = args
    case cmd
      when 'checkDomains'    then ResourceManager.checkDomains(*restArgs)
      when 'validateState'   then ValidateState.main(*restArgs)
      when 'refreshFromSpec' then RefreshFromSpec.main(*restArgs)
      when 'master'          then RunMaster.main(*restArgs)
      when 'commandServer'   then CommandServer.main(*restArgs)
      when 'ec2manager'      then EC2Manager.main(*restArgs)
      when 'rateAll'         then RatingEngine.new.rateAll(*restArgs)
      when 'runHighlyRated'  then RatingEngine.new.runHighlyRated(*restArgs)
      when 'periodicUpdate'  then
        RatingEngine.new.rateAll(*restArgs)
        RatingEngine.new.runHighlyRated(*restArgs)
      else
        ResourceManager.new(*args)
    end
  end
end
