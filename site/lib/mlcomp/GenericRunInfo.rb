require 'mlcomp/RunInfo'

# A RunInfo is used to create a RunSpecification, the tree that describes the constructor of the program to be executed.
# Usually the RunInfo is parametrized by a few parameters (e.g., see SupervisedLearningRunInfo).
# This RunInfo is parametrized by a RunSpecification directly.
class GenericRunInfo < RunInfo
  attr_reader :runSpecTree

  def initialize(runSpecTree)
    super(nil)
    @runSpecTree = runSpecTree
  end

  def self.defaultRunInfoSpecObj(runSpecTree)
    Specification.new([self, runSpecTree])
  end

  def getRunSpecObj
    spec = RunSpecification.new(@runSpecTree)
    spec.verifyTypes(RunException)
    spec
  end

  def coreProgram; nil end
  def coreDataset; nil end
end
