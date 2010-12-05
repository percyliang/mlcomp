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
