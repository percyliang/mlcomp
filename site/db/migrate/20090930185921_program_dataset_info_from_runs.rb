class ProgramDatasetInfoFromRuns < ActiveRecord::Migration
  def self.up
    # Create in two stages because we need to select the argmin
    create_view :v_dataset_pre_results, "select datasets.id dataset_id, count(runs.id) num_runs, runs.id last_run_id, min(runs.error) min_error from datasets inner join runs on datasets.id = runs.core_dataset_id group by datasets.id order by runs.updated_at desc" do |t|
      t.column :dataset_id
      t.column :num_runs
      t.column :last_run_id
      t.column :min_error
    end
    create_view :v_dataset_results, "select v_dataset_pre_results.*, runs.id best_run_id, runs.core_program_id best_core_program_id from v_dataset_pre_results inner join runs on runs.core_dataset_id = dataset_id where runs.error = min_error group by dataset_id" do |t|
      t.column :dataset_id
      t.column :num_runs
      t.column :last_run_id
      t.column :min_error
      t.column :best_run_id
      t.column :best_core_program_id
    end

    create_view :v_program_results,
      "select programs.id program_id, count(runs.id) num_runs, runs.id last_run_id from programs inner join runs on programs.id = runs.core_program_id group by programs.id order by runs.updated_at desc" do |t|
      t.column :program_id
      t.column :num_runs
      t.column :last_run_id
    end
  end

  def self.down
    drop_view :v_dataset_pre_results
    drop_view :v_dataset_results
    drop_view :v_program_results
  end
end
