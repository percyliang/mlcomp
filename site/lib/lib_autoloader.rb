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

# This script adds classes in lib to the autoload list and should
# be required by files that want access to classes in lib.

# Automatically autoload all Ruby files in the lib directory.
# Can modify this code to exclude certain files or also add more classes.
if not defined?($lib_autoloaded)
  $lib_autoloaded = true

  Dir["#{File.dirname(__FILE__)}/**/*"].each { |path|
    next unless path =~ /\.rb$/
    next if path == 'lib_autoloader.rb'
    require path
  }

  Domain::load
end
