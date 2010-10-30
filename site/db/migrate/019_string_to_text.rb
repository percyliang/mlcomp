class StringToText < ActiveRecord::Migration
  def self.up
    change_column :datasets, :result, :text
    change_column :runs, :info_spec, :text
  end

  def self.down
    change_column :datasets, :result, :string
    change_column :runs, :info_spec, :string
  end
end
