class AddFullnameToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :fullname, :string
  end

  def self.down
    remove_column :users, :fullname
  end
end
