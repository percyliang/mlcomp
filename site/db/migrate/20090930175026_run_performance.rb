class RunPerformance < ActiveRecord::Migration
  def self.up
    add_column :runs, :performance, :double
  end

  def self.down
    remove_column :runs, :performance
  end
end
