require 'mlcomp/Specification'

# Specification for a run.
# Nodes are programs and their children are constructor arguments.
class RunSpecification < Specification
  def initialize(tree); super(tree) end

  def verifyTypes(exceptionClass)
    #puts YAML::load(to_yaml).inspect
    recurse = lambda { |tree|
      tree = [tree] unless tree.is_a?(Array)
      node, *children = tree

      except = lambda { |message|
        case node
          when Program then str = "program #{node.name}"
          when Dataset then str = "dataset #{node.name}"
          else str = node.to_s
        end
        raise exceptionClass.new("At #{str}: #{message}")
      }

      if children.size > 0 && (not node.is_a?(Program))
        except.call("only programs can take arguments")
      end

      if node.is_a?(Program)
        # Make sure constructor signature agree with the types of the arguments
        signature = (node.constructor_signature || "").split
        if signature.size != children.size
          except.call("wanted #{signature.size} (#{node.constructor_signature}), but got #{children.size} arguments")
        end
        (0...signature.size).each { |i|
          sigType = signature[i]
          if sigType =~ /^(\w+):(.+)$/
            argName = $1
            sigType = $2
          end
          child = children[i]
          child = child[0] if child.is_a?(Array)
          case sigType
            when 'string'
            when 'int'
              raise except.call("wanted integer, but got '#{child}'") unless child.to_s.to_i_or_nil
            when 'float'
              except.call("wanted float, but got '#{child}'") unless child.to_s.to_f_or_nil
            when /^Dataset$/, /^Dataset\[(.+)\]$/
              format = $1
              except.call("wanted dataset, but got '#{child.class}'") unless child.is_a?(Dataset)
              except.call("wanted dataset format #{format}, but got #{child.format}") if format && format != child.format
            when /^Program$/, /^Program\[(.+)\]$/
              taskType = $1
              except.call("wanted program, but got '#{child.class}'") unless child.is_a?(Program)
              except.call("wanted task type #{taskType}, but got #{child.task_type}") if taskType && (not child.taskTypes.index(taskType))
            else
              raise exceptionClass.new("Unknown type: '#{sigType}'")
          end
        }
      end

      # Recurse on children
      children.each { |child| recurse.call(child) }
    }
    recurse.call(@tree)
  end

  # Get all the programs and datasets used
  def programs; _extract(Program); end
  def datasets; _extract(Dataset); end
  def _extract(type) # Private
    list = []
    recurse = lambda { |tree|
      tree.each { |node|
        case node
          when type then list << node
          when Array then recurse.call(node)
        end
      }
    }
    recurse.call(@tree)
    list
  end
end
