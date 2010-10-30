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

class ProgramsController < ApplicationController
  before_filter :require_login, :except => ['index', 'show']
  
  def setProgram
    begin
      @program = Program.find(params[:id])
      true
    rescue Exception
      flash[:error] = $!.message
      redirect_to :action => 'index'
      false
    end
  end

  def checkErrors(program)
    errors = program.checkProper
    if errors.size > 0
      flash[:error] = ['Some information needs to be corrected/filled in before it can be used:'] +
        errors.map{|x| "<div>&nbsp; - #{x}</div>"}
      true
    else
      false
    end
  end

  # GET /programs
  # GET /programs.xml
  def index
    @pagetitle << " - Viewing All Programs"
    
    @tparams = Program.create_tparams(:taskTypes => sessionTaskTypes, :showHelpers => isadmin, :showUnprocessed => isadmin,
                                      :default_tparams => {:title => "Programs (#{sessionTaskTypeSimpleStr})"})
  end

  # GET /programs/1
  # GET /programs/1.xml
  def show
    return unless setProgram
    if not @program.proper
      redirect_to :action => 'edit'
      return
    end
    
    @pagetitle << " - Viewing Program #{@program.name}"
    
    @tparams = Run.create_tparams(:datasetFormats => ['(all)'], :default_tparams => {
      :title => "Existing runs on #{@program.name}",
      :filters => [['core_program_id', @program.id]]
    })
  end

  # GET /programs/new
  # GET /programs/new.xml
  def new
    @pagetitle << " - Create New Program"
    @program = Program.new
  end

  # GET /programs/1/edit
  def edit
    return unless setProgram
    checkErrors(@program)
  end
  
  def replace
    return unless setProgram
    if request.post?
      begin
        @program.destroy
        create
      rescue ProgramException
        flash[:error] = 'Failed to delete program: '+$!.message
        format.html { redirect_to(@program) }
        format.xml  { head :ok }
      end
    end
  end

  # POST /programs
  # POST /programs.xml
  def create
    @program = Program.new(params[:program])

    respond_to do |format|
      begin
        @program.init(session[:user], params[:upload])
        flash[:notice] = "Program (#{Format.space(@program.disk_size)}) was successfully uploaded."
        if checkErrors(@program)
          format.html { redirect_to :action => 'edit', :id => @program }
        else
          @program.process
          flash[:notice] += ' Your program is being run on a sample dataset for sanity checking.'
          format.html { redirect_to(@program) }
          format.xml  { render :xml => @program, :status => :created, :location => @program }
        end
      rescue Exception
        @program.destroy

        flash[:error] = 'Failed to create program: '+$!.message
        format.html { render :action => "new" }
        format.xml  { render :xml => @program.errors, :status => :unprocessable_entity }
        @program = Program.new
      end
    end
    
  end

  # PUT /programs/1
  # PUT /programs/1.xml
  def update
    return unless setProgram
    oldProper = @program.proper

    respond_to do |format|
      begin
        @program.attributes = params[:program]
        if checkErrors(@program)
          format.html { render :action => "edit" }
        else
          if not oldProper # Make sure this happens just once when going from not proper to proper
            @program.process
            flash[:notice] = 'Program was successfully updated.  It will be run on a sample dataset for sanity checking.'
          else
            flash[:notice] = 'Program was successfully updated.'
          end
          
          @program.saveMetadata
          format.html { redirect_to(@program) }
          format.xml  { head :ok }
        end
      rescue Exception
        flash[:error] = 'Failed to update program: '+$!.message
        format.html { redirect_to(@program) }
        format.xml  { head :ok }
      end
    end
  end

  # DELETE /programs/1
  # DELETE /programs/1.xml
  def destroy
    return unless setProgram
    respond_to do |format|
      begin
        @program.destroy
        flash[:notice] = "Program was successfully deleted."
        format.html { redirect_to(programs_url) }
        format.xml  { head :ok }
      rescue ProgramException
        flash[:error] = 'Failed to delete program: '+$!.message
        format.html { redirect_to(@program) }
        format.xml  { head :ok }
      end
    end
  end
  
  def view_file
    program = Program.find(params[:id])
    path = Constants::PROGRAMS_DEFAULT_BASE_PATH + "/" + params[:id] + params[:file]
    if File.binary?(path)
      @file = "This is a binary file"
    elsif (not currentUserCanAccess(program))
      @file = "Sorry: Restricted Access!"
    else
       @file = open(path).read
    end
    @filename = params[:file]
    @pagetitle << " - Viewing File #{@filename}"
    render :layout => 'popup_layout'
  end
  
  def create_bundle
    begin
      @program = Program.find(params[:id])
      raise "Program access is restricted" unless currentUserCanAccess(@program)
      @program_bundle_url = bundle(@program.path, "program-#{@program.id}-#{@program.name}")
    rescue Exception
      @program_bundle_error = $!
    end
    render :layout => false
  end

  #def initiate_runs
    #setProgram
    #render :template => 'runs/initiate_runs'
  #end
end
