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

require 'yaml'

class Reduction
  # Args is a list of source taskTypes, which are to be passed into program's constructor
  attr_accessor :args
  def initialize(programName, args)
    @programName = programName
    @args = args
  end

  def program; Program.findByName(@programName, DomainException) end

  ############################################################ 
  # Given a taskType, can easily figure out which dataset formats are compatbible and vice-versa
  # This easily allows the user interface to allow various programs to run on datasets via reductions somewhat transparently.
  @@compatibleTaskTypeDatasetFormats = {} # taskType -> [datasetFormat]
  @@compatibleDatasetFormatTaskTypes = {} # datasetFormat -> [taskType]
  def self.addCompatibleTaskTypeDatasetFormat(taskType, datasetFormat)
    #puts "datasetFormat #{datasetFormat} -> taskType #{taskType}"
    (@@compatibleTaskTypeDatasetFormats[taskType] ||= []) << datasetFormat
    (@@compatibleDatasetFormatTaskTypes[datasetFormat] ||= []) << taskType
  end
  def self.isTaskTypeDatasetFormatCompatible(program, dataset)
    program.taskTypes.find { |taskType| # Try to find a task type
      (@@compatibleTaskTypeDatasetFormats[taskType] || []).index(dataset.format) # which is good for the dataset format
    }
  end
  def self.compatibleDatasetFormats(taskType)
    @@compatibleTaskTypeDatasetFormats[taskType] || []
  end
  def self.compatibleTaskTypes(datasetFormat)
    @@compatibleDatasetFormatTaskTypes[datasetFormat] || []
  end

  def self.assertCompatible(program, dataset)
    if not Reduction.isTaskTypeDatasetFormatCompatible(program, dataset)
      raise RunException.new("Learner for #{program.taskTypes.join(' ')} is incompatible with dataset format #{dataset.format}")
    end
  end
end

# Currently, domain = taskType = datasetFormat.
class Domain
  attr_accessor :path
  attr_accessor :name, :taskType, :datasetFormat, :kind, :runInfoClass
  attr_accessor :taskDescription, :datasetDescription
  attr_accessor :errorFieldValue, :reductions
  attr_accessor :runFieldSpec, :datasetFieldSpec
  #attr_accessor :compatibleDatasetFormats

  def utilsProgram; Program.findByName(@utilsProgramName, nil) end
  def evaluatorProgram; Program.findByName(@evaluatorProgramName, nil) end
  def sampleDataset; Dataset.findByName(@sampleDatasetName, nil) end

  def verify
    utilsProgram.taskTypes.index('Inspect') or raise "Program #{utilsProgramName} doesn't support the Inspect task"
    utilsProgram.taskTypes.index('Strip') or raise "Program #{utilsProgramName} doesn't support the Strip task"
    utilsProgram.taskTypes.index('Split') or raise "Program #{utilsProgramName} doesn't support the Split task" if kind == 'supervised-learning'
    evaluatorProgram.taskTypes.index('Evaluate') or raise "Program #{evaluatorProgramName} doesn't support the Evaluate task"
    sampleDataset.format == name or raise "Sample dataset has wrong format: expected #{name}, got #{sampleDataset.format}"
    sampleDataset.process_status == 'success' or raise "Sample dataset '#{sampleDataset.name}' has not been successfully processed yet"
    reductions.each { |r|
      r.program.taskTypes.index(@taskType) or raise "Reduction program #{programName} doesn't support #{@taskType} task"
    }
  end

  def initialize(path, map)
    @path = path
    @name = @taskType = @datasetFormat = map['name'] or raise 'Missing name'

    @kind = map['kind'] or raise 'Missing kind'
    ['supervised-learning', 'performing', 'interactive-learning'].index(@kind) or raise "Invalid kind: '#{kind}'; must be either 'supervised-learning' or 'performing'"
    case @kind 
      when 'supervised-learning' then @runInfoClass = SupervisedLearningRunInfo
      when 'performing' then @runInfoClass = PerformingRunInfo
      when 'interactive-learning' then @runInfoClass = InteractiveLearningRunInfo
    end

    @taskDescription = map['taskDescription'] or raise 'Missing taskDescription'
    @datasetDescription = map['datasetDescription'] or raise 'Missing datasetDescription'

    @utilsProgramName = map['utilsProgram'] or raise 'Missing utilsProgram'
    @evaluatorProgramName = map['evaluatorProgram'] or raise 'Missing evaluatorProgram'
    @sampleDatasetName = map['sampleDataset'] or raise 'Missing sampleDataset'

    runFields = map['runFields'] or raise 'Missing runFields'
    @runFieldSpec = FieldSpec.new(runFields)

    datasetFields = map['datasetFields'] or raise 'Missing datasetFields'
    @datasetFieldSpec = FieldSpec.new(datasetFields)

    @errorFieldValue = map['errorFieldValue'] or raise 'Missing errorFieldValue'
    @errorFieldValue = @errorFieldValue.split(/\//)

    #@compatibleDatasetFormats = map['compatibleDatasetFormats'] || []
    #@compatibleDatasetFormats.each { |format| Reduction.addCompatibleTaskTypeDatasetFormat(@taskType, format) }

    @reductions = (map['reductions'] || []).map { |r|
      programName = r['program'] or raise 'Reduction missing program (e.g., one-vs-all)'
      args = r['args'] or raise 'Reduction missing args (e.g., BinaryClassification)'
      args = args.split
      args.size == 1 or raise 'Multiple reduction arguments not supported yet'
      args.each { |arg|
        Reduction.addCompatibleTaskTypeDatasetFormat(arg, @taskType)
      }
      Reduction.new(programName, args)
    }
    Reduction.addCompatibleTaskTypeDatasetFormat(@taskType, @taskType)
  end

  def applyReduction(program, sourceTaskType) # Reduce from target (datasetFormat) to source (taskType)
    #puts "source: #{sourceTaskType}, target: #{@taskType}"
    if sourceTaskType == @taskType
      program
    #elsif Domain.get(sourceTaskType).compatibleDatasetFormats.index(@taskType)
      # The task type can just solve the datasetFormat directly (no reduction needed)
      #program
    else
      @reductions.each { |r|
        #puts "FF " + r.program.name + " " + r.args.inspect
        return [r.program, program] if r.args == [sourceTaskType]
      }
      raise "Internal error: unable to find reduction from #{sourceTaskType} to #{@taskType}"
    end
  end

  ############################################################
  @@names = []
  @@name2domain = {}

  def self.helperTaskTypes; ['Main', 'Inspect', 'Split', 'Strip', 'Interact', 'Evaluate'] end

  def self.names; @@names end
  def self.get(name); @@name2domain[name] or raise "Unknown domain name: #{name}" end
  def self.nameExists?(name); @@name2domain.has_key?(name) end
  def self.load
    basePath = ENV['DOMAINS_PATH'] or raise "Missing environment variable DOMAINS_PATH"
    path = "#{basePath}/index"
    begin
      index = YAML::load(File.read(path))
    rescue Exception
      $stderr.puts "Unable to load index file #{path}: #{$!}"
    end
    index.each { |name|
      path = "#{basePath}/#{name}.domain"
      begin
        map = YAML::load(File.read(path))
        domain = Domain.new(path, map)
        @@names << domain.name
        @@name2domain[domain.name] = domain
      rescue Exception
        $stderr.puts "Unable to load domain #{path}: #{$!}"
        if true # TMP
          puts $!.backtrace.join("\n")
          break
        end
      end
    }
    $stderr.puts "(loaded #{@@names.size} domains from #{basePath})"
  end
end
