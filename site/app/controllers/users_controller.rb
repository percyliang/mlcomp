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

class UsersController < ApplicationController
  before_filter :require_login, :except => [:new, :create, :login, :login_new, :forgot, :reset, :unsubscribe]
  before_filter :require_admin, :only => [:index, :destroy, :loginas, :announcement]

  def index
    @users = User.find(:all)
  end
  
  def show
    @user = User.find(params[:id])
  end

  def login
    session[:user] = nil
    if request.post?
      user = User.authenticate(params[:username], params[:password])
      session[:username] = params[:username]
      if user
        session[:user] = user
      else
        flash[:password_notice] = "Invalid user/password combination."
      end
      uri = session[:original_uri] 
      if false #uri
        session[:original_uri] = nil
        redirect_to uri
      else
        redirect_to :controller => 'general_display', :action => 'index'
      end
    end
  end
  
  def login_new
    session[:user] = nil
    if request.post?
      user = User.authenticate(params[:username], params[:password])
      session[:username] = params[:username]
      if user
        session[:user] = user
      else
        flash[:password_notice] = "Invalid user/password combination."
      end
    end
    render :update do |page|
      page.call 'location.reload'
    end
  end
  
  def loginas
    if user = User.find(params[:id])
      session[:user] = user
      redirect_to :controller => 'general_display', :action => 'index'
    else
      flash[:error] = "Can find user with id #{params[:id]}"
      redirect_to :controller => 'general_display', :action => 'index'
    end
  end

  def logout
    user = session[:user]
    session[:user] = nil
    session[:tmp_user] = nil
    session[:tmp_user_errors] = nil
    session[:isadmin] = nil
    flash[:notice] = "Logged out user #{user.username}" if user
    redirect_to :controller => 'general_display', :action => 'index'
  end

  def new
    @user = User.new(session[:tmp_user])
    @errors = session[:tmp_user_errors]
  end

  def getUser
    if isadmin
      params[:id] ? User.find(params[:id]) : session[:user] # If we're administrator, can do stuff to any user
    else
      session[:user]
    end
  end
  
  def edit
    @user = getUser
    @user.attributes = session[:tmp_user] if session[:tmp_user]
    @errors = session[:tmp_user_errors]
  end

  def create
    user = User.new(params[:user])
    if user.save
      flash[:notice] = 'Your account was successfully created.  Welcome to MLcomp!'
      session[:user] = user # Login immediately
      session[:tmp_user] = nil
      session[:tmp_user_errors] = nil
      redirect_to :controller => :general_display, :action => :index
    else
      flash[:error] = 'Creating account failed!'
      session[:tmp_user] = params[:user]
      session[:tmp_user_errors] = user.errors
      redirect_to :action => :new
    end
  end

  def update
    user = getUser
    if user.update_attributes(params[:user])
      flash[:notice] = 'Your profile was successfully updated.'
      session[:tmp_user] = nil
      session[:tmp_user_errors] = nil
      if isadmin
        redirect_to :action => :index
      else
        redirect_to :controller => :general_display, :action => :index
      end
    else
      flash[:error] = 'Updating profile failed!'
      session[:tmp_user] = params[:user]
      session[:tmp_user_errors] = user.errors
      redirect_to :action => :edit
    end
  end
  
  def destroy
    user = User.find(params[:id])
    user.destroy
    flash[:notice] = 'User was deleted from database.'
    redirect_to :action => :index
  end
  
  def forgot
    if request.post?
      user = User.find_by_email(params[:email])
      if user
        user.create_reset_code
        flash[:notice] = "Reset code sent to #{user.email}"
      else
        flash[:notice] = "#{params[:email]} does not exist in system"
      end
      redirect_to :controller => 'general_display', :action => 'index'
    end
  end
  
  def reset
    @user = nil
    @user = User.find_by_reset_code(params[:reset_code]) unless params[:reset_code].nil?
    if @user.nil?
      flash[:error] = "There was a problem: Reset Code not found!"
      redirect_to :controller => 'general_display'
    else
      session[:user] = @user
      @user.delete_reset_code
      flash[:notice] = "Please change password for #{@user.username}"
      redirect_to :action => 'edit', :id => @user.id
    end
  end

  def unsubscribe
    @user = User.find(params[:id])
    @code = params[:code]
    if params[:confirm]
      unless @user.user_hash == @code
        flash[:error] = "Incorrect user code! Please contact mlcomp.support@gmail.com"
        render :layout => 'single_column_layout'
      else
        if @user.unsubscribe
          render :template => 'users/unsubscribe_success', :layout => 'single_column_layout'
        else
          flash[:error] = "Error: Unable to unsubscribe. Please contact mlcomp.support@gmail.com"
          render :layout => 'single_column_layout'
        end
      end
    else
      render :layout => 'single_column_layout'
    end
    
  end
  
  def announcements

    # This is code to send out mass announcements

    if request.post?
      subject = params[:email_subject]
      body = params[:email_body]
      recipients = User.find_all_by_receive_emails(true)
      recipients.each do |user|
        tmail_msg = AnnouncementEmailer.create_mass_announcement(user,subject,body)
        Announcement.create_ann(user,"mass_email",tmail_msg)
      end
      flash[:notice] = "Prepared announcements for sending"
    end
  end
end
