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

class AnnouncementEmailer < AnnouncementMailer
  def mass_announcement(user,subject,body)
    @subject = "[MLcomp News] " + subject
    @from = 'MLcomp Team <noreply@mlcomp.org>'
    @body[:main_text] = body
    @body[:user] = user
    @body[:url] = url_for(:controller => 'users', :action => 'unsubscribe', 
      :id => user.id, :code => user.user_hash, :host => "mlcomp.org")
    @sent_on = Time.now
    @headers = {}
    @recipients = [user.email]
  end
end
