class UserTimes < ActiveRecord::Migration
  def self.up
    create_view :user_vresults,
      "select users.id user_id, count(runs.id) num_runs, sum(run_statuses.user_time) total_spent_time, sum(run_statuses.user_time * (run_statuses.updated_at > curtime() - 5*60*60)) recent_spent_time from users inner join (runs inner join run_statuses on runs.id = run_statuses.run_id) on users.id = runs.user_id group by users.id;" do |t|
      t.column :user_id
      t.column :num_runs
      t.column :total_spent_time
      t.column :recent_spent_time
    end

    # Allow min_error to be null
    drop_view :dataset_vresults
    create_view :dataset_vresults, "select pre_dataset_vresults.*, runs.id best_run_id, runs.core_program_id best_core_program_id from pre_dataset_vresults inner join runs on runs.core_dataset_id = dataset_id where runs.error = min_error or min_error is null group by dataset_id" do |t|
      t.column :dataset_id
      t.column :num_runs
      t.column :last_run_id
      t.column :min_error
      t.column :best_run_id
      t.column :best_core_program_id
    end
  end

  def self.down
    drop_view :user_vresults
    # LAZY: don't change dataset_vresults
  end
end
