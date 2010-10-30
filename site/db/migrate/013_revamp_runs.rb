class RevampRuns < ActiveRecord::Migration
  def self.up
    add_column :runs, :specification, :text
    add_column :runs, :result, :text
    add_column :runs, :allowed_time, :integer
    add_column :runs, :allowed_memory, :integer
    add_column :runs, :allowed_disk, :integer

    create_table :run_programs do |t|
      t.belongs_to :run
      t.belongs_to :program
      t.timestamps
    end

    drop_table :run_construct_arg_programs
    drop_table :run_results
  end

  def self.down
    remove_column :runs, :specification
    remove_column :runs, :result
    remove_column :runs, :allowed_time
    remove_column :runs, :allowed_memory
    remove_column :runs, :allowed_disk

    drop_table :run_programs

    create_table :run_construct_arg_programs do |t|
      t.belongs_to :run
      t.belongs_to :program
      t.timestamps
    end
    create_table :run_results do |t|
      t.string :key
      t.string :value
      t.belongs_to :run
      t.timestamps
    end
  end
end
