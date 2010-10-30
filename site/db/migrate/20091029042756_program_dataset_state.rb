class ProgramDatasetState < ActiveRecord::Migration
  def self.up
    add_column :programs, :process_status, :string
    add_column :datasets, :process_status, :string
    # Possible states: none, inprogress, success, failed
    (Program.find(:all)+Dataset.find(:all)).each { |x|
      x.process_status = x.processed ? 'success' : 'none'
    }
    remove_column :programs, :processed
    remove_column :datasets, :processed
    add_column :runs, :processed_program_id, :integer
  end

  def self.down
    add_column :programs, :processed, :boolean
    add_column :datasets, :processed, :boolean
    (Program.find(:all)+Dataset.find(:all)).each { |x|
      x.processed = x.process_status != 'success'
    }
    remove_column :programs, :process_status
    remove_column :datasets, :process_status
    remove_column :runs, :processed_program_id
  end
end
