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

def str(x); "#{x.id}:#{x.name}" end

require 'lib_autoloader'
require 'yaml'

class ValidateState
  # See if there are any errors in the MLcomp state.

  def self.main(*args)
    # Make sure each user is valid
    puts "==== CHECKING User"
    User.find(:all).each { |u|
      u.username =~ /^[\w\.]+$/ or puts "ERROR: invalid username #{u.username}"
      u.email =~ /^[\w\.\-\+]+@[\w\.\-\+]+$/ or puts "ERROR: user #{u.username} has a funny email #{u.email}"
    }
    hit = {}
    [Program, Dataset].each { |model|
      puts "==== CHECKING #{model}"
      model.find(:all).each { |x|
        x.user or puts "ERROR: #{str(x)} has no user"
        x.proper or puts "ERROR: #{str(x)} is not proper"
        (x.process_status == "success" || x.process_status == "failed") or puts "ERROR: #{str(x)} process_status is #{x.process_status}"
        File.exists?(x.path) or puts "ERROR: #{str(x)} has non-existent path"
        if File.exists?(x.path+"/metadata")
          name = YAML::load(File.read(x.path+"/metadata"))['name']
          puts "ERROR: metadata contains name #{name} different from #{x.name}" if name != x.name
        else
          puts "ERROR: #{str(x)} has no metadata"
        end
        hit[[model.to_s.downcase+"s", x.id]] = true
      }
    }
    puts "==== CHECKING #{Run}"
    Run.find(:all).each { |r|
      r.programs.each { |x| x or puts "ERROR: run #{r.id} contains non-existent program" }
      r.datasets.each { |x| x or puts "ERROR: run #{r.id} contains non-existent dataset" }
      r.core_program or puts "ERROR: run #{r.id} contains no core program"
      r.core_dataset or puts "ERROR: run #{r.id} contains no core dataset"
      r.user or puts "ERROR: run #{r.id} has no user"
      hit[['runs', r.id]] = true
    }
    puts "==== CHECKING filesystem"
    ['programs', 'datasets', 'runs'].each { |dir|
      Dir.entries(ENV['MLCOMP_BASE_PATH']+"/#{dir}").each { |id|
        next if id == '.' || id == '..' || hit[[dir,id]]
        puts "ERROR: extra directory #{dir}/#{id}"
      }
    }
  end
end
