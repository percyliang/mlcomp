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

# A specification is just a tree structure,
# where nodes are typed objects (strings, programs, datasets)
# that we can encode into a database field.
class Specification
  attr_reader :tree

  def initialize(tree); @tree = tree end

  def to_yaml
    encode = lambda { |tree|
      tree.map { |node|
        case node
          when Array then encode.call(node)
          when Program then ['program', node.id]
          when Dataset then ['dataset', node.id]
          when Class then ['class', node.name]
          else ['string', node.to_s]
        end
      }
    }
    YAML.dump(encode.call(@tree))
  end
  def self.parse(s)
    decode = lambda { |tree|
      raise "Invalid: '#{tree}'" if not tree.is_a?(Array)
      if tree[0].is_a?(String) then # Base case
        type, x = tree
        case type
          when 'program' then Program.findByIdOrNil(x)
          when 'dataset' then Dataset.findByIdOrNil(x)
          when 'class' then Module.const_get(x)
          when 'string' then x
          else raise "Unknown type: '#{type}'"
        end
      else
        tree.map { |node| decode.call(node) }
      end
    }
    self.new(decode.call(YAML.load(s)))
  end

  # Assign each node in the tree a unique node id.
  # Return a list of [node_id, node, children] triples,
  # where each child is [node_id, node]
  def nodes
    list = []
    node_id = 0
    recurse = lambda { |tree|
      root_id = node_id; node_id += 1
      case tree
        when Array then
          children = tree[1..-1].map { |subtree|
            [recurse.call(subtree), subtree.is_a?(Array) ? subtree[0] : subtree]
          }
          list << [root_id, tree[0], children]
        else
          list << [root_id, tree, []]
      end
      root_id
    }
    recurse.call(@tree)
    list
  end

  def construct
    c, *args = @tree
    c.new(args)
  end
end
