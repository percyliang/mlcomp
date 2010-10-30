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

class TableController < ApplicationController
  # Query the table given by :model 
  # Filter using (name LIKE %:filter_string%) and :filters
  def query
    @table_params = (JSON.parse params['table_params']).symbolize_keys
    
    @items,@total,@table_params = TableQuery.lookup(@table_params)
    
    if request.xml_http_request?
      # render :partial => "table_data", :layout => false
    else
      render :partial => "table_container", :layout => true, 
        :locals => {:table_params => @table_params}
    end
    
  end
  
  def test_many
    render :partial => 'many_table_show', :layout => true
  end
end
