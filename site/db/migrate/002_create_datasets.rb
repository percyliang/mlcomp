class CreateDatasets < ActiveRecord::Migration
  def self.up
    create_table :datasets do |t|
      t.string :name, :limit => 60
      t.text :description
      t.text :source
      t.string :task_type
      t.string :location      #local path at which dataset stored
      t.timestamps
    end
    
    create_table :datasets_users do |t|
      t.integer :dataset_id, :user_id
    end
  end
  
  def self.down
    drop_table :datasets
    drop_table :datasets_users
  end
end
