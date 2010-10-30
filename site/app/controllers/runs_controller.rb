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

class RunsController < ApplicationController
  before_filter :require_login, :except => ['index', 'show', 'update_show', 'create_popup']

  # GET /runs
  # GET /runs.xml
  def index
    @pagetitle << " - View All Runs"
    @tparams = Run.create_tparams(:datasetFormats => sessionDatasetFormats, :showHelpers => session[:isadmin])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @runs }
    end
  end

  def show
    @run = Run.find(params[:id])
    if @run.status.status == "ready"
      @queue_size = RunStatus.count({:conditions => "status = 'ready'"})
      @queue_pos = RunStatus.find_all_by_status("ready").index(@run.status)
    end
    @pagetitle << " - Viewing Run #{@run.id}"

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @run }
    end
  end
  
  def update_show
    @run = Run.find(params[:id])
    render :update do |page|
      page[:run_status_box].reload :locals => {:run => @run}
      page[:run_log_box].replace_html @run.logContentsStr
      if @run.status.status == "done" || @run.status.status == "failed"
        page << "executor.stop();"
      end
      if @run.status.status == "running"
        page << "setExecutor(10)"
      end
    end
  end

  # GET /runs/new
  # GET /runs/new.xml
  def new
    @run = Run.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @run }
    end
  end

  def create_run(program, dataset, tune, allowedTime) # (minutes)
    run = Run.new
    domain = Domain.get(dataset.format)
    run.init(session[:user], domain.runInfoClass.defaultRunInfoSpecObj(domain, program, dataset, tune))
    run.allowed_time = allowedTime * 60 # Convert to seconds
    run.save!
    run
  end

  def create_popup
    @pagetitle << " - Create Run"
    
    if request.post?
      @successes, @errors = [], []
      begin
        program = Program.find(params[:run][:program_id])
        dataset = Dataset.find(params[:run][:dataset_id])
        tune = params[:run][:tune] || false
        allowedTime = params[:run][:allowedTime].to_f * 60
        @run = create_run(program, dataset, tune, allowedTime)
        @successes << {:program => program.name, :dataset => dataset.name}
      rescue RunException => error
        @errors << error
      end
      render :update do |page|
        page.replace_html 'creation_result', :partial => "create_run_success"
        page.call 'countDownClose'
        page << "window.opener.updateTable('runs')"
      end
      # render :partial => "create_run_success"
      # render :action => 'creation_outcomes'
      # render :text => "success"
    else
      @program = Program.find(params[:program_id])
      @dataset = Dataset.find(params[:dataset_id])
      @tune = false
      render :layout => 'popup_layout'
    end
  end
  
  def display_run_spec_tree
    @program = Program.find(params[:run][:program_id])
    @dataset = Dataset.find(params[:run][:dataset_id])
    @tune = params[:run][:tune]
    render :partial => 'run_spec'
  end
  
  def compare
    @pagetitle << " - Compare Results"
  end
  
  def compare_update_tables
    @dset_format = params[:id]
    render :update do |page|
		  page << "new Effect.BlindUp('task_type_question')"
      page.replace_html :dset_choose, :partial => 'dset_choose'
      page.replace_html :prg_choose, :partial => 'prg_choose'
      page << "new Effect.BlindDown('programs_and_datasets_box', {queue: 'end'})"
    end
  end
  
  
  def make_comparison
    @programs = Program.find(JSON.parse(params[:programs]))
    @datasets = Dataset.find(JSON.parse(params[:datasets]))
    @matrix = Run.existingRunsMatrix(@programs,@datasets)
    render :update do |page|
      page[:output].replace_html :partial => 'runs_comparison'
      page << "new Effect.BlindUp('programs_and_datasets_box');"
      page << "new Effect.Appear('results_box', {queue: 'end'});"
    end
  end

  # PUT /runs/1
  # PUT /runs/1.xml
  def update
    @run = Run.find(params[:id])

    respond_to do |format|
      if @run.update_attributes(params[:run])
        flash[:notice] = 'Run was successfully updated.'
        format.html { redirect_to(@run) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @run.errors, :status => :unprocessable_entity }
      end
    end
  end

  def kill
    @run = Run.find(params[:id])
    respond_to do |format|
      if @run.running?
        @run.worker.killCurrentRun
        flash[:notice] = 'Run will be terminated.'
        format.html { redirect_to(@run) }
        format.xml  { render :xml => @run, :status => :created, :location => @run }
      else
        flash[:error] = 'Run is not running on any worker.'
        format.html { redirect_to(@run) }
        format.xml  { render :xml => @run, :status => :created, :location => @run }
      end
    end
  end

  # DELETE /runs/1
  # DELETE /runs/1.xml
  def destroy
    @run = Run.find(params[:id])
    respond_to do |format|
      begin
        @run.destroy
        flash[:notice] = "Run was successfully deleted."
        format.html { redirect_to(runs_url) }
        format.xml  { head :ok }
      rescue RunException
        flash[:error] = 'Failed to delete run: '+$!
        format.html { redirect_to(@run) }
        format.xml  { head :ok }
      end
    end
  end

  def create_bundle
    begin
      @run = Run.find(params[:id])
      raise "Run access is restricted" if (not session[:isadmin]) && @run.restricted_access(session[:user])
      @run_bundle_url = bundle(@run.path, "run-#{@run.id}")
    rescue Exception
      @run_bundle_error = $!
    end
    render :layout => false
  end
end
