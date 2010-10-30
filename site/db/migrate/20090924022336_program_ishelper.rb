class ProgramIshelper < ActiveRecord::Migration
  def self.up
    add_column :programs, :is_helper, :boolean
  end

  def self.down
    remove_column :programs, :is_helper
  end
end
