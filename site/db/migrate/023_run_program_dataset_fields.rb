class RunProgramDatasetFields < ActiveRecord::Migration
  def self.up
    add_column :runs, :main_program, :integer
    add_column :runs, :main_dataset, :integer
  end
  def self_down
    remove_column :runs, :main_program
    remove_column :runs, :main_dataset
  end
end
