class RemoveMainProgramId < ActiveRecord::Migration
  def self.up
    remove_column :runs, :main_program_id
  end

  def self.down
    add_column :runs, :main_program_id, :integer
  end
end
