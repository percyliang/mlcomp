class WorkerVersion < ActiveRecord::Migration
  def self.up
    add_column :workers, :version, :integer
  end

  def self.down
    remove_column :workers, :version
  end
end
