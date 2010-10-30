class RunWorker < ActiveRecord::Migration
  def self.up
    add_column :runs, :worker_id, :integer
  end

  def self.down
    remove_column :runs, :worker_id
  end
end
