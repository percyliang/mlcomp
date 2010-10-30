class CreateRunStatuses < ActiveRecord::Migration
  def self.up
    create_table :run_statuses do |t|
      t.belongs_to :run, :null => false
      t.integer :max_memory_usage # Over the course of the run (bytes)
      t.integer :memory_usage # The current (final if run is done) (bytes)
      t.integer :max_disk_usage # Over the course of the run (bytes)
      t.integer :disk_usage # The current (final if run is done) (bytes)
      t.integer :real_time # Actual time spent running (milliseconds)
      t.integer :user_time # Effective CPU time (milliseconds)
      t.string :status # One of {ready, inprogress, done}
      t.timestamps
    end
  end

  def self.down
    drop_table :run_statuses
  end
end
