class CreateRuns < ActiveRecord::Migration
  def self.up
    create_table :runs do |t|
      t.belongs_to :user
      t.belongs_to :program, :null => false
      t.belongs_to :dataset, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :runs
  end
end
