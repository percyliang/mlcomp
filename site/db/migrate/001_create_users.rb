class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :username, :limit => 30, :null => false
      t.string :password_hash, :limit => 30, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
