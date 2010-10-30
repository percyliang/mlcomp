# Raised when anything goes wrong with the dataset.
class DatasetException < Exception
  def initialize(message); @message = message end
  def to_s; @message end
end

# Raised when anything goes wrong with the program.
class ProgramException < Exception
  def initialize(message); @message = message end
  def to_s; @message end
end

# Raised when anything goes wrong with executing a run
# (not when the run itself is bad).
class RunException < Exception
  def initialize(message); @message = message end
  def to_s; @message end
end

# Raised when anything goes wrong with a domain.
class DomainException < Exception
  def initialize(message); @message = message end
  def to_s; @message end
end

# Raised when anything goes wrong with a worker.
class WorkerException < Exception
  def initialize(message); @message = message end
  def to_s; @message end
end
