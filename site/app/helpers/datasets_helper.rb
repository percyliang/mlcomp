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

module DatasetsHelper
	def ownsDataset
     isadmin || (session[:user] && @dataset.user.id == session[:user].id)
  end
  def datasetShowAllButton
    nice_button('Show all datasets', :action => 'index')
  end
  def datasetShowButton
    nice_button('Show info', dataset_path(@dataset))
  end
  def datasetNewButton
    nice_button('Upload new dataset', :action => 'new')
  end
  def datasetEditButton
    nice_button('Edit info', edit_dataset_path(@dataset))
  end
  def datasetReplaceButton
    nice_button("Re-upload", :action => 'replace', :id => @dataset.id)
  end
  def datasetDeleteButton
    nice_button("Delete this dataset", dataset_path(@dataset), :method => :delete,
      :confirm => datasetDeleteConfirm)
  end
  def datasetDeleteConfirm
    msg = "Are you sure you want to delete dataset #{@dataset.name}?"
    msg += " WARNING: doing so will delete its #{@dataset.runs.size} run(s)!" if @dataset.runs.size > 0
    msg
  end
end
