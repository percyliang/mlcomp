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

require 'mlcomp/RunInfo'

# Runs supervised-learning.
class SupervisedLearningRunInfo < RunInfo
  attr_reader :learner, :dataset, :stripper, :evaluator, :tuneHyperparameters

  def initialize(learner, dataset, stripper, evaluator, tuneHyperparameters = false)
    if dataset.process_status != "success"
      raise RunException.new("Dataset '#{dataset.name}' not processed yet")
    end
    @learner = learner
    @dataset = dataset
    @stripper = stripper
    @evaluator = evaluator
    @tuneHyperparameters = tuneHyperparameters && tuneHyperparameters != 'false'
    super(dataset.format)
  end

  def self.defaultRunInfoSpecObj(domain, learner, dataset, tuneHyperparameters)
    Reduction.assertCompatible(learner, dataset)
    Specification.new([self, learner, dataset, domain.utilsProgram, domain.evaluatorProgram, tuneHyperparameters])
  end

  def getRunSpecObj
    main = Program.findByName('supervised-learning', RunException)

    # Hyperparameter tuning
    defaultNumProbes = 5
    if @tuneHyperparameters
      # Need a domain specific to the program, not the dataset
      domain = Domain.get(learner.taskTypes[0])
      effectiveLearner = [
        Program.findByName('tune-hyperparameter', RunException),
        defaultNumProbes, learner, domain.utilsProgram, domain.evaluatorProgram]
    else
      effectiveLearner = learner
    end

    effectiveLearner = @domain.applyReduction(effectiveLearner, learner.taskTypes[0])

    spec = RunSpecification.new([main, effectiveLearner, dataset, stripper, evaluator])
    spec.verifyTypes(RunException)
    spec
  end

  def coreProgram; learner end
  def coreDataset; dataset end
end
