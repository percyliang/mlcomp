class RunError < ActiveRecord::Migration
  def self.up
    remove_column :runs, :performance
    add_column :runs, :error, :double
  end

  def self.down
    add_column :runs, :performance, :double
    remove_column :runs, :error
  end
end
