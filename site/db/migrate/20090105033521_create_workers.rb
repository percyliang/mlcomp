class CreateWorkers < ActiveRecord::Migration
  def self.up
    create_table :workers do |t|
      t.string :handle
      t.string :host, :limit => 60
      t.integer :num_cpus
      t.integer :cpu_speed
      t.integer :max_memory
      t.integer :max_disk
      t.timestamps
    end

    create_table :workers_users do |t|
      t.integer :worker_id, :user_id
    end
    create_table :workers_runs do |t|
      t.integer :worker_id, :run_id
    end
  end

  def self.down
    drop_table :workers
    drop_table :workers_users
    drop_table :workers_runs
  end
end
