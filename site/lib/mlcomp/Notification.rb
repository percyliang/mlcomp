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

# Utilities for notifying (via email)
module Notification
  def self.notify_email(options)
    # TODO: actual send email
    log "SENDING EMAIL: #{options.inspect}"
    #
    ## Following only works if Emailer is set up correctly in
    ## environments.rb. Requires setting an outgoing server, etc.
    ## Check the web for more details.
    #
    # Emailer.deliver_general_email(options[:subject], options[:message])
  end

  def self.notify_event(options)
    options[:subject] ||= "EVENT"
    self.notify_email(options)
  end
  def self.notify_error(options)
    options[:subject] ||= "ERROR"
    self.notify_email(options)
  end
end
