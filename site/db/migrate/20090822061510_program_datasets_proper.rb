class ProgramDatasetsProper < ActiveRecord::Migration
  def self.up
    remove_column :datasets, :valid
    remove_column :programs, :valid
    add_column :datasets, :proper, :boolean
    add_column :programs, :proper, :boolean
  end

  def self.down
    add_column :datasets, :valid, :boolean
    add_column :programs, :valid, :boolean
    remove_column :datasets, :proper
    remove_column :programs, :proper
  end
end
