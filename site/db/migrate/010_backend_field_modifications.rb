class BackendFieldModifications < ActiveRecord::Migration
  def self.up
    ###modify datasets table
    remove_column :datasets, :task_type
    add_column :datasets, :format, :string
    add_column :datasets, :user_split_present, :boolean   #is there a user-specified split for this dataset?

    ###modify programs table
    remove_column :programs, :format
    add_column :programs, :task_type, :string

    ###modify runs table
    remove_column :runs, :program_id
    remove_column :runs, :dataset_id
    add_column :runs, :main_program_id, :integer

    ###create run_construct_arg_programs table
    ###for linking runs to the program arguments passed to the
    ###  construct task function
    ###the construct argument programs for a given run should be ordered
    ###  by increasing id in this table
    create_table :run_construct_arg_programs do |t|
      t.belongs_to :run
      t.belongs_to :program
      t.timestamps
    end
    
    ###create run_datasets
    ###for linking runs to their dataset tuples
    ###the datasets of a given run should be ordered by increasing id in
    ###  this table
    create_table :run_datasets do |t|
      t.belongs_to :run
      t.belongs_to :dataset
      t.timestamps
    end
  end

  def self.down
    ###undo modifications to datasets table
    add_column :datasets, :task_type, :string
    remove_column :datasets, :format
    remove_column :datasets, :user_split_present

    ###undo modifications to programs table
    add_column :programs, :format, :string
    remove_column :programs, :task_type

    ###undo modifications to runs table
    add_column :runs, :program_id, :integer
    add_column :runs, :dataset_id, :integer
    remove_column :runs, :main_program_id
    
    ###drop newly created tables
    drop_table :run_construct_arg_programs
    drop_table :run_datasets
  end
end
