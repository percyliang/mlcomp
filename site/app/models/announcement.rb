class Announcement < ActiveRecord::Base
  
  belongs_to :user
  
  def self.create_ann(user,type,tmail_obj)
    msg = Announcement.new
    msg.message_type = type
    msg.user = user
    msg.serialized_message = tmail_obj.to_s
    msg.processed = false
    msg.success = false
    msg.save
  end
  
  def send_msg(ignore_processed = false)
    raise "already processed" if self.processed and (not ignore_processed)
    self.processed = true
    self.save
    tmail_msg = TMail::Mail.parse(self.serialized_message)
    self.success = true if AnnouncementEmailer.deliver(tmail_msg)
    self.save
  end
  
end