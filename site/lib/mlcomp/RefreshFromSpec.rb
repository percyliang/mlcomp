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

# Recomputes sort fields from the specification.
# Shouldn't need to do this because this computation happens automatically.
class RefreshFromSpec
  def self.main(*args)
    print("Refreshing runs from spec.\n")
    Run.find(:all).each do |r|
      if(r.result != nil)
        r.setSortFields
      end
      r.setFromInfoSpec
      print "."
      STDOUT.flush
    end
    print "\n"

    print("Refreshing datasets from spec.\n")
    Dataset.find(:all).each do |d|
      if(d.result != nil)
        d.setSortFields
      end
      print "."
      STDOUT.flush
    end
    print "\n"
  end
end
