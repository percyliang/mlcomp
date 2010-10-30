class AddInfoSpec < ActiveRecord::Migration
  def self.up
    add_column :runs, :info_spec, :string
  end

  def self.down
    remove_column :runs, :info_spec
  end
end
