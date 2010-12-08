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

require 'xmlrpc/server'

# http://www.fantasy-coders.de/ruby/xmlrpc4r/server.html
class MLcompServer
  # Crude locking: execute block; guarantee that no other performSafely is executing.
  # Catch exceptions and log them.
  # Return response
  def performSafely(&block)
    # Need to synchronize; otherwise two requests to the same server causes problems
    begin
      @mutex.lock
      result = block.call
      @mutex.unlock
      result
    rescue Exception => e
      @mutex.unlock if @mutex.locked?
      log "EXCEPTION: #{e.message}\n#{e.backtrace.join("\n")}"
      if [ProgramException, DatasetException, RunException, WorkerException].find { |t| e.is_a?(t) } then
        failedResponse(e.message) # Benign failure
      else
        begin
          Notification::notify_error(:message => "#{this.class} exception: #{e.message}")
        rescue Exception => e
          log "ERROR TRYING TO REPORT ERROR!"
        end
        @server.shutdown # This is really bad - we just get out of here (master will be restarted)
      end
    end
  end

  def initialize(args, defaultPort)
    @mutex = Mutex.new

    # local: accept connections only locally (hack for master to work for Macs, because * works)
    port, local, @verbose = extractArgs(:args => args, :spec => [
      ['port', Fixnum, defaultPort],
      ['local', TrueClass, false],
      ['verbose', Fixnum, 0],
    nil])

    log "Starting XMLRPC http server on port #{port}..."
    @server = XMLRPC::Server.new(port, local ? IPSocket.getaddress(Socket.gethostname) : "*", 1000)

    # If this happens, the worker is messed up
    @server.set_default_handler { |name, *args|
      raise XMLRPC::FaultException.new(-99, "Method '#{name}' missing or wrong number of parameters!")
    }
  end

  # Every response is one of these two
  def successResponse(message)
    response = {}
    response['success'] = true
    response['message'] = message
    response
  end
  def failedResponse(message)
    response = {}
    response['success'] = false
    response['message'] = message
    response
  end

  # Get/set fields
  # Note: we need to convert integers to string because
  # integers might be too big (Bignum) for XMLRPC
  def getField(map, key); map[key] or raise "Missing field '#{key}'" end
  def getIntField(map, key); getField(map, key).to_i end
  def getBase64Field(map, key); XMLRPC::Base64.decode(getField(map, key)) end
  def setField(map, key, value); raise "Empty value not allowed for '#{key}'" if value == nil; map[key] = value end
  def setIntField(map, key, value); setField(map, key, value.to_s) end
  def setBase64Field(map, key, value); setField(map, key, XMLRPC::Base64.encode(value)) end
end
