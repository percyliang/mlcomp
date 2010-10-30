class CreateRunResults < ActiveRecord::Migration
  def self.up
    create_table :run_results do |t|
      t.string :key
      t.string :value
      t.belongs_to :run
      t.timestamps
    end
  end

  def self.down
    drop_table :run_results
  end
end
