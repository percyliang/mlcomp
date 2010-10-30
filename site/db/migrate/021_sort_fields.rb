class SortFields < ActiveRecord::Migration
  def self.up
    add_column :programs, :sort1, :double
    add_column :programs, :sort2, :double
    add_column :programs, :sort3, :double
    add_column :programs, :sort4, :double
    add_column :programs, :sort5, :double
    add_column :datasets, :sort1, :double
    add_column :datasets, :sort2, :double
    add_column :datasets, :sort3, :double
    add_column :datasets, :sort4, :double
    add_column :datasets, :sort5, :double
    add_column :runs, :sort1, :double
    add_column :runs, :sort2, :double
    add_column :runs, :sort3, :double
    add_column :runs, :sort4, :double
    add_column :runs, :sort5, :double
  end
  def self_down
    remove_column :programs, :sort1
    remove_column :programs, :sort2
    remove_column :programs, :sort3
    remove_column :programs, :sort4
    remove_column :programs, :sort5
    remove_column :datasets, :sort1
    remove_column :datasets, :sort2
    remove_column :datasets, :sort3
    remove_column :datasets, :sort4
    remove_column :datasets, :sort5
    remove_column :runs, :sort1
    remove_column :runs, :sort2
    remove_column :runs, :sort3
    remove_column :runs, :sort4
    remove_column :runs, :sort5
  end
end
