class ProgramProcessed < ActiveRecord::Migration
  def self.up
    add_column :programs, :processed, :boolean
  end

  def self.down
    remove_column :programs, :processed
  end
end
