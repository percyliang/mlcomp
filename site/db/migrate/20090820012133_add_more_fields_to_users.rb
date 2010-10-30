class AddMoreFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email, :string
    add_column :users, :affiliation, :string
  end

  def self.down
    remove_column :users, :email
    remove_column :users, :affiliation
  end
end
