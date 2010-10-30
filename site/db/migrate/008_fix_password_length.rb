class FixPasswordLength < ActiveRecord::Migration
  def self.up
    change_column :users, :password_hash, :string, :null => false
  end

  def self.down
    change_column :users, :password_hash, :string, :limit => 30, :null => false
  end
end
