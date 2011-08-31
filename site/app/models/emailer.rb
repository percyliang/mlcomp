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

class Emailer < ActionMailer::Base
  # All of the settings here should probably be changed, these are the
  # default emailer settings for mlcomp's live server

  def user_comment(username, fullname, email, message, url)
    @subject = "User comment from #{username} (#{fullname})"
    @recipients = SITEPARAMS[:notify_recipients]
    @from = 'MLcomp commenter'
    @reply_to = email
    @sent_on = Time.now
    @body = {:username => username, :fullname => fullname, :email => email, :message => message, :url => url}
    @headers = {}
  end
  
  def general_email(subject, body)
    @subject = subject
    @recipients = SITEPARAMS[:notify_recipients]
    @from = 'MLcomp server'
    @sent_on = Time.now
    @body = {:body => body}
    @headers = {}
  end

  def reset_notification(user)
    setup_email(user)
    @subject    += 'Link to reset your password'
    @body[:url]  = "http://mlcomp.org/reset/" + user.reset_code
  end
  
  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = "mlcomp.support@gmail.com"
    @subject     = "[Mlcomp Support] "
    @sent_on     = Time.now
    @body[:user] = user
  end
end
