class CreatePrograms < ActiveRecord::Migration
  def self.up
    create_table :programs do |t|
      t.string :name, :limit => 60
      t.text :description
      t.string :format    #language of program; binary?
      t.timestamps
    end
    
    create_table(:programs_users, :id => false) do |t|
      t.integer :program_id, :user_id
    end
  end

  def self.down
    drop_table :programs
    drop_table :programs_users
  end
end
