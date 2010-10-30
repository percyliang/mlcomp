class OuterJoin < ActiveRecord::Migration
  def self.up
    drop_view :pre_dataset_vresults
    create_view :pre_dataset_vresults,
      "select datasets.id dataset_id, count(runs.id) num_runs, runs.id last_run_id, min(runs.error) min_error from datasets left outer join runs on datasets.id = runs.core_dataset_id group by datasets.id order by runs.updated_at desc" do |t|
      t.column :dataset_id
      t.column :num_runs
      t.column :last_run_id
      t.column :min_error
    end

    drop_view :dataset_vresults
    create_view :dataset_vresults,
      "select pre_dataset_vresults.*, runs.id best_run_id, runs.core_program_id best_core_program_id from pre_dataset_vresults left outer join runs on runs.core_dataset_id = dataset_id where runs.error = min_error or min_error is null group by dataset_id" do |t|
      t.column :dataset_id
      t.column :num_runs
      t.column :last_run_id
      t.column :min_error
      t.column :best_run_id
      t.column :best_core_program_id
    end

    drop_view :program_vresults
    create_view :program_vresults,
      "select programs.id program_id, count(runs.id) num_runs, runs.id last_run_id from programs left outer join runs on programs.id = runs.core_program_id group by programs.id order by runs.updated_at desc" do |t|
      t.column :program_id
      t.column :num_runs
      t.column :last_run_id
    end
  end

  def self.down
  end
end
