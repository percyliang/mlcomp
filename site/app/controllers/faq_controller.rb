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

require 'json'
require 'yaml'
require 'lib_autoloader'
class FaqController < ApplicationController
  
  def index
    @sections = @questions.map{|x| x['tags']}.flatten.select {|x| x =~ /section_/}.map{|x| x.gsub("section_","")}.uniq
  end
  
  def save_faq
    faq_data = JSON.parse params[:faq_data]
    faq_data.each{|x| x["tags"] = x["tags"].split(",").map{|str| str.gsub(/[ \t]+/,"")}}
    save_dir = "#{RAILS_ROOT}/lib/FAQsaved"
    `mkdir #{save_dir}` unless File::exists?(save_dir)
    save_file = save_dir + "/FAQsave_" + Time.now.to_i.to_s + ".yml"
    `cp #{@@FAQ_FILE} #{save_file}`
    File.open(@@FAQ_FILE, "w") do |f|
      f.write faq_data.to_yaml
    end 
    flash[:notice] = " FAQ saved successfully "
    redirect_to :action => 'index'
  end

end
