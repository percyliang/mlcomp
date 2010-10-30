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

module RunsHelper
  # Display a specification tree
  def getRunSpecTree(options)
    program = options[:program]
    dataset = options[:dataset]
    tune = options[:tune]
    verbose = true

    if verbose
      domain = Domain.get(dataset.format)
      info_spec_obj = domain.runInfoClass.defaultRunInfoSpecObj(domain, program, dataset, tune).construct
      runInfoToRunSpecTree(info)
    else
      ["<ul class='maketree'>",
      "<li>Program: " + program_link(program) + ": #{program.description}</li>",
      "<li class=\"last\">Dataset: " + dataset_link(dataset) + ": #{dataset.description}</li>",
      "</ul>"].join("\n")
    end
  end

  def runInfoToRunSpecTree(info)
    recurse = lambda { |tree|
      main, *args = tree.map { |node|
        case node
          when Array then recurse.call(node)
          when Program then
            (node.is_helper ? "<b>#{node.name}</b>" : program_link(node)) + ": #{node.description}"
          when Dataset then dataset_link(node) + ": #{node.description}"
          when Class then raise "Invalid type"
          else node.to_s
        end
      }

      if tree[0].is_a?(Program)
        names = tree[0].constructor_signature.split
        args = args.map_with_index { |arg,i|
          "(#{names[i]}) #{arg}"
        }
      end
      lis = args.map { |arg| "<li>#{arg}</li>" }
      lis = lis[0...(lis.length-1)] + [lis.last.gsub('<li>','<li class="last">')]
      ([main, "<ul class='maketree'>"] + lis +  ["</ul>"]).join("\n")
    }
    spec = info.getRunSpecObj
    ["<ul class='maketree'><li class='last'>", recurse.call(spec.tree), "</li></ul>"].join("\n")
  end
  
  def display_runs_list runs
    runs.map do |run|
      "<div>error: FILLIN<br/>id: #{run.id}<br/>status: #{run.status.status}</div>"
    end.join("\n")
  end

	def ownsRun
     isadmin || (session[:user] && @run.user.id == session[:user].id)
  end
  def runShowAllButton
    nice_button('Show all runs', :action => 'index')
  end
  def runKillButton
    nice_button("Terminate this run", {:controller => 'runs', :action => :kill, :id => @run.id}, {:confirm => "Are you sure?"})
  end
  def runDeleteButton
    nice_button("Delete this run", run_path(@run), :method => :delete, :confirm => runDeleteConfirm)
  end
  def runDeleteConfirm
    "Are you sure you want to delete run #{@run.id}?"
  end
end
