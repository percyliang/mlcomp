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

# Simple way to process command-line arguments
# Return [value1, ... valueK]; modifies args
# If remove, we remove the used arguments from args.
# Each element of names is either a string name
# or a tuple [name, type, default value, required].
def extractArgs(options)
  d = lambda { |x,y| x != nil ? x : y }
  args = options[:args] || ARGV
  remove = d.call(options[:remove], true)
  spec = options[:spec] || []
  recognizeAllOpts = d.call(options[:recognizeAllOpts], true)

  arr = lambda { |x| x.is_a?(Array) ? x : [x] }
  spec = spec.compact.map { |x| arr.call(x) }
  names = spec.map { |x| x[0] }
  types = spec.map { |x| x[1] || String }
  values = spec.map { |x| x[2] != nil ? arr.call(x[2]) : nil } # Default values, to be replaced
  requireds = spec.map { |x| x[3] }

  # Print help?
  args.each { |arg|
    if arg == '-help'
      puts 'Usage:'
      spec.each { |name,type,value,required|
        puts "  -#{name}: #{type} [#{value}]#{required ? ' (required)' : ''}"
      }
    end
  }
  
  newArgs = [] # Store the arguments that we don't remove
  i = nil
  verbatim = false
  args.each { |arg|
    if arg == '--' then
      verbatim = true
    elsif (not verbatim) && arg =~ /^-(.+)$/ then
      x = $1
      #i = names.index($1)
      # If $1 is the prefix of exactly one name in names, then use that
      matchi = names.map_with_index { |name,j| name =~ /^#{x}/ ? j : nil }.compact
      if recognizeAllOpts then
        if matchi.size == 0
          puts "No match for -#{x}"
          exit 1
        elsif matchi.size > 1
          puts "-#{x} is ambiguous; possible matches: "+matchi.map{|i| "-"+names[i]}.join(' ')
          exit 1
        end
      end
      i = (matchi.size == 1 ? matchi[0] : nil)

      values[i] = [] if i
      verbatim = false
    else
      values[i] << arg if i
      verbatim = false
    end
    newArgs << arg unless remove && i
  }
  args.clear
  newArgs.each { |arg| args << arg }

  (0...names.size).each { |i|
    if requireds[i] && (not values[i]) then
      puts "Missing required argument: -#{names[i]}"
      exit 1
    end
  }

  # Interpret values according to the types
  values.each_index { |i|
    next if values[i] == nil
    t = types[i]
       if t == String    then values[i] = values[i].join(' ')
    elsif t == Fixnum    then values[i] = values[i][0].to_i
    elsif t == Float     then values[i] = values[i][0].to_f
    elsif t == TrueClass then values[i] = (values[i].size == 0 || values[i][0].to_s == 'true')
    elsif t.is_a?(Array) then
      t = t[0]
         if t == String    then values[i] = values[i]
      elsif t == Fixnum    then values[i] = values[i].map { |x| x.to_i }
      elsif t == Float     then values[i] = values[i].map { |x| x.to_f }
      elsif t == TrueClass then values[i] = values[i].map { |x| x == 'true' }
      else "Unknown type: '#{types[i][0]}'"
      end
    else raise "Unknown type: '#{types[i]}'"
    end
  }

  values
end
