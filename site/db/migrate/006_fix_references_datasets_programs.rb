class FixReferencesDatasetsPrograms < ActiveRecord::Migration
  def self.up
    drop_table :datasets_users
    add_column :datasets, :user_id, :integer    #datasets belong to users
    
    drop_table :programs_users
    add_column :programs, :user_id, :integer    #programs belong to users
  end

  def self.down
    create_table(:datasets_users, :id=>false) do |t|
      t.integer :dataset_id, :user_id
    end
    remove_column :datasets, :user_id

    create_table(:programs_users, :id => false) do |t|
      t.integer :program_id, :user_id
    end
    remove_column :programs, :user_id
  end
end
