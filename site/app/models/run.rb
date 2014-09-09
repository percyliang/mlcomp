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

require 'lib_autoloader'

# A run is specified by
#  - user
#  - RunSpecification (runSpecObj): a tree (represented by a YAML string)
#    Each node is [type, data, [child_1, ..., child_n]], where type is program, dataset, or string
#    Non-leaf nodes are program IDs
#  - RunInfo (@info): provides logic for constructing a RunSpecification and displaying information.
#    This is serialized as a specification (info_spec is the YAML string, info_spec_obj is the Specification object).
#  - redundant for easy access: list of programs and datasets used
#  - status (reported by the runner)
#  - result (reported by the program): a tree (represented by a YAML string)
#    Each node is {key_1 => value_1, ..., key_n => value_n}
# Keep this class generic, without a notion of machine learning or specific tasks.
#
# Two ways a run could be created:
#   init(): info_spec_obj given
#   read from the database: info_spec -> info_spec_obj
class Run < ActiveRecord::Base
  
  acts_as_commentable
  
  belongs_to :user
  has_one :status, :class_name => "RunStatus", :dependent => :destroy

  # Who is running me?
  belongs_to :worker

  # If this is a processing run
  belongs_to :processed_program, :class_name => "Program", :foreign_key => "processed_program_id"
  belongs_to :processed_dataset, :class_name => "Dataset", :foreign_key => "processed_dataset_id"

  has_many :run_datasets, :dependent => :destroy
  has_many :datasets, :through => :run_datasets #, :order => 'run_datasets.id'

  has_many :run_programs, :dependent => :destroy
  has_many :programs, :through => :run_programs #, :order => 'run_programs.id'

  # Note core_program and core_dataset, like sort[0-5] are for convenience
  # The information is all contained in info
  belongs_to :core_program, :class_name => "Program", :foreign_key => "core_program_id"
  belongs_to :core_dataset, :class_name => "Dataset", :foreign_key => "core_dataset_id"

  # get error: primary_key
  #has_one :user_vresult, :class_name => "User::Vresult", :primary_key => "user_id", :foreign_key => "user_id"

  def info
    if not @info
      # Construct the info object given info_spec (DB field)
      info_spec_obj = Specification.parse(self.info_spec)
      c, *args = info_spec_obj.tree
      @info = c.new(*args)
      @info.run = self
    end
    @info
  end
  def runSpecObj
    if not @runSpecObj then
      @runSpecObj = info.getRunSpecObj
    end
    @runSpecObj
  end

  def self.findAllByInfoSpec(info_spec)
    Run.find(:all, :conditions => ['info_spec = (?)', info_spec])
  end
  def self.findAllByInfoSpecObj(info_spec_obj)
    self.findAllByInfoSpec(info_spec_obj.to_yaml)
  end

  def path
    raise "No path" unless self.id
    Constants::RUNS_DEFAULT_BASE_PATH + "/#{self.id}"
  end

  def name
    programName = self.info.coreProgram && self.info.coreProgram.name
    datasetName = self.info.coreDataset && self.info.coreDataset.name
    "(#{programName},#{datasetName})"
  end

  # Had hyperparameter tuning done
  def tuneHyperparameters
    if defined?(info.tuneHyperparameters)
      info.tuneHyperparameters
    else
      nil
    end
  end

  # (Converts result (a string) into a structured object)
  # If result gets updated (as a string), we update the tree
  def resultTree
    if @savedResult != result
      @savedResult = result
      begin
        @savedResultTree = result && result != "" ? YAML.load(result) : {}
      rescue Exception
        @savedResultTree = {}
      end
    end
    @savedResultTree
  end

  def checkAllProcessed
    programs.each { |program|
      raise RunException.new("Run depends on unprocessed program #{program.id} (#{program.name})") unless program.is_helper || program.process_status == 'success'
    }
    datasets.each { |dataset|
      raise RunException.new("Run depends on unprocessed dataset #{dataset.id} (#{dataset.name})") unless dataset.process_status == 'success'
    }
  end

  def init(user, info_spec_obj)
    self.user = user
    self.status = RunStatus.new
    self.status.status = 'ready'
    setProcessedProgramDatasetStatus('none')
    self.info_spec = info_spec_obj.to_yaml

    setFromInfoSpec

    # FUTURE: get these values dynamically from user
    self.allowed_time = 5 * 60*60 # 5 hours
    self.allowed_memory = 1.5 * 1024*1024*1024 # 1.5G
    self.allowed_disk = 10 * 1024*1024*1024 # 10G (FUTURE: actually enforce this)
    self.saveOrRaise(true)
  end
  def destroy
    if self.worker && self.worker.current_run == self
      log "Deleting run #{self.id}, which is running on worker #{self.worker.handle}; telling it to terminate the run"
      self.worker.killCurrentRun
    end
    self.deleteFromFilesystem
    super
  end

  def setFromInfoSpec
    self.specification = self.runSpecObj.to_yaml
    self.programs = self.runSpecObj.programs
    self.datasets = self.runSpecObj.datasets
    self.core_program = info.coreProgram
    self.core_dataset = info.coreDataset
    self.save
  end

  def invokeCommand(program, name, *args)
    #args = args.map { |x| "'"+x.gsub(/'/, "\\'")+"'" } # Quote all args
    args = args.map { |x| '"'+x.gsub(/"/, "\\\"")+'"' } # Quote all args (use double quotes so can use environment variables)
    "(cd #{program} && ./run #{name} #{args.join(' ')}) || exit 1"
  end

  def readyToExecute?; ActiveRecord::Base.silence {self.status.status == 'ready'} end

  # This is called when a worker fails to deliver;
  # then we're eligible for another worker
  def giveUp
    self.status.status = 'ready'
    setProcessedProgramDatasetStatus('none')
    self.status.save
  end

  # Call this after result is set
  def setSortFields
    self.sort0 = info.getSortField(0)
    self.sort1 = info.getSortField(1)
    self.sort2 = info.getSortField(2)
    self.sort3 = info.getSortField(3)
    self.sort4 = info.getSortField(4)
    self.sort5 = info.getSortField(5)
    self.error = info.getError
  end
  def getSortField(i)
    case i
      when 0 then self.sort0
      when 1 then self.sort1
      when 2 then self.sort2
      when 3 then self.sort3
      when 4 then self.sort4
      when 5 then self.sort5
    end
  end

  def deleteFromFilesystem
    if self.id && File.exists?(self.path)
      FileUtils.remove_dir(self.path)
    end
  end

  # Save or throw an exception
  def saveOrRaise(validate)
    raise RunException.new("Unable to save run #{self.id}: #{errors.full_messages.join('; ')}") if not save(validate)
  end

  # Return an array mapping node id to directory name
  def getDirs
    dirs = []
    spec = self.runSpecObj
    spec.nodes.each { |node_id,node,children|
      case node
        when Program, Dataset
          dirs[node_id] = "#{node.class.to_s.downcase}#{node_id}"
      end
    }
    dirs
  end

  def setProcessedProgramDatasetStatus(status)
    if self.processed_program
      self.processed_program.process_status = status
      self.processed_program.save
    end
    if self.processed_dataset
      self.processed_dataset.process_status = status
      self.processed_dataset.save
    end
  end

  # Copy everything in place and return a command to run
  def startRun
    log "===== START RUN #{id} ====="
    self.status.status = 'running'
    setProcessedProgramDatasetStatus('inprogress')
    self.status.save
    spec = self.runSpecObj

    # Copy programs and datasets to the run directory
    if File.exists?(self.path)
      log "Run path already exists, deleting and starting over..."
      systemOrFail('rm', '-rf', self.path)
    end
    Dir.mkdir(self.path)
    dirs = getDirs
    spec.nodes.each { |node_id,node,children|
      case node
        when Program, Dataset
          unless File.exists?(node.path)
            log "Internal error: directory doesn't exist: #{node.path}"
            raise "Internal error: directory doesn't exist: #{node.path}"
          end
          systemOrFail('ln', '-s', node.path, self.path+"/"+dirs[node_id])
      end
    }

    # Construct each of the program
    commands = []
    spec.nodes.each { |node_id,node,children|
      next unless node.class == Program
      args = children.map { |child_id,child|
        case child
          when Program, Dataset then "../"+dirs[child_id]
          else child.to_s
        end
      }
      commands << invokeCommand(dirs[node_id], 'construct', *args)
    }
    # Run main program
    commands << invokeCommand(dirs[0], 'execute')

    # Create a single script to execute all these commands
    scriptName = "main"
    IO.writelines(self.path+'/'+scriptName,
      ['#!/bin/bash', ''] +
      ['echo "Running program, redirecting console output to the log file..."'] +
      (self.allowed_memory ? ["ulimit -v #{(self.allowed_memory/1024).to_i} &&"] : []) +
      (self.allowed_time ? ["ulimit -t #{self.allowed_time.to_i} &&"] : []) +
      ['ln -sf program0/status &&'] +
      ["cd `dirname $0` && time ("] +
      commands.map { |cmd| "  #{cmd};" } +
      [") > log 2>&1"]
      #[") < /dev/null > log 2>&1"] # {07/05/11} piping /dev/null eats up the exit code for some reason (found this running on collaborativefiltering-sample)
      #[") < /dev/null 2>&1 | tee log"] # Can't use this because we need the exit code of the command and tee eats that up
    )
    systemOrFail('chmod', '+x', self.path+'/'+scriptName)

    # README
    lines = []
    lines << "This directory contains all the programs/datasets necessary to replicate run #{self.id}."
    lines << "To execute this run, type:"
    lines << "  ./main"
    lines << "Standard out will be saved to the file \"log\"."
    lines << "Other results are written to the \"status\" files in the various program directories."

    lines << "Below are the relevant programs and datasets:"
    lines << '---'
    lines += spec.nodes.sort {|a,b| a[0] <=> b[0]}.map { |node_id,node,children|
      case node
        when Program, Dataset
          "#{dirs[node_id]}: #{node.name} (id=#{node.id}, created by #{node.user && node.user.username}) [#{node.description}]"
        else
          nil
      end
    }.flatten.compact
    IO.writelines(self.path+"/README", lines)

    "bash "+scriptName
  end

  # Whether we need to fetch the full results
  def needFullResults; self.processed_dataset != nil end

  def finishRun(exitCode, fullResultsPath=nil)
    log "===== FINISH RUN #{id} ====="

    dirs = getDirs
    map = readStatus(self.path)
    # Let user decide success through the status file,
    # but if it doesn't exist, base success on exit code
    map['success'] = (exitCode == 0) unless map.has_key?('success')
    map['exitCode'] = exitCode
    success = map['success']

    # If I'm a program processing run, then mark program as processed (either success or failed).
    if self.processed_program
      self.core_program.process_status = success ? "success" : "failed"
      self.core_program.saveOrRaise(true)
    end

    # If I'm a dataset processing run, then mark dataset as processed (either success or failed).
    # Also copy the dataset back.
    if self.processed_dataset
      sourcePath = fullResultsPath+"/"+dirs[1]
      if success && File.directory?(sourcePath) # Copy it over
        self.processed_dataset.deleteFromFilesystem
        log "Installing processed dataset (#{sourcePath} -> #{self.processed_dataset.path})..."
        recursiveCopy(sourcePath, self.processed_dataset.path)
        self.processed_dataset.disk_size = MyFileUtils.getDiskSize(self.processed_dataset.path)
      else
        log "Dataset processing failed (success=#{success}, sourcePath=#{sourcePath})"
        success = map['success'] = false
        map['message'] = "Dataset processing failed (internal error)"
      end
      self.processed_dataset.process_status = success ? "success" : "failed"
      self.processed_dataset.result = YAML.dump(map)
      self.processed_dataset.setSortFields
      begin
        self.processed_dataset.saveOrRaise(true)
      rescue Exception => e
        success = false
      end
    end
    
    # Save results to database
    self.result = YAML.dump(map)
    self.setSortFields
    self.saveOrRaise(true)
    self.status.status = success ? 'done' : 'failed'
    self.status.save
    log "Status: #{self.status.status}"
    Notification::notify_event(:message => "Run #{self.id}:#{self.name} of #{self.user && self.user.username} finished: #{self.status.status}")
  end

  # return at most maxLines lines of the log file
  def logContents(maxLines=400)
    # Show the last maxLines lines
    logPath = self.path+"/log"
    return nil unless File.exists?(logPath)
    result = `tail -#{maxLines+1} '#{logPath}'` # WARNING: quoting path (self.path should be sanitized)
    return nil unless result # Shouldn't happen
    lines = result.split(/\n/)
    lines[0] = '... (lines omitted) ...' if lines.size == maxLines+1
    lines
  end
  def logContentsStr
    (self.logContents || []).map { |s| CGI.escapeHTML(s).chomp+"\n" }.join('')
  end

  def self.countByStatus(status)
     Run.count(:joins => :status, :conditions => ["run_statuses.status = (?)", status])
  end

  def self.runningRuns
     Run.find(:all, :joins => :status, :conditions => ["run_statuses.status = (?)", 'running'])
  end

  def running?; self.status.status == 'running' && self.worker end

  def restricted_access(user); (self.programs + self.datasets).find {|p| p.restricted_access && p.user != user} end
  
  def self.existingRuns(program, dataset)
    Run.find(:all, :conditions => ['core_program_id = ? AND core_dataset_id = ?', program, dataset])
  end

  # Return a matrix, each cell is a list of runs for that program/dataset
  def self.existingRunsMatrix(programs, datasets)
    programs.map { |program|
      datasets.map { |dataset|
        self.existingRuns(program, dataset)
      }
    }
  end

  def self.create_tparams(options)
    default_tparams = {
      :name => "runs",
      :filter_field => ['programs.name', 'datasets.name', 'runs.id', 'run_statuses.status'],
      :model => 'Run', 
      :limit => 25,
      :width => '100%',
      :current_sort_col => 'run_statuses.updated_at',
      :reverse_sort => true,
      :paginate => true,
      :pagination_page => 0, 
      :show_footer => true}.merge(options[:default_tparams] || {})

    datasetFormats = options[:datasetFormats] or raise "Missing"
    user = options[:user]

    defaultColsPre = [:run_id, :run_core_program, :run_core_dataset, :run_hyper, :run_user, :run_updated_at, :run_status, :run_time, :run_memory]
    defaultColsPost = []
    defaultJoins = [:status, :core_program, :core_dataset]

    tparams_specs = []
    datasetFormats.each { |datasetFormat|
      taskType = datasetFormat # ASSUMPTION
      cols = []
      cols += defaultColsPre
      if taskType == '(all)'
        cols << :run_error
      else
        cols << [Domain.get(taskType).runInfoClass.to_s, taskType]
      end
      cols += defaultColsPost
      filters = []
      filters << ['programs.is_helper', false] unless options[:showHelpers]
      filters << ['datasets.format', datasetFormat] if datasetFormat != '(all)'
      filters << ['runs.user_id', user.id] if user
      tparams_specs << [datasetFormat, cols, filters, defaultJoins]
    }

    tparams_specs.map { |name,cols,filters,joins|
      [name, default_tparams.merge({:columns => cols,
        :columns => (default_tparams[:columns] || []) + cols,
        :filters => (default_tparams[:filters] || []) + filters,
        :joins => (default_tparams[:joins] || []) + joins})]
    }
  end
end
