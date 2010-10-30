/* --user=rails_user */
use mlcomp_development;

/* List of runs whose core programs are not helpers. */
drop view if exists non_helper_runs;
create view non_helper_runs as select runs.id, runs.error, runs.core_dataset_id, runs.updated_at from runs inner join programs on runs.core_program_id = programs.id where programs.is_helper is null or programs.is_helper = false;

/* TODO: create more composite indices - move into rails migrations */
alter table programs drop index idx_helper;
create index idx_helper on programs (is_helper, id);

/* For each dataset, look at non-helper runs (those whose core programs are not helpers) on that dataset;
   count them and sort them by updated time.
   Warning: when min_error is null, best_core_program_id could still be something */
drop view if exists pre_dataset_vresults;
drop view if exists dataset_vresults;
create view pre_dataset_vresults as select datasets.id dataset_id, count(runs.id) num_runs, max(runs.id) last_run_id, min(runs.error) min_error from datasets left outer join non_helper_runs as runs on datasets.id = runs.core_dataset_id group by datasets.id order by runs.updated_at desc;
/* Now for each dataset, choose the program (if any) that achieves the minimum error. */
create view dataset_vresults as select pre_dataset_vresults.*, runs.id best_run_id, runs.core_program_id best_core_program_id from pre_dataset_vresults left outer join runs on runs.core_dataset_id = dataset_id where runs.error = min_error or min_error is null group by dataset_id;

/* For each program, keep track of the number of runs. */
drop view if exists program_vresults;
create view program_vresults as select programs.id program_id, count(runs.id) num_runs, runs.id last_run_id from programs left outer join runs on programs.id = runs.core_program_id group by programs.id order by runs.updated_at desc;

/* For each user, keep track of time spent running his jobs (both in total and recently) */
drop view if exists user_vresults;
create view user_vresults as select users.id user_id, count(runs.id) num_runs, sum(run_statuses.real_time) total_spent_time, sum(run_statuses.real_time * (run_statuses.updated_at > now() - 5*60*60)) recent_spent_time from users inner join (runs inner join run_statuses on runs.id = run_statuses.run_id) on users.id = runs.user_id group by users.id;
