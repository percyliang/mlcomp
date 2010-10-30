class Types < ActiveRecord::Migration
  def self.up
    add_column :programs, :constructor_signature, :string
  end
  def self_down
    remove_column :programs, :constructor_signature
  end
end
