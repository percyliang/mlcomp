class AddAdminUser < ActiveRecord::Migration
  def self.up
    #unless User.find_by_username("admin")
      #adminparams = {:username => "admin", :password => "mlcomp", :fullname => "The Administrator"}
      #admin = User.create adminparams;
    #end
  end

  def self.down
    #user = User.find_by_username("admin")
    #unless user.nil?
      #user.destroy
    #end
  end
end
