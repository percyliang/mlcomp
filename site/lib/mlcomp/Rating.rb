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

# Rates programs and datasets.
#
# Each (program,dataset) yields an error rate (FUTURE: and time).
# If there are multiple runs, just take the best one.
# If any runs crashed, give maximum error rate.
#
# Quality of a program (avgGaussPercentile):
#   Across datasets with that program, area to the right of the fitted Gaussian of the error rate.
#   Good programs beat other programs by a decent margin.
#
# Quality of a dataset (avgStddev):
#   Across runs with that dataset, standard deviation of error.
#   Good datasets distinguish programs.

$infty = 1.0/0

class RatingEngine
  def sum(a); x = 0; a.each { |y| x += y }; x end
  def mean(a); sum(a)*1.0 / a.size end
  def var(a); m = mean(a); mean(a.map{|x| (x-m)**2}) end
  def stddev(a); Math.sqrt(var(a)) end

  #def fetchInBlocks(model, *args)
    #model.find(*args)
  #end

  def rateAll(*args)
    errors = {}
    runIdx = 0
    numRuns = Run.count
    @verbose = 0

    add = lambda { |program,dataset,error|
      runIdx += 1
      puts "#{runIdx}/#{numRuns}: #{program.name} #{dataset.name} #{error}" if @verbose >= 2
      key = [program,dataset]
      errors[key] = [errors[key] || $infty, error].min
    }

    # Go through all runs
    puts "=== Going through #{numRuns} runs..."
    path = ENV['MLCOMP_SOURCE_PATH']+'/site/public/download/runs.txt' # Save results of all runs
    lines = []
    lines << ['domain', 'programID', 'programName', 'datasetID', 'datasetName', 'runID', 'tunedHyperparameters', 'error'].join("\t")
    Run.find(:all).each_with_index { |r,i|
      s = r.status.status
      program = r.info.coreProgram
      dataset = r.info.coreDataset
      next if program.is_helper
      lines << [dataset.format, program.id, program.name, dataset.id, dataset.name, r.id, r.tuneHyperparameters ? true : false, s == 'done' ? r.error : 'failed'].join("\t")
      if s == 'done' && r.error
        add.call(program, dataset, r.error)
      elsif s == 'failed'
        add.call(program, dataset, $infty)
      end
    }
    out = open(path, 'w')
    lines.each { |line| out.puts line }
    out.close

    # Index programs/datasets
    dataset2errorPrograms = {}
    errors.each { |programDataset,error|
      program, dataset = programDataset
      (dataset2errorPrograms[dataset] ||= []) << [error,program]
    }
    program2percentiles = {}

    # Take the log of errors.
    # This makes everything insensitive to scaling of the errors.
    dataset2errorPrograms.values.each { |list|
      list.each { |a|
        a[0] = [1e-4, a[0]].max # Don't let errors get too small
        a[0] = Math.log(a[0]) if a[0] != $infty
      }
    }

    minPointsForRating = 5

    # Rate the datasets first
    puts "=== Rating datasets..."
    dataset2errorPrograms.each { |dataset,errorPrograms|
      errors = errorPrograms.map { |e,p| e }
      programs = errorPrograms.map { |e,p| p }

      # Replace infinity with maximum actual error
      actualErrors = errors.map { |e| e != $infty ? e : nil }.compact
      if actualErrors.size == 0 # Everything crashed
        dataset.avg_stddev = nil
        dataset.save!
        next
      end
      max = actualErrors.max
      errors = errors.map { |e| e != $infty ? e : max }
      if errors.size < minPointsForRating # Not enough data points
        dataset.avg_stddev = nil
        dataset.save!
        next
      end
      dataset.avg_stddev = stddev(errors)
      puts "dataset #{dataset.name}: #{dataset.avg_stddev} (#{errors.size})" if @verbose >= 1
      dataset.save!

      # Remap errors to percentiles
      mean = mean(errors)
      stddev = stddev(errors)

      percentiles = errors.map { |e|
        z = stddev == 0 ? 0.0 : (e-mean)/stddev
        1.0/(1+Math.exp(z))
      }
      programs.zip(percentiles).each { |program,per|
        (program2percentiles[program] ||= []) << per
      }
    }

    # Rate the programs now
    puts "=== Rating programs..."
    program2percentiles.each { |program,pers|
      if pers.size < minPointsForRating
        program.avg_percentile = nil
        program.save!
        next
      end
      smoothing = 1
      mean = sum(pers) / (pers.size+smoothing)
      program.avg_percentile = mean
      puts "program #{program.name}: #{program.avg_percentile} (#{pers.size})" if @verbose >= 1
      program.save!
    }
  end

  def runHighlyRated(*args)
    log "runHighlyRated: #{args.inspect}"
    pretend, tuneHyperparameters, numTop, = extractArgs(:args => args, :spec => [
      ['pretend', TrueClass, false],
      ['tuneHyperparameters', TrueClass, false], # Important this is false not nil for matching specs
      ['numTop', Fixnum, 5],
    nil])

    #minRuns = 10
    Domain.names.each { |name| # For each domain...
      puts "============= Domain #{name}"
      domain = Domain.get(name)

      allPrograms = Program.find(:all, :conditions => ['task_type = ? AND process_status = ? AND is_helper = ?', name, 'success', false])
      allDatasets = Dataset.find(:all, :conditions => ['format = ? AND process_status = ?', name, 'success'])

      runs = []
      
      # Take the numTop highest-rated programs...
      topPrograms = allPrograms.sort { |p1,p2| (p2.avg_percentile || -1) <=> (p1.avg_percentile || -1) }[0...numTop]
      topPrograms.each { |program|
        puts "Program #{program.name} with rating #{program.avg_percentile}"
      }
      # Take the programs which have fewer than minRuns...
      #freshPrograms = allPrograms.map { |program|
      #  numRuns = program.vresult.num_runs
      #  if numRuns < minRuns
      #    puts "Program #{program.name} has only #{numRuns} < #{minRuns} runs"
      #    program
      #  else
      #    nil
      #  end
      #}.compact

      # Take the numTop highest-rated datasets...
      topDatasets = allDatasets.sort { |d1,d2| (d2.avg_stddev || -1) <=> (d1.avg_stddev || -1) }[0...numTop]
      topDatasets.each { |dataset|
        puts "Dataset #{dataset.name} with rating #{dataset.avg_stddev}"
      }
      # Take the datasets which have fewer than minRuns...
      #freshDatasets = allDatasets.map { |dataset|
      #  numRuns = dataset.vresult.num_runs
      #  if numRuns < minRuns
      #    puts "Dataset #{dataset.name} has only #{numRuns} < #{minRuns} runs"
      #    dataset
      #  else
      #    nil
      #  end
      #}.compact

      numLaunched = 0
      runAll = lambda { |programs,datasets|
        programs.each { |program|
          datasets.each { |dataset|
            domain = Domain.get(dataset.format)
            info_spec_obj = domain.runInfoClass.defaultRunInfoSpecObj(domain, program, dataset, tuneHyperparameters)
            str = "run(#{program.name}, #{dataset.name}, hyper=#{tuneHyperparameters})"
            runs = Run.findAllByInfoSpecObj(info_spec_obj)
            next if runs.size > 0
            numLaunched += 1
            if pretend
              puts "ADD #{str}"
              next
            end
            run = Run.new
            begin
              run.init(User.internalUser, info_spec_obj)
              run.checkAllProcessed
              log "Added run #{run.id}: #{str}"
            rescue Exception
              log "#{$!} [#{program.name}, #{dataset.name}]"
              log $!.backtrace.join("\n") unless $!.is_a?(RunException) # Something screwed up
              run.destroy
            end
          }
        }
      }

      # Run top on all, fresh on top
      runAll.call(topPrograms, allDatasets)
      runAll.call(allPrograms, topDatasets)
      puts "#{numLaunched} runs #{pretend ? 'to be ' : ''}created"
    }
  end
end
