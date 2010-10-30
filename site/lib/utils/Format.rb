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

# Format time, errors, disk spaces into strings.
class Format
  def self.time(s) # In seconds
    return nil if not s
    s = s.to_i
    m = s / 60; s %= 60
    h = m / 60; m %= 60
    d = h / 24; h %= 24
    y = d / 365; d %= 365
    return "#{y}y#{d}d" if y > 0
    return "#{d}d#{h}h" if d > 0
    return "#{h}h#{m}m" if h > 0
    return "#{m}m#{s}s" if m > 0
    return "#{s}s"
  end

  def self.space(b) # In bytes
    return nil if not b
    b = b.to_i
    mb = (b / (1024*1024)).to_i
    kb = (b / 1024).to_i
    return "#{mb}M" if mb > 0
    return "#{kb}K" if kb > 0
    "#{b}B"
  end

  def self.datetime(d) # In seconds since Jan 1970
    return nil if not d
    Time.at(d).strftime("%D %H:%M:%S")
  end

  def self.double(x)
    return nil if not x
    x = x.to_f
    return x.to_i.to_s if (x - x.to_i).abs < 1e-40 # An integer (probably)
    return sprintf("%.2e", x) if x.abs < 1e-3 # Scientific notation if close to 0
    # Make sure we have 3 significant digits
    y = x.abs
    return sprintf("%.3f", x) if y < 1
    return sprintf("%.2f", x) if y < 10
    return sprintf("%.1f", x) if y < 100
    return sprintf("%.0f", x)
  end

  # Convert a YAML hash tree to HTML
  def self.hashTreeToHTML(h)
    if h.is_a?(Hash)
      (["<ul class='maketree'>"] +
      h.keys.map{|x| x.to_s}.sort.map { |k| "<li><b>#{k}:</b> #{self.hashTreeToHTML(h[k])}</li>" } +
      ["</ul>"]).join("\n")
    else
      h.to_s
    end
  end
end
