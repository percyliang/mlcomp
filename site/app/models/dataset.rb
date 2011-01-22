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

class Dataset < ActiveRecord::Base
  acts_as_commentable
  
  belongs_to :user

  has_many :run_datasets
  has_many :runs, :through => :run_datasets

  has_one :vresult
  class Vresult < ActiveRecord::View
    belongs_to :best_core_program, :class_name => 'Program'
  end

  has_many :processorRuns, :class_name => 'Run', :foreign_key => 'processed_dataset_id'

  def path
    raise "No path" unless self.id
    Constants::DATASETS_DEFAULT_BASE_PATH + "/#{self.id}"
  end

  def contents
    path = self.path+"/raw"
    path = self.path+"/train" if not File.exists?(path)
    if File.file?(path)
      IO.read(path)
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

  # Return error messages
  def checkProper
    errors = []
    if self.name && self.name.size > 0
      errors << "Name already exists" if Dataset.find(:all, :conditions => ['name = (?)', self.name]).any? { |d| d.id != self.id }
    else
      errors << "Name must be non-empty"
    end
    if self.format && self.format.size > 0
      errors << "Invalid dataset format" unless Domain.nameExists?(self.format)
    else
      errors << "Missing dataset format" 
    end
    if errors.size == 0
      self.proper = true
      self.save!
    end
    errors
  end
  def formatErrors(errors)
    errors.map { |e| "<div>#{e}</div>" }
  end

  def init(user, file)
    self.user = user
    self.process_status = "none"
    self.saveOrRaise(false)

    self.storeInFilesystem(file)
    self.extractMetadata
    self.saveOrRaise(true)
  end

  def info; @info ||= DatasetInfo.new(self) end

  # Return run to process the dataset
  def process
    # Set up a run to process the dataset (e.g., create splits, validate the dataset)
    begin
      run = Run.new
      run.init(self.user, info.processorRunInfoSpecObj)
      run.processed_dataset = self
      run.saveOrRaise(true)
      run
    rescue RunException
      raise DatasetException.new($!)
    end
  end
  
  def destroy
    runs.each { |r| r.destroy }
    self.deleteFromFilesystem
    super
  end
  
  def storeInFilesystem(file)
    raise DatasetException.new("No file specified") unless file && file != ""
    if File.exists?(self.path)
      raise "Internal error: directory for this dataset already exists."
    end
    MyFileUtils.store(file, self.path, true, DatasetException)
    MyFileUtils.ensureInDirectoryAsFile(self.path, "raw")
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
      self.format = map['format'] if map['format']
      self.restricted_access = map['restricted_access'] if map['restricted_access']
    rescue Exception
      raise DatasetException.new("Problem with metadata file: #{$!.message}")
    end
  end
  def saveMetadata
    map = {}
    map['name'] = self.name
    map['description'] = self.description
    map['format'] = self.format
    map['restricted_access'] = self.restricted_access
    f = open("#{path}/metadata", "w")
    f.puts YAML::dump(map)
    f.close
  end

  def self.findByName(name, exceptionClass)
    matches = find(:all, :conditions => ['name = ? AND proper = ?', name, true])
    if matches.size == 1
      matches[0]
    else
      if exceptionClass
        raise exceptionClass.new("Found #{matches.size} datasets with name '#{name}'; wanted exactly one")
      else
        nil
      end
    end
  end
  def self.findByIdOrNil(id)
    find(:all, :conditions => ['id = ?', id])[0]
  end

  # Call this after result is set
  def setSortFields
    self.sort0 = info.getSortField(0)
    self.sort1 = info.getSortField(1)
    self.sort2 = info.getSortField(2)
    self.sort3 = info.getSortField(3)
    self.sort4 = info.getSortField(4)
    self.sort5 = info.getSortField(5)
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

  # Save or throw an exception
  def saveOrRaise(validate)
    begin
      raise DatasetException.new("Unable to save dataset #{self.id}: #{errors.full_messages.join('; ')}") if not save(validate)
    rescue Exception => e
      raise DatasetException.new("Unable to save dataset #{self.id}: #{e}")
    end
  end

  # Create a table params object for displaying datasets
  def self.create_tparams(options={})
    default_tparams = {
      :name => "datasets",
      :model => 'Dataset', 
      :limit => 25,
      :width => '100%',
      :show_footer => true,
      :paginate => true, :pagination_page => 0, 
      :current_sort_col => 'avg_stddev', :reverse_sort => true,
      :include => ['user', 'vresult'],
    }.merge(options[:default_tparams] || {})

    datasetFormats = options[:datasetFormats] or raise 'Missing'
    user = options[:user]

    defaultColsPre = [:dset_name, :dset_user, :dset_created_at, :dset_disk_size, :dset_avg_stddev]
    defaultColsPost = [:dset_status, :dset_num_runs, :dset_best_error, :dset_best_program]
    #defaultJoins = [:vresult]
    defaultJoins = []
    tparams_specs = []
    datasetFormats.each { |datasetFormat|
      cols = []
      cols += defaultColsPre
      cols.push(:dset_format) if datasetFormat == '(all)'
      cols << [DatasetInfo.to_s, datasetFormat] if datasetFormat != '(all)'
      cols += defaultColsPost
      filters = []
      filters << ['format', datasetFormat] if datasetFormat != '(all)'
      filters << ['process_status', 'success'] unless options[:showUnprocessed]
      filters << ['user_id', user.id] if user
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
