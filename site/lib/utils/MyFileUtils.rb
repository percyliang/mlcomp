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

require 'ftools'

class FileContents
  attr :value
  def initialize(value)
    @value = value
  end
end

####Utility functions for operating on files.
module MyFileUtils
  # Return an absolute path in the temporary directory with the given suffix.
  def self.getTmpPath(suffix)
    "#{Constants::TMP_PATH}/#{rand(10000000)}#{suffix}"
  end

  def self.zipFile?(f); magicNumber(f, 2) == "PK" end

  # Get the n-byte sequence from the beginning of the file or stream
  # (arg can be either a string path or a file stream)
  def self.magicNumber(file, n)
    # Open if file name
    if file.class == String
      stream = open(file, "r")
      return nil if not stream 
      close = true
    else
      stream = file
      close = false
    end
    # Read
    savePos = stream.tell
    x = stream.read(n)
    stream.seek(savePos)
    # Close (if we opened)
    stream.close if close
    x
  end

  # Copy file (directory, zip file, plain file, or stream) to outputPath; unpack if necessary.
  # If stripDirectory and zip contains one directory and it's not named raw (HACK), move contents of that directory into outputPath.
  # TODO: support for tar, tar.gz, bz2 files
  def self.store(file, outputPath, stripDirectory, exceptionClass)
    # We supply the contents of the file directly
    if file.class == FileContents
      out = open(outputPath, "w")
      out.puts file.value
      out.close 
      return
    end

    if file.class == String
      if File.directory?(file) 
        recursiveCopy(file, outputPath)
        return
      end
      begin
        stream = open(file, "r") # File
        close = true
      rescue Exception
        raise exceptionClass.new("Can't open file: {$!.message}")
      end
    else
      stream = file
      close = false
    end

    if zipFile?(stream)
      # Save to temporary file
      tempArchiveFilePath = getTmpPath('.zip')
      writeToFile(stream, tempArchiveFilePath, exceptionClass)

      # Expand the archive file into the directory given by outputPath
      Dir.mkdir(outputPath)
      systemOrFail('unzip', '-q', tempArchiveFilePath, '-d', outputPath)

      # If archive contains one directory, move its contents to self.path and get rid of the superfluous directory
      # This is a bit heuristic, and would fail if a dataset is uploaded with one directory "raw"
      if stripDirectory
        files = self.listFiles(outputPath)
        if files.size == 1 && File.directory?(files[0]) && files[0] != 'raw' then
          tmpPath = "#{files[0]}.tmp#{rand(10000000)}"
          File.move(files[0], tmpPath)
          self.listFiles(tmpPath).each { |path| File.move(path, outputPath) }
          systemOrFail('rm', '-r', tmpPath) # tmpPath could still contain irrelevant files (e.g., .DS_Store)
        end
      end

      # Clean up
      File.delete(tempArchiveFilePath)
    else
      writeToFile(stream, outputPath, exceptionClass)
    end

    stream.close if close
  end

  # Like Dir[path+"/*"] but includes hidden files
  def self.listFiles(path)
    Dir.entries(path).delete_if { |x| x == '.' || x == '..' || x == '.DS_Store' }.map { |x| path+"/"+x }
  end

  def self.writeToFile(inputStream, outputPath, exceptionClass)
    max = 1024*1024
    n = 0
    limit_mb = 200 # maximum file size allowed (note that inputStream is probably zipped up)
    limit = limit_mb*1024*1024
    File.open(outputPath, "wb") { |f|
      while true
        s = inputStream.read(max)
        break unless s && s.size > 0
        n += s.size
        raise exceptionClass.new("Sorry, your file exceeds #{limit_mb}MB, which is beyond our capacity right now.") if n > limit
        f.write(s)
      end
    }
  end

  def self.getDiskSize(path)
    n = 0
    Dir["#{path}/**/*"].each { |subPath|
      n += File.size(subPath) if File.file?(subPath) 
    }
    n
  end

  def self.giveExecPermissions(path, exceptionClass)
    begin
      systemOrFail('chmod', '+x', path)
    rescue
      raise exceptionClass.new($!)
    end
  end

  def self.ensureInDirectoryAsFile(path, fileName)
    # If path is a file, make path a directory and move that file into that directory
    return if File.directory?(path) # Already a directory
    raise "Not a file: #{path}" unless File.file?(path) # Well, must be a file then
    tmpDirPath = path+".tmpdir"
    raise "Can't create #{tmpDirPath}" unless FileUtils.mkdir(tmpDirPath)
    raise "Can't move" unless FileUtils.mv(path, tmpDirPath+"/"+fileName)
    raise "Can't move" unless FileUtils.mv(tmpDirPath, path)
  end
end
