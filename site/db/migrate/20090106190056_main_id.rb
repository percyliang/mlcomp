class MainId < ActiveRecord::Migration
  def self.up
    add_column :runs, :core_program_id, :integer
    add_column :runs, :core_dataset_id, :integer
    remove_column :runs, :main_program
    remove_column :runs, :main_dataset
  end

  def self.down
    remove_column :runs, :core_program_id
    remove_column :runs, :core_dataset_id
    add_column :runs, :main_program, :integer
    add_column :runs, :main_dataset, :integer
  end
end
