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

class TableQuery
  def self.lookup(table_params)
    model = table_params[:model].camelize.constantize
    
    extra_select = ""
    
    if table_params[:current_sort_col]
      sorter = table_params[:current_sort_col]

      extra_select += ", #{table_params[:current_sort_col]} IS NULL AS isnull"
      # sorter += " DESC" if table_params[:reverse_sort]
      # Subtle trick to always put all the nulls at the bottom (unary minus)
      if table_params[:reverse_sort]
         sorter = "isnull ASC, #{sorter} DESC"
       else
         sorter = "isnull ASC, #{sorter} ASC"
       end
    end

    conditions = [[], []]
        
    #puts table_params.inspect
    # Main textual filter: the query can which can be null or an array
    if table_params[:filter_string]
      filterField = table_params[:filter_field] || 'name'
      filterField = [filterField] unless filterField.is_a?(Array)
      conditions[0] << "(" + filterField.map { |f| "#{f} LIKE (?)" }.join(" OR ") + ")"
      conditions[1] += ["%"+table_params[:filter_string]+"%"]*filterField.size
    end 

    # Additional filters
    if table_params[:filters]
      table_params[:filters].each { |k,v,op|
        op = "=" unless op
        conditions[0] << "#{k} #{op} (?)"
        conditions[1] << v
      }
    end

    sql = [conditions[0].join(" AND ")] + conditions[1]
    puts "SQL: #{sql.inspect}"
    #puts "table_params: #{table_params.inspect}"
    
    if table_params[:paginate] and table_params[:limit] and table_params[:pagination_page]
      offset = table_params[:limit] * table_params[:pagination_page]
    else
      offset = 0
    end

    if table_params[:joins]
      if table_params[:joins].is_a?(Array)
        joins = table_params[:joins].map { |x| x.to_sym }
      else
        joins = table_params[:joins].to_sym
      end
    else
      joins = nil
    end
    #puts joins.inspect
    
    select = "#{model.table_name}.*" + extra_select
    #puts select

    items = model.find(:all,
      :select => select,
      :order => sorter,
      :conditions => sql,
      :include => table_params[:include],
      :joins => joins,
      :limit => table_params[:limit] || false,
      :offset => offset)

    # No limit/offset
    total = model.count(:all,
      :conditions => sql,
      :include => table_params[:include],
      :joins => joins)

    if table_params[:paginate]
      if total < table_params[:limit]
        table_params[:pagination_maxed] = true
      else
        table_params[:pagination_maxed] = false
      end
    end
    
    return [items, total, table_params]
  end
end
