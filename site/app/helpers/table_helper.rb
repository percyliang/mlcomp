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

module TableHelper

  # table_params[:columns] contains a list of columns specifications to render
  # A column specification can either be
  #  - static (e.g., :prg_name): looked up in table_builders
  #  - dynamic (e.g., FlatPredictionDatasetInfo): gotten from class's getSortField and sortFieldNames

  def coloredText(text, color)
    "<font color=\"#{color}\">#{text}</font>"
  end
  def processorLink(x, text)
    run = x.processorRuns.last
    run ? link_to(text, run_path(run)) : text
  end
  def programStatus(x)
    if not x.proper
      return link_to(coloredText('invalid info', 'red'), edit_program_path(x))
    end
    case x.process_status 
      when 'failed' then processorLink(x, coloredText('check failed', 'red'))
      when 'success' then processorLink(x, 'checked')
      when 'inprogress' then processorLink(x, 'checking')
      else coloredText('unchecked', 'gray')
    end
  end
  def datasetStatus(x)
    if not x.proper
      return link_to(coloredText('invalid info', 'red'), edit_dataset_path(x))
    end
    case x.process_status 
      when 'failed' then processorLink(x, coloredText('processing failed', 'red'))
      when 'success' then processorLink(x, 'processed')
      when 'inprogress' then processorLink(x, 'processing')
      else coloredText('unprocessed', 'gray')
    end
  end
  def runStatus(x)
    case x.status.status
      when 'failed' then coloredText('failed', 'red')
      else x.status.status
    end
  end

  def create_table_builders
    {
    :prg_id => {:dbfield => 'programs.id', :display => :id.to_proc, :colname => "ID", 
      :title => "This is the ID of the program"},
    :prg_name => {:dbfield => :name, :display => 
      lambda {|x| program_link x}, :colname => "Name", :title => "This is the program name"},
    :prg_name_nolink => {:dbfield => :name, :display => :name.to_proc, :colname => "Name"},
    :prg_disk_size => {:dbfield => :disk_size, :display => 
      lambda {|x| Format.space(x.disk_size)}, :colname => "Disk usage"},
    :prg_task_type => {:dbfield => :task_type, :display => 
      lambda {|x| program_task_name x.task_type}, :colname => "Task type"},
    :prg_user => {:dbfield => :user_id, :display => 
      lambda {|x| user_link x.user}, :colname => "User"},
    :prg_user_nolink => {:dbfield => :user_id, :display => 
      lambda {|x| x.user.username}, :colname => "User"},
    :prg_add_to_list_link => {:display => 
      lambda {|x| add_item_link x }, :colname => "Run this?", :nosort => true},
    :prg_create_run => {:dbfield => "", :colname => "", :nosort => true, :display => lambda {|x| link_to_function("run", "prgid_torun = #{x.id}; startRun();", :class => 'icon')}, :nosort => true},
    :prg_add_to_list => {:dbfield => "", :colname => "Add",   :display => 
      lambda {|x| link_to_function "add", "addProgramToList('#{x.name}',#{x.id});"}},
    :prg_created_at => {:dbfield => :created_at, :display =>
      lambda {|x| timeSince(x.created_at, {})}, :colname => "Created"},
    :prg_status => {:dbfield => :processed, :colname => 'Status', :display => lambda { |x| programStatus(x) }, :nosort => true},
    :prg_num_runs => {:dbfield => "program_vresults.num_runs", :display => lambda {|x| x.vresult ? x.vresult.num_runs : 0}, :colname => "#runs", :nosort => true},
    #:prg_last_run => {:dbfield => "vresult.last_run_id", :display => lambda {|x| x.vresult ? x.vresult.last_run : 0}, :colname => "Last run"},
    :prg_avg_percentile => {:dbfield => :avg_percentile, :display => lambda {|x| x.avg_percentile ? (x.avg_percentile*100).to_i : nil}, :colname => "Rating"},

    :dset_id => {:dbfield => 'datasets.id', :display => :id.to_proc, :colname => "ID"},
    :dset_name => {:dbfield => :name, :display => lambda {|x| dataset_link x}, :colname => "Name"},
    :dset_name_nolink => {:dbfield => :name, :display => :name.to_proc, :colname => "Name"},
    :dset_user => {:dbfield => :user_id, :display => 
      lambda {|x| user_link x.user}, :colname => "User"},
    :dset_user_nolink => {:dbfield => :user_id, :display => 
      lambda {|x| x.user.username}, :colname => "User", :nosort => true},
    :dset_format => {:dbfield => :format, :display => 
      lambda {|x| dataset_task_name x.format}, :colname => "Format"}, 
    :dset_source => {:dbfield => :source, :display => 
      lambda {|x| truncate x.source.to_s, 8}, :colname => "Source"},
    :dset_disk_size => {:dbfield => :disk_size, :display => 
      lambda {|x| Format.space(x.disk_size)}, :colname => "Disk usage"},
    :dset_create_run => {:dbfield => "", :display => 
      lambda {|x| link_to_function "run", "dsetid_torun = #{x.id}; startRun();"}, :nosort => true},
    :dset_add_to_list => {:dbfield => "", :colname => "Add", :display => 
      lambda {|x| link_to_function "add", "addDatasetToList('#{x.name}',#{x.id});"}},
    :dset_created_at => {:dbfield => 'datasets.created_at', :display =>
      lambda {|x| timeSince(x.created_at, {})}, :colname => "Created"},
    :dset_status => {:dbfield => :processed, :colname => 'Status', :display => lambda { |x| datasetStatus(x) }, :nosort => true},
    :dset_num_runs => {:dbfield => "dataset_vresults.num_runs", :display => lambda {|x| x.vresult ? x.vresult.num_runs : 0}, :colname => "#runs", :nosort => true},
    :dset_avg_stddev => {:dbfield => :avg_stddev, :display => lambda {|x| x.avg_stddev ? (x.avg_stddev*100).to_i : nil}, :colname => "Rating"},
    :dset_best_error => {:dbfield => "dataset_vresults.min_error", :display => lambda {|x| x.vresult ? Format.double(x.vresult.min_error) : nil}, :colname => "Best error", :nosort => true},
    :dset_best_program => {:dbfield => "dataset_vresults.best_core_program_id", :display =>
      lambda {|x| x.vresult && x.vresult.min_error ? program_link(x.vresult.best_core_program) : nil}, :colname => "Best program", :nosort => true},

    :run_id => {:dbfield => 'runs.id', :display => lambda {|x| link_to "Run ##{x.id}", :controller => 'runs', :action => 'show', :id => x.id}, :colname => "ID"},
    :run_user => {:dbfield => 'runs.user_id', :display => 
      lambda {|x| user_link x.user}, :colname => "User", :nosort => true},
    :run_task_type => {:dbfield => :task_type, :display => 
      lambda {|x| x.core_program ? x.core_program.task_type : "(none)"}, :colname => "Task Type"},
    #:run_created_at => {:dbfield => :created_at, :display => :created_at.to_proc, :colname => "Created At"},
    :run_core_program => {:dbfield => :core_program_id, :display => 
      lambda {|x| x.core_program ? program_link(x.core_program) : "(none)"}, :colname => "Program"},
    :run_core_dataset => {:dbfield => :core_dataset_id, :display => 
      lambda {|x| x.core_dataset ? dataset_link(x.core_dataset) : "(none)"}, :colname => "Dataset"},
    :run_hyper => {:display => 
      lambda {|x| b = x.tuneHyperparameters; b == nil ? nil : (b ? 'yes' : 'no')}, :colname => "Tuned hyper."},
    :run_status => {:dbfield => 'run_statuses.status', :display => 
      lambda {|x| runStatus(x) }, :colname => "Status"},
    :run_updated_at => {:dbfield => 'run_statuses.updated_at', :display =>
      lambda {|x| timeSince(x.updated_at, {})}, :colname => "Updated"},
    :run_time => {:dbfield => 'run_statuses.real_time', :display => lambda {|x| Format.time(x.status.real_time) }, :colname => "Total time"},
    :run_memory => {:dbfield => 'run_statuses.max_memory_usage', :display => lambda {|x| Format.space(x.status.max_memory_usage) }, :colname => "Memory"},
    :run_error => {:dbfield => :error, :display => lambda {|x| Format.double(x.error) }, :colname => "Error"},

    :worker_user => {:dbfield => :user_id, :display => lambda {|x| x.user.username}, :colname => "User"},
    :worker_handle => {:dbfield => :handle, :display => lambda {|x| x.handle}, :colname => "Handle"},
    :worker_host => {:dbfield => :host, :display => lambda {|x| x.host}, :colname => "Host"},
    :worker_version => {:dbfield => :version, :display => lambda {|x| x.version}, :colname => "Version"},
    :worker_current_run => {:dbfield => :current_run_id, :display => 
      lambda {|x| x.current_run ? (link_to x.current_run.id, run_path(x.current_run)) : '(none)'}, 
      :colname => "Current run"},
    :worker_num_cpus => {:dbfield => :num_cpus, :display => 
      lambda {|x| x.num_cpus}, :colname => "# CPUs"},
    :worker_cpu_speed => {:dbfield => :cpu_speed, :display => 
      lambda {|x| "#{x.cpu_speed}MHz"}, :colname => "CPU speed"},
    :worker_max_memory => {:dbfield => :max_memory, :display => 
      lambda {|x| Format.space(x.max_memory)}, :colname => "Memory"},
    :worker_max_disk => {:dbfield => :max_disk, :display => 
      lambda {|x| Format.space(x.max_disk)}, :colname => "Disk"},
    :worker_updated_at => {:dbfield => :updated_at, :display =>
      lambda {|x| timeSince(x.updated_at, {0 => 'green', 60 => 'brown', 60*60 => 'red'})}, :colname => "Last ping"}
    }
  end

  def timeSince(time, colorSchedule)
    dt = Time.now - time
    color = nil
    colorSchedule.keys.sort.map { |qt|
      color = colorSchedule[qt] if dt > qt
    }
    coloredText("#{Format.time(dt)} ago", color)
  end

  def make_nice_table headers, body, title = nil
    table_html = "<thead>"
    table_html << "<tr><td colspan=#{headers.length} class='table_header'>#{title}</td></tr>" unless title.nil?
    table_html << "<thead><tr>" + headers.map {|x| "<th>" + x.to_s + "</th>" }.join(" ") + "\n"
    table_html << "</tr></thead>"
    table_html << "<tbody>"
    if body.length == 0
      table_html << "<tr class='even'><td colspan=#{headers.length.to_s} style='font-weight:bold; text-align:center; font-size:1.2em'>(no items)</td></tr>\n"
      #table_html << "<tr class='even'><td colspan=#{headers.length.to_s} style='font-weight:bold; text-align:center; font-size:1.2em'> Sorry, no items to display!</td></tr>\n"
    end
    body.each do |row|
      table_html << "<tr class='#{cycle('even','odd')}'>\n" + row.map {|x| "<td>" + x.to_s + "</td>" }.join(" ") + "\n</tr>\n"
    end
    
    table_html << "</tbody>"
    table_html = "<table class=\"sorted_table_box\" cellpadding=2 cellspacing=0>\n" + table_html + "\n</table>\n"
  end

  def sort_link_helper2(text, colname, table_name, title_text, nowsort)
    change_params_fn = "if (getTableValue('#{table_name}','current_sort_col') == '#{colname}') {
    updateTableElt('#{table_name}','reverse_sort', !(getTableValue('#{table_name}','reverse_sort')));
    } else {
      updateTableElt('#{table_name}','reverse_sort', false);
      updateTableElt('#{table_name}','current_sort_col', '#{colname}');
      };
      updateTableElt('#{table_name}','pagination_page', 0);
      updateTable('#{table_name}');"
      text = text + nowsort if nowsort
      link_to_function(text, change_params_fn, :class => (nowsort ? "sortingon" : ""), :title => title_text || "")
    end

    def sort_td_class_helper(param)
      # This just changes the css class of the table header depending on the order of the sort
      result = 'class="sortup"' if params[:sort] == param
      result = 'class="sortdown"' if params[:sort] == param + "_reverse"
      return result
    end

    def pagination_line(tparams, numitems, total)
      return "&nbsp;" if total == 0
      startnum = tparams[:pagination_page] * tparams[:limit] + 1
      endnum = startnum + numitems - 1
      if tparams[:pagination_page] > 0
        lowerpage_link = link_to_function(h("<"), "updateTableElt(
        '#{tparams[:name]}', 'pagination_page', #{tparams[:pagination_page] - 1});
        updateTable('#{tparams[:name]}');", :class => 'table_nav_button')
      else
        lowerpage_link = "<span class='table_nav_button_inactive'>#{h('<')}</span>"
      end
      raisepage_link = link_to_function(h(">"), "updateTableElt(
      '#{tparams[:name]}', 'pagination_page', #{tparams[:pagination_page] + 1});
      updateTable('#{tparams[:name]}');", :class => 'table_nav_button')
      raisepage_link = "<span class='table_nav_button_inactive'>#{h('>')}</span>" if startnum + tparams[:limit] > total
      paginate_links = (numitems < total) ?  (lowerpage_link + " " +  raisepage_link) : "&nbsp;"
      out = "#{startnum}-#{endnum} of #{total} " + paginate_links
      return out
    end  
  end
