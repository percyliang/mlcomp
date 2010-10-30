class RenameAdmin < ActiveRecord::Migration
  def self.up
    remove_column :users, :admin
    add_column :users, :is_admin, :boolean
  end

  def self.down
    remove_column :users, :is_admin
    add_column :users, :admin, :boolean
  end
end
