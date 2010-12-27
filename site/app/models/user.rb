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

require 'active_record/view'

# FUTURE: include features (confirm email, forgot password, etc.)
# http://www.aidanf.net/rails_user_authentication_tutorial
class User < ActiveRecord::Base
  has_many :datasets
  has_many :programs
  has_many :runs
  has_many :announcements
  
  validates_uniqueness_of :username
  validates_length_of :username, :within => 3..40

  attr_accessor :password_confirmation
  validates_confirmation_of :password
  validates_length_of :password, :within => 6..40

  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => "is invalid"

  has_one :vresult
  class Vresult < ActiveRecord::View
  end

  def name; self.username end # For consistency
  
  def validate
    errors.add_to_base("Username must include only letters and digits") if username =~ /[^\w]/
  end

  def self.internalUser
    internalUserName = "internal"
    # Return the internal user (create one if doesn't exist)
    u = User.find(:first, :conditions => ['username = ?', internalUserName])
    if not u
      log "Creating internal user"
      u = User.new
      u.username = internalUserName
      u.fullname = "Internal User"
      u.password = "SOMETHING"+rand.to_s # Never be able to log in
      u.email = "mlcomp.support@gmail.com"
      u.save!
    end
    u
  end

  def self.authenticate(name,password)
    user = self.find_by_username(name)
    unless user.nil?
      expected_password = encrypted_password(password)
      if user.password_hash != expected_password
        user = nil
      end
    end
    user
  end
  
  def password
    @password
  end
  
  def password=(pwd)
    @password = pwd
    return if pwd.blank?
    self.password_hash = User.encrypted_password(password)
  end
  
  def create_reset_code
    reset_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
    if update_attribute(:reset_code, reset_code)
      if SITEPARAMS[:email_configured]
        Emailer.deliver_reset_notification(self)
      end
    end
  end 
  
  def delete_reset_code
    update_attributes( {:reset_code => nil})
    save(false)
  end
  
  def user_hash
    Digest::SHA1.hexdigest(self.username + "is_this_a_random_string_or_not?")[0..8]
  end
  
  def unsubscribe
    update_attribute(:receive_emails,false)
    save(false)
  end
  
  private
  def self.encrypted_password(password)
    string_to_hash = password + "nonsensecharacters"
    Digest::SHA1.hexdigest(string_to_hash)
  end
end
