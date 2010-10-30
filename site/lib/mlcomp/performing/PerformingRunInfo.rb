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

class PerformingRunInfo < RunInfo
  attr_reader :performer, :dataset, :stripper, :evaluator

  def initialize(performer, dataset, stripper, evaluator)
    if dataset.process_status != "success"
      raise RunException.new("Dataset '#{dataset.name}' not processed yet")
    end
    @performer = performer
    @dataset = dataset
    @stripper = stripper
    @evaluator = evaluator
    super(dataset.format)
  end

  def self.defaultRunInfoSpecObj(domain, performer, dataset, tuneHyperparameters)
    Reduction.assertCompatible(performer, dataset)
    Specification.new([self, performer, dataset, domain.utilsProgram, domain.evaluatorProgram])
  end

  def getRunSpecObj
    main = Program.findByName('performing', RunException)
    effectivePerformer = @domain.applyReduction(performer, performer.taskTypes[0])
    spec = RunSpecification.new([main, effectivePerformer, dataset, stripper, evaluator])
    spec.verifyTypes(RunException)
    spec
  end

  def coreProgram; performer end
  def coreDataset; dataset end
end
