class CreateAnnouncements < ActiveRecord::Migration
  def self.up
    create_table :announcements do |t|
      t.string :serialized_message, :limit => 2.megabytes
      t.string :message_type
      t.integer :user_id
      t.boolean :processed, :default => false
      t.boolean :success, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :announcements
  end
end
