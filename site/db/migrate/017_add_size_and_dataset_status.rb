class AddSizeAndDatasetStatus < ActiveRecord::Migration
  def self.up
    add_column :datasets, :disk_size, :integer
    add_column :programs, :disk_size, :integer
    add_column :datasets, :result, :string
  end

  def self.down
    remove_column :datasets, :disk_size
    remove_column :programs, :disk_size
    remove_column :datasets, :result
  end
end
