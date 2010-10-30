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

require 'lib_autoloader'

class WorkersController < ApplicationController
  before_filter :require_login

  def prune
    Worker.findInactive.each { |worker| worker.destroy }
    respond_to do |format|
      flash[:notice] = 'Unresponsible workers pruned.'
      format.html { redirect_to :action => 'index' }
      format.xml
    end
  end
  
  def index
    @workers = Worker.find(:all)

    myCols = [:worker_handle, :worker_host, :worker_version, :worker_current_run, :worker_num_cpus, :worker_cpu_speed, :worker_max_memory, :worker_max_disk, :worker_updated_at]
    allCols = [:worker_user] + myCols

    tparams = []
    tparams << ['(all)', allCols]
    tparams << ['(mine)', myCols, [['user_id', session[:user].id]]] if session[:user]

    # Create table_params
    @tparams = tparams.map { |name,cols,filters|
      [name, {
        :columns => cols,
        :name => "workers",
        :model => 'Worker', 
        :filters => filters,
        :limit => 100,
        :width => '100%',
        :current_sort_col => 'updated_at',
        :reverse_sort => true,
        :paginate => true,
        :pagination_page => 0, 
        :show_footer => true,
      }]
    }
  end

  def show
    @worker = Worker.find(params[:id])
  end
end
