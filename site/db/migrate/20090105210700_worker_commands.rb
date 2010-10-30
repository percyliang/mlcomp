class WorkerCommands < ActiveRecord::Migration
  def self.up
    add_column :workers, :command, :string
  end

  def self.down
    remove_column :workers, :command
  end
end
