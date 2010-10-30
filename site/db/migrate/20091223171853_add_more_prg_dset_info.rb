class AddMorePrgDsetInfo < ActiveRecord::Migration
  def self.up
    add_column :datasets, :url, :string
    add_column :datasets, :author, :string
    add_column :programs, :url, :string
    add_column :programs, :language, :string
    add_column :programs, :tuneable, :boolean
  end

  def self.down
    remove_column :datasets, :url
    remove_column :datasets, :author
    remove_column :programs, :url
    remove_column :programs, :language
    remove_column :programs, :tuneable
  end
end
