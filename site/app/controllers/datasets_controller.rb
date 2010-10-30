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

class DatasetsController < ApplicationController
  before_filter :require_login, :except => ['index', 'show']

  def setDataset
    begin
      @dataset = Dataset.find(params[:id])
      true
    rescue Exception
      flash[:error] = $!.message
      redirect_to :action => 'index'
      false
    end
  end

  def checkErrors(dataset)
    errors = dataset.checkProper
    if errors.size > 0
      flash[:error] = ['Some information needs to be corrected/filled in before it can be used:'] +
        errors.map{|x| "<div>&nbsp; - #{x}</div>"}
      true
    else
      false
    end
  end

  # GET /datasets
  # GET /datasets.xml
  def index
    @pagetitle << " - Viewing All Datasets"
  
    @tparams = Dataset.create_tparams(:datasetFormats => sessionDatasetFormats, :showUnprocessed => isadmin,
                                      :default_tparams => {:title => "Datasets (#{sessionDatasetFormatSimpleStr})"})
  end

  # GET /datasets/1
  # GET /datasets/1.xml
  def show
    return unless setDataset
    if not @dataset.proper
      redirect_to :action => 'edit'
      return
    end
    
    @pagetitle << " - Viewing Dataset #{@dataset.name}"

    @tparams = Run.create_tparams(:datasetFormats => ['(all)'], :default_tparams => {
      :title => "Existing runs on #{@dataset.name}",
      :filters => [['core_dataset_id', @dataset.id]],
      :current_sort_col => 'error',
      :reverse_sort => false
    })
  end

  # GET /datasets/new
  # GET /datasets/new.xml
  def new
    @pagetitle << " - Adding New Dataset"
    @dataset = Dataset.new
  end

  # GET /datasets/1/edit
  def edit
    return unless setDataset
    checkErrors(@dataset)
  end

  def replace
    return unless setDataset
    if request.post?
      begin
        @dataset.destroy
        create
      rescue DatasetException
        flash[:error] = 'Failed to delete dataset: '+$!.message
        format.html { redirect_to(@dataset) }
        format.xml  { head :ok }
      end
    end
  end

  # POST /datasets
  # POST /datasets.xml
  def create
    
    # Three cases:
    # 1. params = {
    #   "action"=>"create", 
    #   "controller"=>"datasets",
    #   "upload_raw_single" => "",
    #   "upload_raw_zip" => "",
    #   "upload_format" => "copy_paste",
    #   "dataset_format" => "MulticlassClassification",
    #   "copy_paste_dataset" => "2 1:1 2:-1 3:00 4:85 5:1 8:1 9:000 12:1 13:-1 15:1 17:1 19:1 22:1 24:1 29:1 33:1 35:1 37:1 39:1 41:1 43:1 44:1 45:0.400 46:0610.0 47:0762 49:0000 51:1 55:1\r\n2 1:1 2:-1 3:00 4:50 5:1 8:1 9:000 12:1 13:-1 15:1 17:1 22:1 24:1 29:1 33:1 35:1 37:1 39:1 41:1 43:1 44:-1 45:0.400 46:0610.0 47:0000 49:0000 51:1 53:1\r\n1 1:1 3:00 4:00 6:-1 7:1 9:000 12:1 15:1 17:1 22:1 24:1 25:1 29:1 33:1 35:1 37:1 39:1 41:1 43:1 44:-1 45:0.800 46:0050.0 47:0000 49:0000 51:1 54:1\r\n"
    # }
    # 
    # 2. params = {
    #   "action"=>"create", 
    #   "controller"=>"datasets",
    #   "upload_raw_single"=>#<ActionController::UploadedStringIO:0x102f36d28>, 
    #   "upload_raw_zip" => "",
    #   "upload_format"=>"single_file", 
    #   "copy_paste_dataset"=>"", 
    #   "dataset_format"=>"Regression"
    # }
    # 
    # 2. params = {
    #   "action"=>"create", 
    #   "controller"=>"datasets",
    #   "upload_raw_single"=>"", 
    #   "upload_raw_zip" => #<ActionController::UploadedStringIO:0x102f36d28>,
    #   "upload_format"=>"zip", 
    #   "copy_paste_dataset"=>"", 
    #   "dataset_format"=>"Regression"
    # }

    @dataset = Dataset.new(params[:dataset])
    selectedFormat = params[:dataset_format]
    method = params[:upload_format]
    
    respond_to do |format|
      begin
        upload = nil
        case method
          when 'single_file'
            upload = params[:upload_raw_single]
          when 'zip'
            upload = params[:upload_raw_zip]
          when 'copy_paste'
            upload = FileContents.new(params[:copy_paste_dataset])
        end
        raise DatasetException.new("No data received using upload method #{method}") if upload == nil

        @dataset.init(session[:user], upload)

        if @dataset.format
          if @dataset.format != selectedFormat
            raise DatasetException.new("Format #{selectedFormat} was selected, but uploaded dataset has format #{@dataset.format}")
          end
        else
          @dataset.format = selectedFormat
          @dataset.saveOrRaise(true)
        end

        flash[:notice] = "Dataset (#{Format.space(@dataset.disk_size)}) was successfully uploaded."
        if checkErrors(@dataset)
          format.html { redirect_to :action => 'edit', :id => @dataset }
        else
          @dataset.process
          flash[:notice] += ' A run was created to process it.'
          format.html { redirect_to(@dataset) }
          format.xml  { render :xml => @dataset, :status => :created, :location => @dataset }
        end
      rescue Exception
        @dataset.destroy

        flash[:error] = 'Failed to create dataset: '+$!.message
        format.html { render :action => "new" }
        format.xml  { render :xml => @dataset.errors, :status => :unprocessable_entity }
        @dataset = Dataset.new
      end
    end
  end

  # PUT /datasets/1
  # PUT /datasets/1.xml
  def update
    return unless setDataset
    oldProper = @dataset.proper

    respond_to do |format|
      begin
        @dataset.attributes = params[:dataset]
        if checkErrors(@dataset)
          format.html { render :action => "edit" }
        else
          if not oldProper # Make sure this happens just once when going from not proper to proper
            @dataset.process
            flash[:notice] = 'Dataset was successfully updated and a run was created to process it.  This might take some time depending on the size of the dataset and availability of computation.  Refresh the page; when the status is "processed", you run programs on your dataset.'
          else
            flash[:notice] = 'Dataset was successfully updated.'
          end
          @dataset.saveMetadata
          format.html { redirect_to(@dataset) }
          format.xml  { head :ok }
        end
      rescue Exception
        flash[:error] = 'Failed to update dataset: '+$!.message
        format.html { redirect_to(@dataset) }
        format.xml  { head :ok }
      end
    end
  end

  # DELETE /datasets/1
  # DELETE /datasets/1.xml
  def destroy
    return unless setDataset
    respond_to do |format|
      begin
        @dataset.destroy
        flash[:notice] = "Dataset was successfully deleted."
        format.html { redirect_to(datasets_url) }
        format.xml  { head :ok }
      rescue DatasetException
        flash[:error] = 'Failed to delete dataset: '+$!.message
        format.html { redirect_to(@dataset) }
        format.xml  { head :ok }
      end
    end
  end

  def create_bundle
    begin
      @dataset = Dataset.find(params[:id])
      raise "Dataset access is restricted" unless currentUserCanAccess(@dataset)
      @dataset_bundle_url = bundle(@dataset.path, "dataset-#{@dataset.id}-#{@dataset.name}")
    rescue Exception
      @dataset_bundle_error = $!
    end
    render :layout => false
  end
end
