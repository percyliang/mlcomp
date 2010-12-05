require 'mlcomp/MLcompServer'

class CommandServer < MLcompServer
  def CommandServer.main(*args)
    CommandServer.new(args)
  end

  def initialize(args)
    super(args, 7001)

    @handleMap = {} # handle -> user

    @server.add_handler("Login") { |*args| performSafely { login(*args) } }
    @server.add_handler("CreateSimpleRun") { |*args| performSafely { createSimpleRun(*args) } }
    @server.add_handler("CreateGenericRun") { |*args| performSafely { createGenericRun(*args) } }

    @server.serve
  end

  def login(username, password)
    user = User.authenticate(username, password)
    if user # Good
      handle = rand(1000000000)
      log "CommandServer: Assigned user #{username} handle #{handle}"
      @handleMap[handle] = user
      response = successResponse("You got a new handle")
      response['handle'] = handle
      response
    else
      failedResponse('Invalid username/password')
    end
  end

  def createSimpleRun(handle, programStr, datasetStr, tuneHyperparameters)
    user = @handleMap[handle]
    #user = User.internalUser # TMP
    return failedResponse("Invalid handle; please login in again") if not user

    program = nil
    begin
      if programStr =~ /^\d+$/
        program = Program.findByIdOrNil(programStr.to_i)
      else
        program = Program.findByName(programStr, RunException)
      end
    rescue Exception => e
      return failedResponse("Non-existent program ID or name: #{programStr}")
    end
    dataset = nil
    begin
      if datasetStr =~ /^\d+$/
        dataset = Dataset.findByIdOrNil(datasetStr.to_i)
      else
        dataset = Dataset.findByName(datasetStr, RunException)
      end
    rescue Exception => e
      return failedResponse("Non-existent dataset ID or name: #{datasetStr}")
    end

    tuneHyperparameters = tuneHyperparameters == true || tuneHyperparameters == "true"

    begin
      domain = Domain.get(dataset.format)
      info_spec_obj = domain.runInfoClass.defaultRunInfoSpecObj(domain, program, dataset, tuneHyperparameters)
      run = Run.new
      run.init(user, info_spec_obj)
      log "CommandServer: user #{user.username} created simple run #{run.id}"
      response = successResponse("Successfully created run #{run.id}")
      response['runId'] = run.id
      response
    rescue Exception => e
      return failedResponse("Unable to start run: #{e}")
    end
  end

  # description: "- program:svmlight" (YAML string that represents a tree)
  # runSpecTree: [<Program>]
  # info_spec_obj: Specification.new([GenericRunInfo, runSpecTree])
  def createGenericRun(handle, description)
    user = @handleMap[handle]
    #user = User.internalUser
    return failedResponse("Invalid handle; please login in again") if not user

    tree = nil
    begin
      tree = YAML.load(description)
    rescue Exception => e
      return failedResponse("Description is invalid YAML: #{e}")
    end

    runSpecTree = nil
    begin
      runSpecTree = toRunSpecTree(tree)
    rescue Exception => e
      return failedResponse("Interpreting description tree failed: #{e}")
    end

    begin
      info_spec_obj = GenericRunInfo.defaultRunInfoSpecObj(runSpecTree)
      #puts runSpecTree.inspect
      #puts info_spec_obj.to_yaml
      run = Run.new
      run.init(user, info_spec_obj)
      log "CommandServer: user #{user.username} created generic run #{run.id}"
      response = successResponse("Successfully created run #{run.id}")
      response['runId'] = run.id
      response
    rescue Exception => e
      return failedResponse("Problem with run specification: #{e}")
    end
  end

  def toRunSpecTree(rootTree)
    raise "Run description should be an array, not a #{rootTree.class}" unless rootTree.is_a?(Array)
    recurse = lambda { |tree|
      case tree
        when Fixnum then tree
        when Float then tree
        when String
          saveTree = tree
             if tree =~ /^program:(\d+)$/ then tree = Program.findByIdOrNil($1.to_i)
          elsif tree =~ /^program:(.+)$/  then tree = Program.findByName($1, nil)
          elsif tree =~ /^dataset:(\d+)$/ then tree = Dataset.findByIdOrNil($1.to_i)
          elsif tree =~ /^dataset:(.+)$/  then tree = Dataset.findByName($1, nil)
          end
          raise "Non-existent program or dataset (remember, use program:<id> or program:<name>, etc.): #{saveTree}" if not tree
          tree
        when Array then tree.map { |x| recurse.call(x) }
        else raise "Invalid type in YAML: #{tree.class}"
      end
    }
    recurse.call(rootTree)
  end
end
