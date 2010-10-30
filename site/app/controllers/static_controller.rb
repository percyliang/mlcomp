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

class StaticController < ApplicationController
  NO_CACHE = []

  def index
    path = 'static/' + params[:path].join('/')
    fullpath = 'app/views/' + path
    begin
      if path =~ /\.(html)$/
        render :text => File.read(fullpath), :layout => true  
      elsif path =~ /\.(erb)$/
        render :template => path, :layout => true
      else 
        send_file fullpath        
      end
    rescue Exception => e
      puts e.inspect
      render :file => "#{RAILS_ROOT}/public/404.html", :status => 404 and return
    end
  end

end
