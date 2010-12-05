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

# This class provides controller functionality for displaying pages that are generally
#  viewable, such as the index page, about page, etc.
class GeneralDisplayController < ApplicationController
  
  helper :all
  
  # This is no longer needed, everything here is public
  # before_filter :require_login, :except => [:login, :index, :front_page]
  
  def index
    
    @show_format_selector = false
    
    @pagetitle << " - Home"
    
    session[:format_filter] ||= "(all)"
    @program_tparams = Program.create_tparams(:taskTypes => sessionTaskTypes,
      :default_tparams => {
        :title => "Recent programs (#{sessionDatasetFormatSimpleStr})",
        :limit => 5,
        :current_sort_col => 'programs.created_at',
        :reverse_sort => true
      })

    @dataset_tparams = Dataset.create_tparams(:datasetFormats => sessionDatasetFormats,
      :default_tparams => {
        :title => "Recent datasets (#{sessionDatasetFormatSimpleStr})",
        :limit => 5,
        :current_sort_col => 'datasets.created_at',
        :reverse_sort => true
      })

    @run_tparams = Run.create_tparams(:datasetFormats => sessionDatasetFormats,
      :default_tparams => {
        :title => "Recent runs (#{sessionDatasetFormatSimpleStr})",
        :limit => 5,
      })
    # render :layout => 'single_column_layout'
  end
  
  def domain_file
    name = params[:domain]
    if not name
      flash[:error] = "No domain specified"
      render :text => '', :layout => true
    else
      begin
        domain = Domain.get(name)
      rescue
        domain = nil
      end
      if domain
        render :text => IO.readlines(domain.path), :content_type => 'text/plain'
      else
        flash[:error] = "Invalid domain!"
        render :text => '', :layout => true
      end
    end
  end
  
  def mlcomp_tool
    path = ENV['MLCOMP_SOURCE_PATH']+'/mlcomp-tool'
    render :text => File.exists?(path) ? IO.readlines(path) : "", :content_type => 'text/plain'
  end
  def general_rb
    path = ENV['MLCOMP_SOURCE_PATH']+'/site/lib/utils/general.rb'
    render :text => File.exists?(path) ? IO.readlines(path) : "", :content_type => 'text/plain'
  end
  
  def front_page
    @pagetitle = "Welcome to MLcomp"
    if session[:user].nil?
      render :layout => 'single_column_layout'
    else
      redirect_to :controller => 'my_stuff'
    end
  end
  
  def leave_comment
    comment = params[:comment]
    commenturl = params[:commenturl]
    if session[:user] || comment =~ /notspam/ # If logged in or user said notspam
      username = session[:user] ? session[:user].username : "anon"
      fullname = session[:user] ? session[:user].fullname : "anon"
      email = session[:user] ? session[:user].email : nil
      #
      ## Following only works if Emailer is set up correctly in
      ## environments.rb. Requires setting an outgoing server, etc.
      ## Check the web for more details.
      # 
      # Emailer.deliver_user_comment(username, fullname, email, comment, commenturl)
    end
    render :update do |page|
      page.call "$('comment').clear"
      page[:comment_status].replace_html "Comment sent, Thanks!"
      page.visual_effect :fade, 'comment_status', :duration => 5
    end
  end

  def add_comment
    @success = false
    if session[:user]

      commentable_type = params[:comment][:commentable]
      commentable_id = params[:comment][:commentable_id]
      # Get the object that you want to comment
      commentable = Comment.find_commentable(commentable_type, commentable_id)
      params[:comment][:commentable] = commentable

      # Create a comment with the user submitted content
      comment = Comment.new(params[:comment])
      # Assign this comment to the logged in user
      comment.user_id = session[:user].id

      # Add the comment
      commentable.comments << comment
      @success = true
    else
      flash[:error] = "Must be logged in!"
    end


    render :update do |page|
      if @success
        cid = "comment_#{comment.id}"
        page.insert_html :top, :comment_list, "<li id='#{cid}' style='display:none'> </li>"
        page << "$('comment_list').scrollTo()"
        page[cid].replace_html :partial => 'shared/comment', :locals => {:comment => comment}
        page.visual_effect :appear, cid
        page.form.reset :add_comment_form
      else
        page.call 'location.reload'
      end
    end
  end
  
  def delete_comment
    
    @success = false
    @errors = []
    
    unless session[:user].nil?
      if comment = Comment.find(params[:id])
        if comment.user[:id] == session[:user].id
          if comment.destroy
            @success = true
          else
            @errors << "Could not delete comment, not sure why"
          end
        else
          @errors << "That comment does not belong to you"
        end
      else
        @errors << "Comment not found, there was an error"
      end
    end
    
    render :update do |page|
      if @success
        page.visual_effect :switch_off, "comment_#{params[:id]}"
      else
        @errors.each {|err| flash[:error] = err}
        page.call 'location.reload'
      end
    end

  end
  
  def setAdmin
    session[:isadmin] = params[:isadmin]
    redirect_to request.referer
  end
end
