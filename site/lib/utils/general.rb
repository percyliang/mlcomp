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

# General utilities such as including mixins to standard classes.
# Last updated 10/30/10.

require 'yaml'
require 'scanf'

class Hash
  # Return the value associated with the key.
  # Raise an exception if that key doesn't exist
  def getOrRaise(key, exceptionClass=String)
    value = self[key]
    raise exceptionClass.new("Missing key: #{key}") unless value != nil
    return value
  end

  def getRecursive(*keys)
    if keys.size == 0
      self
    else
      value = self[keys[0]]
      return value if keys.size == 1
      if value && value.is_a?(Hash)
        value.getRecursive(*keys[1..-1])
      else
        nil
      end
    end
  end
  def setRecursive(keys, value)
    if keys.size == 0
      # Error?
    elsif keys.size == 1
      self[keys[0]] = value
    else
      map = self[keys[0]]
      map = self[keys[0]] = {} if not map
      map.setRecursive(keys[1..-1], value)
    end
  end
end

class Array
  def shuffle(randSeed=nil)
    saveRandSeed = srand(randSeed) if randSeed
    each_index { |i|
      j = Kernel::rand(size-i)+i
      t = self[i]; self[i] = self[j]; self[j] = t
    }
    srand(saveRandSeed) if randSeed
    self
  end
  def map_with_index
    a = []
    each_with_index { |x,i| a << yield(x, i) }
    a
  end
end

