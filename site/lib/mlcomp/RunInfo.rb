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

# A RunInfo object provides a schema for creating a RunSpecification
# (hierarchical structures containing all the information needed to create an
# actual run).  Such a schema might be supervised learning.
#
# In practice, the user will want to make a run out of a program with a
# particular taskType, which should map to a canonical run specification for
# creating a run.  Note that the task type of the top-level program of that run
# is always Main.  The program with that taskType is the coreProgram.
#
# Some programs are just helpers and are never run directly, for example,
# evaluators (although in principle, in the future, we might want to make a
# RunInfo that allows a program to take a completed run as an argument, to do,
# for example, data analysis).
#
# There are four important subclasses, corresponding to kind (supervised-learning, performing) and (processing dataset, executing programs)
#  - SupervisedLearningRunInfo
#  - PerformingRunInfo
#  - SupervisedLearningDatasetProcessorRunInfo
#  - PerformingDatasetProcessorRunInfo
class RunInfo
  attr_accessor :run # Set later in run.rb

  def initialize(taskType)
    @domain = Domain.get(taskType)
  end

  # Create the specification for the default RunInfo (how to construct myself).
  def defaultRunInfoSpecObj(*args); raise "Abstract method" end

  # Returns a run specification, which contains all the information to
  # construct the programs and therefore execute the run.
  def getRunSpecObj; raise "Abstract method" end

  # Convenient function used by subclasses
  def result(*args); run.resultTree && run.resultTree.getRecursive(*args) end

  def self.sortFieldSpec(name); Domain.get(name).runFieldSpec end
  def getSortField(i); @domain && ensureFloat(result(*@domain.runFieldSpec.values[i])) end
  def getError; @domain && ensureFloat(result(*@domain.errorFieldValue)) end # Boil down a run to a single number (lower is better)

  # If not a finite float, then replace with nil
  # Need this because SQL doesn't allow storing of NaNs or infinities
  def ensureFloat(x); x.is_a?(Float) && x.finite? ? x : nil end

  def coreProgram; raise "Abstract method" end
  def coreDataset; raise "Abstract method" end
end
