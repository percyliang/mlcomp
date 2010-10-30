class UpdateWorkerFields < ActiveRecord::Migration
  def self.up
    drop_table :workers_users
    drop_table :workers_runs
    add_column :workers, :user_id, :integer
    add_column :workers, :current_run_id, :integer
  end

  def self.down
    create_table :workers_users do |t|
      t.integer :worker_id, :user_id
    end
    create_table :workers_runs do |t|
      t.integer :worker_id, :run_id
    end
    remove_column :workers, :user_id
    remove_column :workers, :current_run_id
  end
end
