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
require 'active_record/view'

class Program < ActiveRecord::Base
  
  acts_as_commentable
  
  belongs_to :user
  #validates_presence_of :name
  #validates_uniqueness_of :name

  has_many :run_programs
  has_many :runs, :through => :run_programs
  
  has_one :vresult
  class Vresult < ActiveRecord::View; end

  has_many :processorRuns, :class_name => 'Run', :foreign_key => 'processed_program_id'

  def path
    raise "No path" unless self.id
    Constants::PROGRAMS_DEFAULT_BASE_PATH + "/#{self.id}"
  end

  def taskTypes; self.task_type ? self.task_type.split : [] end
  def hasConstructor?; self.constructor_signature != nil && self.constructor_signature.size > 0 end

  # Return error messages
  def checkProper
    # FUTURE: unify checkProper with dataset; make sure that name is \w+
    errors = []
    errors << "Name must be non-empty" unless self.name && self.name.size > 0
    errors << "Name already exists" if Program.find(:all, :conditions => ['name = ?', self.name]).any? { |p| p.id != self.id }
    errors << "Missing task type" if self.taskTypes.size == 0
    errors << "Invalid task type" unless self.taskTypes.all? { |t| Domain.nameExists?(t) || Domain.helperTaskTypes.index(t) }
    if errors.size == 0
      # Update these fields (must be done every time fields are updated) 
      self.is_helper = (not Domain.nameExists?(self.task_type)) || hasConstructor?
      self.process_status = "success" if self.is_helper # Automatic for helpers

      self.proper = true
      self.save!
    end
    errors
  end

  def init(user, file)
    self.user = user
    self.is_helper = false
    self.saveOrRaise(false)

    self.storeInFilesystem(file)
    self.extractMetadata
    self.saveOrRaise(true)
  end

  # Return run to process this program
  def process
    # Make sure this program runs on a sample dataset (for non-helper programs)
    begin
      run = Run.new
      if not self.is_helper # Only check non-helper programs
        domain = Domain.get(taskTypes[0]) # Use task dataset
        info_spec_obj = domain.runInfoClass.defaultRunInfoSpecObj(domain, self, domain.sampleDataset, false)
        run.init(self.user, info_spec_obj)
        run.processed_program = self
        run.saveOrRaise(true)
      end
    rescue RunException
      raise ProgramException.new($!)
    end
  end
  
  def destroy
    runs.each { |r| r.destroy }
    self.deleteFromFilesystem
    super
  end

  def storeInFilesystem(file)
    raise ProgramException.new("No file specified") unless file && file != ""
    if(File.exists?(self.path))
      raise "Internal error: directory for this program already exists."
    end

    MyFileUtils.store(file, self.path, true, ProgramException)
    MyFileUtils.ensureInDirectoryAsFile(self.path, "run")

    if not File.file?("#{self.path}/run")
      raise ProgramException.new("'run' executable file missing (this is the entry point to your program)")
    end
    
    # Make sure the run script is executable
    MyFileUtils.giveExecPermissions("#{self.path}/run", ProgramException)

    self.disk_size = MyFileUtils.getDiskSize(self.path)
  end

  def deleteFromFilesystem
    if self.id && File.exists?(self.path)
      FileUtils.remove_dir(self.path)
    end
  end

  def extractMetadata
    return unless File.exists?("#{path}/metadata")
    begin
      f = open("#{path}/metadata", "r")
      map = YAML::load(f)
      f.close
      self.name = map['name'] if map['name']
      self.description = map['description'] if map['description']
      self.task_type = map['task'] if map['task']
      self.restricted_access = map['restricted_access'] if map['restricted_access']
      self.constructor_signature = map['construct'] if map['construct']
    rescue Exception
      raise ProgramException.new("Problem with metadata file: #{$!.message}")
    end
  end
  def saveMetadata
    map = {}
    map['name'] = self.name
    map['description'] = self.description
    map['task'] = self.task_type
    map['restricted_access'] = self.restricted_access
    map['construct'] = self.constructor_signature
    begin
      f = open("#{path}/metadata", "w")
      f.puts YAML::dump(map)
      f.close
    rescue
      raise ProgramException.new("Unable to save metadata")
    end
  end

  def self.findByName(name, exceptionClass)
    matches = find(:all, :conditions => ['name = ? AND proper = ?', name, true])
    if matches.size == 1
      matches[0]
    else
      if exceptionClass
        raise exceptionClass.new("Found #{matches.size} programs with name '#{name}'; wanted exactly one")
      else
        nil
      end
    end
  end
  def self.findByIdOrNil(id)
    find(:all, :conditions => ['id = ?', id])[0]
  end

  # Save or throw an exception
  def saveOrRaise(validate)
    raise ProgramException.new("Unable to save program #{self.id}: #{errors.full_messages.join('; ')}") if not save(validate)
  end

  def directory_tree
    Program.directory_tree_helper "", path
  end
  
  def self.directory_tree_helper dirpath, basepath
    children = Dir.entries(basepath + "/" + dirpath).delete_if {|fname| fname =~ /^\./}
    dirHash = Hash.new
    children.each do |child|
      childpath = dirpath + "/" + child
      if File.directory? basepath + "/" + childpath
        dirHash[child] = directory_tree_helper childpath, basepath
      else
        dirHash[child] = childpath
      end
    end
    dirHash
  end

  def self.create_tparams(options={})
    default_tparams = {
      :name => "programs",
      :model => 'Program', 
      :limit => 25,
      :width => '100%',
      :show_footer => true,
      :paginate => true, :pagination_page => 0, 
      :current_sort_col => 'avg_percentile', :reverse_sort => true,
      :include => ['user', 'vresult'],
    }.merge(options[:default_tparams] || {})
    taskTypes = options[:taskTypes] or raise "Missing"
    user = options[:user]
    
    defaultCols = [:prg_name, :prg_user, :prg_created_at, :prg_disk_size, :prg_num_runs, :prg_status, :prg_avg_percentile]
    #defaultJoins = [:vresult]
    defaultJoins = []
    tparams_specs = []
    taskTypes.each { |taskType|
      cols = []
      cols += defaultCols
      cols << :prg_task_type if taskType == '(all)'
      filters = []
      filters << ['is_helper', false] unless options[:showHelpers]
      filters << ['process_status', 'success'] unless options[:showUnprocessed]
      filters << ['task_type', taskType] if taskType != '(all)'
      filters << ['user_id', user.id] if user
      tparams_specs << [taskType, cols, filters, defaultJoins]
    }

    tparams_specs.map { |name,cols,filters,joins|
      [name, default_tparams.merge({:columns => cols,
        :columns => (default_tparams[:columns] || []) + cols,
        :filters => (default_tparams[:filters] || []) + filters,
        :joins => (default_tparams[:joins] || []) + joins})]
    }
  end
end
