class WorkerLastRunTime < ActiveRecord::Migration
  def self.up
    add_column :workers, :last_run_time, :datetime
  end

  def self.down
    remove_column :workers, :last_run_time
  end
end
