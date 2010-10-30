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

class DatasetInfo
  attr_accessor :dataset

  def initialize(dataset)
    @dataset = dataset
    @domain = Domain.get(dataset.format)
  end

  def result(*args); dataset.resultTree && dataset.resultTree.getRecursive(*args) end

  def self.sortFieldSpec(name); Domain.get(name).datasetFieldSpec end
  def getSortField(i); result(*@domain.datasetFieldSpec.values[i]) end

  # Returns a RunInfo (wrapped in a Specification object) to process the dataset
  def processorRunInfoSpecObj
    utils = @domain.utilsProgram
    case @domain.kind
      when 'supervised-learning' then Specification.new([SupervisedLearningDatasetProcessorRunInfo, @dataset, utils, utils])
      when 'performing' then Specification.new([PerformingDatasetProcessorRunInfo, @dataset, utils])
      when 'interactive-learning' then Specification.new([InteractiveLearningDatasetProcessorRunInfo, @dataset, utils])
      else raise 'Invalid kind'
    end
  end
end
