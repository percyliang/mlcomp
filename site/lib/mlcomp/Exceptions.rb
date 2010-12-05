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
