class DatasetProcessorFeedback < ActiveRecord::Migration
  def self.up
    add_column :runs, :processed_dataset_id, :integer
    add_column :datasets, :processed, :boolean
  end

  def self.down
    remove_column :runs, :processed_dataset_id
    remove_column :datasets, :processed
  end
end
