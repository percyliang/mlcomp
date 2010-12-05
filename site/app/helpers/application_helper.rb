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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def isadmin; session[:isadmin] end

  def programIcon(width=80); image_tag "program_img2.png", :width => width end
  def datasetIcon(width=80); image_tag "database.png", :width => width end
  def runIcon(width=80); image_tag "server.png", :width => width end
  def helpIcon(width=80); image_tag "book.png", :width => width end

  def midProgramIcon; programIcon(40); end
  def midDatasetIcon; datasetIcon(40); end
  def midRunIcon; runIcon(40); end

  def adminLink
    return "" unless session[:user] && session[:user].is_admin
    def highlight(text); "<font color=\"red\"><b>#{text}</b></font>" end
    def select(text, value)
      link_to(text, { :controller => 'general_display', :action => 'setAdmin', :isadmin => value },
              :id => 'onOffLink', :style => 'padding:0')
    end
    session[:isadmin] ? "[admin: #{highlight('on')} #{select('off', false)}]" :
                        "[admin: #{select('on', true)} #{highlight('off')}]"
  end

  def loggedin?
    not session[:user].nil?
  end

  def dataset_link dset
    return nil unless dset
    link_to shrt(dset.name), { :controller => 'datasets', :action => 'show', :id => dset }, 
    { 
      :class => 'dataset_link', 
      :type => "Dataset",
      :prototip => "true", 
      :name => dset.name, 
      :owner => dset.user && dset.user.username, 
      :desc => dset.description,
      :eltid => dset.id
    }
  end

  def program_link prg
    return nil unless prg
    link_to shrt(prg.name || "(no name)"), { :controller => 'programs', :action => 'show', :id => prg }, { 
      :class => 'program_link', 
      :type => "Program",
      :prototip => "true", 
      :name => prg.name, 
      :owner => prg.user && prg.user.username, 
      :desc => prg.description,
      :eltid => prg.id
    }
  end

  def run_link run
    link_to "Run ##{run.id}", { :controller => 'runs', :action => 'show', :id => run }, { :class => 'run_link' }
  end

  def user_link usr
    if usr
      link_to shrt(usr.username), {:controller => 'users', :action => 'show', :id => usr}, { :class => 'user_link' }
    else
      '(no user)'
    end
  end
  
  def shrt(str,len=20)
    return "" if str.nil?
    return str
    #if str.length >= len
    #  str[0...(len-3)] + "..."
    #else
    #  str
    #end
  end

  def program_task_name obj
    name = obj if obj.class == String
    name = obj.task_type if obj.class == Program
    "<span class='program_type'>#{name}</span>" 
  end

  def run_task_name name
    "<span class='run_type'>#{name}</span>"
  end

  def dataset_task_name obj
    name = obj if obj.class == String
    name = obj.format if obj.class == Dataset
    "<span class='dataset_type'>#{name}</span>"
  end

  def trunc(flt, len=6)
    truncate(flt, len, "")
  end

  def pagination_links_remote(paginator)
    page_options = {:window_size => 1}
    pagination_links_each(paginator, page_options) do |n|
      options = {
        :url => {:action => 'list', :params => params.merge({:page => n})},
        :update => 'table'
      }
      html_options = {:href => url_for(:action => 'list', :params => params.merge({:page => n}))}
      link_to_remote(n.to_s, options, html_options)
    end
  end

  def inside_layout(layout, &block)
    @template.instance_variable_set("@content_for_layout", capture(&block))

    layout = layout.include?("/") ? layout : "layouts/#{layout}" if layout
    buffer = eval("_erbout", block.binding)
    buffer.concat(@template.render_file(layout, true))
  end  

  def add_item_link item
    link_to_function "add_this", "add_to_list('#{item.name}','#{item.id}')"
  end
  
  def button_to_remote(name, options = {}, html_options = {})
    button_to_function(name, remote_function(options), html_options)
  end
  
  def show_hide_item(title, &block)
    randid = (rand 1000000).to_s
    boxid = "show_hide_" + randid
    toggid = "toggle_id_" + randid
    showimg = icon 'arrow_right'
    hideimg = icon 'arrow_down'
    concat("<div class='show_hide_box'>\n", block.binding)
    concat("<span class='show_hide_header'> #{title} " + link_to_function("<span id='#{toggid}'>" + showimg + "</span>", "if ($('#{boxid}').visible()){
    				$('#{boxid}').hide();
    				$('#{toggid}').update('#{showimg}');
    			} else {
    				$('#{boxid}').show();
    				$('#{toggid}').update('#{hideimg}');
    			}", :class => 'icon') + "</span>\n", block.binding)
    concat("<div id='#{boxid}' style='display:none'>", block.binding)
    yield
    concat("</div>\n", block.binding)
    concat("\n</div>\n", block.binding)
  end

  def mlcomp_name
    "<span style='font-variant:small-caps; font-size:1.2em'>MLcomp</span>"
  end

  ############################################################
  # Duplicated in application.rb

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
  
  def icon name
    image_tag "icons/#{name}.gif", :class => 'icon'
  end

  def nice_button(name, options = {}, html_options = {})
    "<span class='buttons'>" + link_to(name, options, html_options) +  "</span>"
  end

  def make_list type, lst
    "<#{type}>\n" + lst.map {|x| "<li>#{x}</li>"}.join("\n") + "</#{type}>"
  end
  
  def info_table pairlist
    "<table class='info_table'>\n" + pairlist.map do |pair|
      "<tr>\n" + "<td class='info_label'>#{pair[0]}</td>" + 
        "<td>#{pair[1]}</td>" +"</tr>\n"
    end.join("\n") + "\n</table>\n"
  end
  
end
