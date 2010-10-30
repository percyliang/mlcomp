# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20101007183241) do

  create_table "announcements", :force => true do |t|
    t.text     "serialized_message", :limit => 16777215
    t.string   "message_type"
    t.integer  "user_id"
    t.boolean  "processed",                              :default => false
    t.boolean  "success",                                :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", :force => true do |t|
    t.string   "title",            :limit => 50, :default => ""
    t.string   "comment",                        :default => ""
    t.datetime "created_at",                                     :null => false
    t.integer  "commentable_id",                 :default => 0,  :null => false
    t.string   "commentable_type", :limit => 15, :default => "", :null => false
    t.integer  "user_id",                        :default => 0,  :null => false
  end

  add_index "comments", ["user_id"], :name => "fk_comments_user"

  create_table "datasets", :force => true do |t|
    t.string   "name",              :limit => 60
    t.text     "description"
    t.text     "source"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "format"
    t.text     "result"
    t.float    "sort1"
    t.float    "sort2"
    t.float    "sort3"
    t.float    "sort4"
    t.float    "sort5"
    t.float    "sort0"
    t.float    "disk_size"
    t.boolean  "restricted_access"
    t.boolean  "proper"
    t.string   "process_status"
    t.string   "url"
    t.string   "author"
    t.float    "avg_stddev"
  end

  add_index "datasets", ["user_id"], :name => "index_datasets_on_user_id"

  create_table "programs", :force => true do |t|
    t.string   "name",                  :limit => 60
    t.text     "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "task_type"
    t.string   "constructor_signature"
    t.float    "sort1"
    t.float    "sort2"
    t.float    "sort3"
    t.float    "sort4"
    t.float    "sort5"
    t.float    "sort0"
    t.float    "disk_size"
    t.boolean  "restricted_access"
    t.boolean  "proper"
    t.boolean  "is_helper"
    t.string   "process_status"
    t.string   "url"
    t.string   "language"
    t.boolean  "tuneable"
    t.float    "avg_percentile"
  end

  add_index "programs", ["user_id"], :name => "index_programs_on_user_id"

  create_table "run_datasets", :force => true do |t|
    t.integer  "run_id"
    t.integer  "dataset_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "run_datasets", ["run_id", "dataset_id"], :name => "index_run_datasets_on_run_id_and_dataset_id"

  create_table "run_programs", :force => true do |t|
    t.integer  "run_id"
    t.integer  "program_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "run_programs", ["run_id", "program_id"], :name => "index_run_programs_on_run_id_and_program_id"

  create_table "run_statuses", :force => true do |t|
    t.integer  "run_id",           :null => false
    t.integer  "real_time"
    t.integer  "user_time"
    t.string   "status"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "max_memory_usage"
    t.float    "memory_usage"
    t.float    "max_disk_usage"
    t.float    "disk_usage"
  end

  create_table "runs", :force => true do |t|
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "specification"
    t.text     "result"
    t.integer  "allowed_time"
    t.text     "info_spec"
    t.integer  "processed_dataset_id"
    t.float    "sort1"
    t.float    "sort2"
    t.float    "sort3"
    t.float    "sort4"
    t.float    "sort5"
    t.float    "sort0"
    t.integer  "worker_id"
    t.float    "allowed_memory"
    t.float    "allowed_disk"
    t.integer  "core_program_id"
    t.integer  "core_dataset_id"
    t.float    "error"
    t.integer  "processed_program_id"
  end

  add_index "runs", ["core_dataset_id", "error"], :name => "index_runs_on_core_dataset_id_and_error"
  add_index "runs", ["core_program_id", "error"], :name => "index_runs_on_core_program_id_and_error"
  add_index "runs", ["user_id"], :name => "index_runs_on_user_id"
  add_index "runs", ["processed_dataset_id"], :name => "index_runs_on_processed_dataset_id"
  add_index "runs", ["processed_program_id"], :name => "index_runs_on_processed_program_id"

  create_table "users", :force => true do |t|
    t.string   "username",       :limit => 30,                   :null => false
    t.string   "password_hash",                                  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "fullname"
    t.string   "email"
    t.string   "affiliation"
    t.boolean  "is_admin"
    t.string   "reset_code"
    t.boolean  "receive_emails",               :default => true
  end

  create_table "workers", :force => true do |t|
    t.string   "handle"
    t.string   "host",           :limit => 60
    t.integer  "num_cpus"
    t.integer  "cpu_speed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.integer  "current_run_id"
    t.string   "command"
    t.float    "max_memory"
    t.float    "max_disk"
    t.integer  "version"
    t.datetime "last_run_time"
  end

  create_view "dataset_vresults", "select `pre_dataset_vresults`.`dataset_id` AS `dataset_id`,`pre_dataset_vresults`.`num_runs` AS `num_runs`,`pre_dataset_vresults`.`last_run_id` AS `last_run_id`,`pre_dataset_vresults`.`min_error` AS `min_error`,`runs`.`id` AS `best_run_id`,`runs`.`core_program_id` AS `best_core_program_id` from (`pre_dataset_vresults` left join `runs` on((`runs`.`core_dataset_id` = `pre_dataset_vresults`.`dataset_id`))) where ((`runs`.`error` = `pre_dataset_vresults`.`min_error`) or isnull(`pre_dataset_vresults`.`min_error`)) group by `pre_dataset_vresults`.`dataset_id`", :force => true do |v|
    v.column :dataset_id
    v.column :num_runs
    v.column :last_run_id
    v.column :min_error
    v.column :best_run_id
    v.column :best_core_program_id
  end

  create_view "pre_dataset_vresults", "select `datasets`.`id` AS `dataset_id`,count(`runs`.`id`) AS `num_runs`,`runs`.`id` AS `last_run_id`,min(`runs`.`error`) AS `min_error` from (`datasets` left join `runs` on((`datasets`.`id` = `runs`.`core_dataset_id`))) group by `datasets`.`id` order by `runs`.`updated_at` desc", :force => true do |v|
    v.column :dataset_id
    v.column :num_runs
    v.column :last_run_id
    v.column :min_error
  end

  create_view "program_vresults", "select `programs`.`id` AS `program_id`,count(`runs`.`id`) AS `num_runs`,`runs`.`id` AS `last_run_id` from (`programs` left join `runs` on((`programs`.`id` = `runs`.`core_program_id`))) group by `programs`.`id` order by `runs`.`updated_at` desc", :force => true do |v|
    v.column :program_id
    v.column :num_runs
    v.column :last_run_id
  end

  create_view "user_vresults", "select `users`.`id` AS `user_id`,count(`runs`.`id`) AS `num_runs`,sum(`run_statuses`.`user_time`) AS `total_spent_time`,sum((`run_statuses`.`user_time` * (`run_statuses`.`updated_at` > (curtime() - ((5 * 60) * 60))))) AS `recent_spent_time` from (`users` join (`runs` join `run_statuses` on((`runs`.`id` = `run_statuses`.`run_id`))) on((`users`.`id` = `runs`.`user_id`))) group by `users`.`id`", :force => true do |v|
    v.column :user_id
    v.column :num_runs
    v.column :total_spent_time
    v.column :recent_spent_time
  end

end
