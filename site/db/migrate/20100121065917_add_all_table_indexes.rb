class AddAllTableIndexes < ActiveRecord::Migration
  def self.up
    add_index :runs, [:core_dataset_id,  :error]
    add_index :runs, [:core_program_id, :error]
    add_index :runs, [:user_id]
    add_index :run_programs, [:run_id, :program_id]
    add_index :run_datasets, [:run_id, :dataset_id]
    add_index :datasets, [:user_id]
    add_index :programs, [:user_id]
    add_index :runs, [:processed_dataset_id]
    add_index :runs, [:processed_program_id]
  end

  def self.down
    remove_index :runs, [:core_dataset_id, :error]
    remove_index :runs, [:core_program_id, :error]
    remove_index :runs, [:user_id]
    remove_index :run_programs, [:run_id, :program_id]
    remove_index :run_datasets, [:run_id, :dataset_id]
    remove_index :datasets, [:user_id]
    remove_index :programs, [:user_id]
    remove_index :runs, :processed_dataset_id
    remove_index :runs, :processed_program_id
  end
end