require 'general'

class DatasetSplit
  def initialize(numExamples, trainSplitFrac)
    # Two ways to split
    #   - Order-independent (this is what we do now)
    #   - First portion is train, second portion is test
    #     (has advantage of being more realistic)
    permutation = (0...numExamples).to_a.shuffle(42)
    @isTrain = [false] * numExamples
    numTrainExamples = (numExamples * trainSplitFrac + 0.5).to_i
    (0...numTrainExamples).each { |i| @isTrain[permutation[i]] = true }
  end

  def isTrain(i); @isTrain[i] end
end

class SVMLightFormat
  TRAIN_SPLIT_FRAC = 0.7

  # binary and multi subclasses should verify the output label
  def isValidLabel(y); raise "Abstract method" end
  def updateLabelSummary(summary, y); raise "Abstract method" end
  def blankLabel; 0 end

  # Crude test: shards are files, splits are directories containing train and test
  def split?(dirPath); File.directory?(dirPath) end 

  # path is a single file that contains examples in SVM light format
  # Return statistics of the datashard at path.
  # Throw an exception if invalid format.
  # WARNING: this function is slow for large datasets.
  def inspect(path)
    exitFail("File doesn't exist: '#{path}'") if not File.exists?(path)

    numExamples = 0
    numDim = 0
    labelSummary = nil
    lineNum = 0
    IO.foreach(path) { |line|
      lineNum += 1
      line = line.trim
      next if line =~ /^#/
      y, *xs = line.split

      # Label
      if not isValidLabel(y)
        exitFail("Invalid label '#{y}' in #{path} on line #{lineNum}")
      end
      labelSummary = updateLabelSummary(labelSummary, y)

      # Features
      xs.each { |x|
        if x =~ /^(\d+):(.+)$/
          i, v = $1.to_i_or_nil, $2.to_f_or_nil
          if i && v && i >= 1
            numDim = [numDim, i].max
            next
          end
        end
        exitFail("Invalid feature '#{x}' in #{path} on line #{lineNum}; expected <positive integer>:<float>")
      }
      numExamples += 1
    }

    # Return statistics
    labelSummary['numExamples'] = numExamples
    labelSummary['numDim'] = numDim
    writeStatus(labelSummary)
    exitSuccess
  end
  
  def split(inPath, trainPath, testPath)
    trainOut = File.open(trainPath, "w")
    testOut = File.open(testPath, "w")

    # Split the data
    numExamples = IO.readlinesClean(inPath).size
    split = DatasetSplit.new(numExamples, TRAIN_SPLIT_FRAC)
    lineNum = 0
    IO.foreach(inPath) { |inputLine|
      (split.isTrain(lineNum) ? trainOut : testOut).print(inputLine)
      lineNum += 1
    }

    trainOut.close
    testOut.close
  end

  def stripLabels(inPath, outPath)
    # Assume that the first column is the output label, which we just replace with 0
    out = open(outPath, "w")
    IO.foreachClean(inPath) { |line|
      y, x = line.split(/ /, 2)
      out.puts "#{blankLabel} #{x}"
    }
    out.close
  end

  def main
    cmd = ARGV.shift
    case cmd
      when 'inspect'
        path, = parseArgs(:file)
        inspect(path)
      when 'split'
        rawPath, trainPath, testPath = parseArgs(:file, :nonexist, :nonexist)
        split(rawPath, trainPath, testPath)
      when 'stripLabels'
        inPath, outPath = parseArgs(:file, :nonexist)
        stripLabels(inPath, outPath)
    end
  end
end
