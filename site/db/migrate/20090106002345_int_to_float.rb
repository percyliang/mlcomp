class IntToFloat < ActiveRecord::Migration
  def self.up
    remove_column :datasets, :disk_size
    remove_column :programs, :disk_size
    remove_column :run_statuses, :max_memory_usage
    remove_column :run_statuses, :memory_usage
    remove_column :run_statuses, :max_disk_usage
    remove_column :run_statuses, :disk_usage
    remove_column :runs, :allowed_memory
    remove_column :runs, :allowed_disk
    remove_column :workers, :max_memory
    remove_column :workers, :max_disk

    add_column :datasets, :disk_size, :float
    add_column :programs, :disk_size, :float
    add_column :run_statuses, :max_memory_usage, :float
    add_column :run_statuses, :memory_usage, :float
    add_column :run_statuses, :max_disk_usage, :float
    add_column :run_statuses, :disk_usage, :float
    add_column :runs, :allowed_memory, :float
    add_column :runs, :allowed_disk, :float
    add_column :workers, :max_memory, :float
    add_column :workers, :max_disk, :float
  end

  def self.down
    remove_column :datasets, :disk_size
    remove_column :programs, :disk_size
    remove_column :run_statuses, :max_memory_usage
    remove_column :run_statuses, :memory_usage
    remove_column :run_statuses, :max_disk_usage
    remove_column :run_statuses, :disk_usage
    remove_column :runs, :allowed_memory
    remove_column :runs, :allowed_disk
    remove_column :workers, :max_memory
    remove_column :workers, :max_disk

    add_column :datasets, :disk_size, :integer
    add_column :programs, :disk_size, :integer
    add_column :run_statuses, :max_memory_usage, :integer
    add_column :run_statuses, :memory_usage, :integer
    add_column :run_statuses, :max_disk_usage, :integer
    add_column :run_statuses, :disk_usage, :integer
    add_column :runs, :allowed_memory, :integer
    add_column :runs, :allowed_disk, :integer
    add_column :workers, :max_memory, :integer
    add_column :workers, :max_disk, :integer
  end
end
