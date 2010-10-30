class ZeroSortFields < ActiveRecord::Migration
  def self.up
    add_column :programs, :sort0, :double
    add_column :datasets, :sort0, :double
    add_column :runs, :sort0, :double
  end
  def self_down
    remove_column :programs, :sort0
    remove_column :datasets, :sort0
    remove_column :runs, :sort0
  end
end
