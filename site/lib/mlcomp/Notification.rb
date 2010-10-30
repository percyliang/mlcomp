# Utilities for notifying (via email)
module Notification
  def self.notify_email(options)
    # TODO: actual send email
    log "SENDING EMAIL: #{options.inspect}"
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
