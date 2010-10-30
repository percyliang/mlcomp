class ProgramDatasetsValid < ActiveRecord::Migration
  def self.up
    add_column :datasets, :valid, :boolean
    add_column :programs, :valid, :boolean
    add_column :datasets, :restricted_access, :boolean
    add_column :programs, :restricted_access, :boolean
  end

  def self.down
    remove_column :datasets, :valid
    remove_column :programs, :valid
    remove_column :datasets, :restricted_access
    remove_column :programs, :restricted_access
  end
end
