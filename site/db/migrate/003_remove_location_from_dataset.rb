class RemoveLocationFromDataset < ActiveRecord::Migration
  def self.up
    remove_column :datasets, :location
  end

  def self.down
    add_column :datasets, :location, :string
  end
end
