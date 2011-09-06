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

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  before_filter :action_notification, :modify_domain
  
  def modify_domain
    if params[:domain]
      session[:format_filter] = params[:domain]
    end
  end
  
  def update_format_filter
    format_filter = params[:format_filter_selection]
    unless session[:format_filter] == format_filter
      session[:format_filter] = format_filter
      render :update do |page| 
        page.call 'location.reload' 
      end
    end
  end

  # before_filter :require_login, :except => :login
  # before_filter :require_login, :except => :general_display

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => '0e0b6493b4b241f2aebe006c85f55fc1'
  @@FAQ_FILE = "#{RAILS_ROOT}/lib/FAQ.yml"
  def initialize
    @pagetitle = "MLcomp"	
    @show_format_selector = true
    @questions = YAML::load File.read(@@FAQ_FILE)
  end

  def require_login
    if(session[:user].nil?)
      session[:original_uri] = request.request_uri # Ideally, want this for every page
      errorMessage("You must be logged in to see this page.")
      #flash[:notice] = 'Must log in to see this page'
      #redirect_to :controller => :general_display, :action => 'login'
    end
  end

  def action_notification
    notify_actions = [
      ['datasets', 'create'],
      ['datasets', 'update'],
      ['datasets', 'destroy'],
      ['datasets', 'create_bundle'], 
      ['programs', 'create'],
      ['programs', 'update'],
      ['programs', 'destroy'],
      ['programs', 'create_bundle'], 
      ['runs', 'create'],
      ['runs', 'destroy'],
      ['runs', 'create_bundle'],
      ['users', 'create'],
    nil].compact
    if notify_actions.member?([params[:controller], params[:action]])
      # If logged in, comes from session, if creating new user, comes from params
      if session[:user]
        username = session[:user].username || "anon"
        fullname = session[:user].fullname || "?"
      elsif params[:user]
        username = params[:user]['username'] || "anon"
        fullname = params[:user]['fullname'] || "?"
      end

      hostname = `hostname`.chomp

      # What thing are we operating on
      model = nil
      if params[:controller] == 'datasets' then model = Dataset
      elsif params[:controller] == 'programs' then model = Program
      elsif params[:controller] == 'runs' then model = Run
      end
      if model && params[:id]
        x = model.find(params[:id])
        payload = x ? "#{x.id}:#{x.name}" : params[:id]
      else
        payload = params[:id]
      end

      message = "#{username}@#{hostname} (#{fullname}): #{params[:controller]}.#{params[:action]}(#{payload})"
      Notification::notify_event({:message => message})
    end
  end

  def errorMessage(msg)
    render :text => "<span style=\"color: red\">#{msg}</span>", :layout => true
  end

  def require_admin
    if not isadmin
      errorMessage("You must be an administrator to see this page.")
    end
  end

  def isadmin; session[:isadmin] end

  protected

  # Return the url
  def bundle(dirPath, prefix)
    basePath = "#{RAILS_ROOT}/public/download"
    random = (0...5).map { (?A + rand(26)).chr }.join('')
    name = "#{sanitizeFileName(prefix)}_#{random}.zip" # FUTURE: make this more secure
    outPath = "#{basePath}/#{name}"

    Dir.mkdir(basePath) if not File.exists?(basePath)
    
    if not File.exists?(outPath)
      changePath(File.dirname(dirPath)) {
        systemOrFail('zip', '-q', '-r', outPath, File.basename(dirPath))
      }
      File.chmod(0644, outPath) # Set read permissions on the file
    end

    "/download/#{name}"
  end

  def sanitizeFileName(name)
    name.gsub(/[^\w_\-\.]/, "_")
  end

  # Can pass in program/dataset/run
  def currentUserCanAccess(x)
    (not x.restricted_access) || (isadmin || x.user.id == session[:user].id)
  end

  ############################################################
  # Duplicated in application_helper.rb

  def sessionDatasetFormats
    format = session[:format_filter] || '(all)'
    [format]
    #format == '(all)' || DatasetInfo.datasetFormats.index(format) ? [format] : '(all)'
  end
  def sessionTaskTypes
    # Right now, assume datasetFormat == taskType
    sessionDatasetFormats
  end

  # Duplicated from application_helper
  def sessionDatasetFormatSimpleStr
    format = session[:format_filter] || '(all)'
    if format
      if format == '(all)' then 'all domains'
      else format
      end
    else
      nil
    end
  end
  def sessionTaskTypeSimpleStr; sessionDatasetFormatSimpleStr end

  def sessionDatasetFormatStr
    format = session[:format_filter] || '(all)'
    if format
      if format == '(all)' then 'all domains'
      else "the <em>#{format}</em> domain"
      end
    else
      nil
    end
  end
  def sessionTaskTypeStr; sessionDatasetFormatStr end
end

ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
:default => "%m/%d/%Y",
:date_time12 => "%m/%d/%Y %I:%M%p",
:date_time24 => "%m/%d/%Y %H:%M"
)
