class AddRating < ActiveRecord::Migration
  def self.up
    add_column :programs, :avg_percentile, :double
    add_column :datasets, :avg_stddev, :double
  end

  def self.down
    remove_column :programs, :avg_percentile
    remove_column :datasets, :avg_stddev
  end
end