class String
  def urlencode
    gsub(/[^a-zA-Z0-9\-_\.!~*'()]/n) {|x| sprintf('%%%02x', x[0])}
  end
  def trim; sub(/^\s+/, "").sub(/\s+$/, "") end
  def to_i_or_nil; t = scanf("%d%s"); t.size == 1 ? t[0] : nil end
  def to_f_or_nil; t = scanf("%f%s"); t.size == 1 ? t[0] : nil end
end

class IO
  def self.writelines(file, lines)
    out = Kernel.open(file, "w")
    lines.each { |line| out.puts line }
    out.close
  end

  # Return the number of lines in the file at path
  def self.countlines(path)
    n = 0
    IO.foreach(path) { |line| n += 1 }
    n
  end

  # Read lines from a file but strip away whitespace and initial comments (marked by #)
  def self.readlinesClean(file)
    lines = []
    foreachClean(file) { |line| lines << line }
    lines
  end
  def self.foreachClean(file)
    IO.foreach(file) { |line|
      line = line.trim
      next if line =~ /^#/ # Skip comments
      yield line
    }
  end

  def self.foreach2(file1, file2)
    in1 = Kernel.open(file1, 'r')
    in2 = Kernel.open(file2, 'r')
    while true
      line1 = in1.gets
      line2 = in2.gets
      break if line1 == nil && line2 == nil
      yield [line1, line2]
    end
    in1.close
    in2.close
  end
end

############################################################

def systemOrFail(cmd, *args)
  #puts "SYSTEM: #{([cmd]+args).inspect}"
  ok = system(cmd, *args)
  raise "Command failed: #{([cmd]+args).inspect}" if not ok
end

# Change directory temporarily to path, do block; and then switch back.
def changePath(path, &block)
  currPath = Dir.pwd
  begin
    Dir.chdir(path)
    result = block.call
    Dir.chdir(currPath)
    result
  rescue
    Dir.chdir(currPath)
    raise $!
  end
end

def recursiveCopy(sourcePath, targetPath)
  if File.exists?(targetPath)
    raise "Internal error: '#{targetPath}' already exists"
  end
  # Dereference symbolic links
  systemOrFail('cp', '-RL', sourcePath, targetPath)
end

############################################################
# These functions are used by many of the standalone
# Ruby programs that get submitted to mlcomp.

class FilePath
  attr :path
  def initialize(path); @path = path end
  def relativize(newRoot)
    # path is relative to the current directory
    # return a path relative to newRoot
    # Example: currRoot = "/home/a1", path = "b/c", newRoot = "../a2", newPath = "../a1/b/c"
    return @path if @path =~ /^\// # Absolute path
    return File.expand_path(@path) if newRoot =~ /^\//
    path = @path.split(/\//)
    currRoot = Dir.pwd.split(/\//)
    newRoot = newRoot.split(/\//)
    newRoot.each { |a|
      if a == '..'
        if path[0] == '..'
          path.shift # ..'s cancel
          currRoot.pop
        else
          path = [currRoot.pop]+path
        end
      else
        path = ['..']+path
      end
    }
    path.join('/')
  end
end
def file(path); FilePath.new(path) end

# Tricky: oldPath could have been constructed with various relative paths.
# Need to adapt them to newPath.
# HACK: assume all paths are in 'args' file.  Only will get replaced.
# Ideally, we'd run the constructor again.
def copyProgram(oldPath, newPath)
  recursiveCopy(oldPath, newPath)
  argsPath = newPath+"/args"
  newPathFromOld = file(newPath).relativize(oldPath)
  if File.exists?(argsPath)
    args = IO.readlines(argsPath).map { |arg| arg.chomp }
    newArgs = changePath(oldPath) {
      args.map { |arg|
        File.exists?(arg) ? file(arg).relativize(newPathFromOld) : arg
      }
    }
    IO.writelines(argsPath, newArgs)
  end
end

def runProgram(programPath, method, *args)
  # For file path arguments, make them with respect to programPath
  args = args.map { |arg|
    arg.is_a?(FilePath) ? arg.relativize(programPath) : arg.to_s
  }

  # Set up
  clearStatus(programPath)
  programName = File.basename(programPath)
  args = ['./run', method] + args

  # Run
  startTime = Time.now.to_i
  puts "=== START #{programName}: #{args.join(' ')}"
  success = changePath(programPath) { system(*args) }
  endTime = Time.now.to_i
  time = endTime - startTime
  puts "=== END #{programName}: #{args.join(' ')} --- #{success ? 'OK' : 'FAILED'} [#{time}s]"

  # Get results
  map = readStatus(programPath)
  map['success'] = map['success'] != nil ? map['success'] : success
  map['time'] = time
  map
end

# Functions for reading/writing status files.
# This is the way programs return values
    
def readStatus(path='.')
  path = path+"/status"
  File.file?(path) ? open(path, "r") { |f| YAML::load(f) } : {}
end
def writeStatus(map, path='.')
  #puts "WRITE " + map.inspect
  path = path+"/status"
  open(path, "w") { |f| YAML::dump(map, f) }
  map
end
def successStatus?(map); map && map['success'] == true end
def exitSuccess
  updateStatus('success', true)
  exit 0
end
def exitFail(message=nil)
  puts "Failed: #{message}" if message
  updateStatus('success', false)
  updateStatus('message', message) if message
  exit 1
end
def exitIfFail(key, map, message=nil)
  updateStatus(key, map)
  exitFail(message) if not successStatus?(map)
end
def clearStatus(path='.')
  path = path+"/status"
  File.delete(path) if File.exists?(path)
  {}
end
def updateStatus(key, value, path='.')
  map = readStatus(path)
  case key
    when String then map[key] = value
    when Array then map.setRecursive(key, value)
    else raise "Bad key: '#{key}'"
  end
  writeStatus(map, path)
  map
end

# Dealing with arguments

def saveArgs; IO.writelines('args', ARGV) end
def loadArgs(*types)
  parseArgsHelper(IO.readlines('args').map { |x| x.trim }, types)
end
def parseArgs(*types)
  parseArgsHelper(ARGV, types)
end
def parseArgsHelper(args, types)
  if args.size != types.size
    exitFail("Expected #{types.size} args, got #{args.size}")
  end
  (0...args.size).map { |i| arg = args[i]
    case types[i]
      when :string
        # Always ok
      when :integer
        arg = arg.to_i_or_nil
        exitFail("Expected integer but got '#{arg}'") if not arg
      when :directory then
        exitFail("Directory doesn't exist: '#{arg}'") if not File.directory?(arg)
      when :file then
        exitFail("File doesn't exist: '#{arg}'") if not File.file?(arg)
      when :nonexist then
        #raise "Path already exists: '#{arg}'" if File.exists?(arg) # Too harsh
        puts "WARNING: path already exists, overwriting: '#{arg}'" if File.exists?(arg)
      when :program then
         exitFail("Program doesn't exist: '#{arg}'") if not (File.directory?(arg) && File.file?(arg+"/run"))
      else
        exitFail("Unknown argument type: '#{types[i]}'")
    end
    arg
  }
end
