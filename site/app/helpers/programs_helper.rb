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

module ProgramsHelper
  
  def display_dir_tree prog
    begin
      display_tree_helper prog.directory_tree, prog
    rescue Exception => e
      return "There was an error<br>" + e.backtrace.join("<br>")
    end
  end

  def display_tree_helper h, prog
    if h.is_a?(Hash)
      tree_bod = []
      trkeys = h.keys.sort
      trkeys.each_with_index do |k,ind| 
        cls = (ind == trkeys.length - 1 ? ' class="last"' : '')
        tree_bod << "<li#{cls}><b>#{k}</b> #{display_tree_helper(h[k], prog)}</li>"
      end
      (["<ul class='maketree'>"] + tree_bod + ["</ul>"]).join("\n")
    else
      link_to "view", {:controller => 'programs', :action => 'view_file', :file => h.to_s, :id => prog}, :popup => ['new_window_name', 'height=700,width=640']# + "\n" + "<div id='file_#{h}' style='display:none;'></div>"
    end
  end

	def ownsProgram
     isadmin || (session[:user] && @program.user.id == session[:user].id)
  end
  def programShowAllButton
    nice_button('Show all programs', :action => 'index')
  end
  def programShowButton
    nice_button('Show info', program_path(@program))
  end
  def programNewButton
    nice_button('Upload new program', :action => 'new')
  end
  def programEditButton
    nice_button('Edit info', edit_program_path(@program))
  end
  def programReplaceButton
    nice_button("Re-upload", :action => 'replace', :id => @program.id)
  end
  def programDeleteButton
    nice_button("Delete this program", program_path(@program), :method => :delete,
      :confirm => programDeleteConfirm)
  end
  def programDeleteConfirm
    msg = "Are you sure you want to delete program #{@program.name}?"
    msg += " WARNING: doing so will delete its #{@program.runs.size} run(s)!" if @program.runs.size > 0
    msg
  end
end
