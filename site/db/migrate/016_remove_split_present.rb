class RemoveSplitPresent < ActiveRecord::Migration
  def self.up
    remove_column :datasets, :user_split_present
  end

  def self.down
    add_column :datasets, :user_split_present, :boolean
  end
end
