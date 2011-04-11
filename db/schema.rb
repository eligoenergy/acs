# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110309194306) do

  create_table "access_requests", :force => true do |t|
    t.integer  "user_id",                                   :null => false
    t.integer  "created_by_id",                             :null => false
    t.integer  "resource_id",                               :null => false
    t.integer  "current_worker_id"
    t.string   "request_action",                            :null => false
    t.string   "current_state",     :default => "pending",  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "manager_id"
    t.integer  "resource_owner_id"
    t.integer  "help_desk_id"
    t.datetime "completed_at"
    t.integer  "completed_by_id"
    t.boolean  "for_new_user",      :default => false
    t.boolean  "historical",        :default => false,      :null => false
    t.integer  "hr_id"
    t.string   "reason",            :default => "standard", :null => false
  end

  add_index "access_requests", ["created_by_id"], :name => "index_access_requests_on_created_by_id"
  add_index "access_requests", ["current_worker_id"], :name => "index_access_requests_on_current_worker_id"
  add_index "access_requests", ["reason", "request_action"], :name => "index_access_requests_on_reason_and_request_action"
  add_index "access_requests", ["request_action", "reason"], :name => "index_access_requests_on_request_action_and_reason"
  add_index "access_requests", ["user_id"], :name => "index_access_requests_on_user_id"

  create_table "change_logs", :force => true do |t|
    t.integer  "item_id",        :null => false
    t.string   "item_type",      :null => false
    t.string   "attribute_name"
    t.text     "old_value"
    t.text     "new_value"
    t.string   "changed_by"
    t.datetime "created_at"
    t.integer  "revision"
  end

  add_index "change_logs", ["item_type", "item_id"], :name => "index_change_logs_on_item_type_and_item_id"

# Could not dump table "companies" because of following StandardError
#   Unknown type 'name' for column 'name'

  create_table "departments", :force => true do |t|
    t.integer  "location_id", :null => false
    t.string   "name",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "departments", ["location_id", "name"], :name => "index_departments_on_location_id_and_name"
  add_index "departments", ["name"], :name => "index_departments_on_name"

  create_table "employment_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "employment_types", ["name"], :name => "index_employment_types_on_name"

  create_table "jobs", :force => true do |t|
    t.integer  "department_id",                :null => false
    t.string   "name",                         :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "lawson_cd"
    t.integer  "revision",      :default => 1, :null => false
  end

  add_index "jobs", ["department_id", "name"], :name => "index_jobs_on_department_id_and_name"
  add_index "jobs", ["name"], :name => "index_jobs_on_name"

  create_table "jobs_permissions", :id => false, :force => true do |t|
    t.integer "job_id",        :null => false
    t.integer "permission_id", :null => false
  end

  add_index "jobs_permissions", ["job_id", "permission_id"], :name => "index_jobs_permissions_on_job_id_and_permission_id"

  create_table "locations", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "locations", ["name"], :name => "index_locations_on_name"

  create_table "mailer_templates", :force => true do |t|
    t.text     "body"
    t.string   "path"
    t.string   "format"
    t.string   "locale"
    t.string   "handler"
    t.boolean  "partial",     :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
  end

  add_index "mailer_templates", ["path"], :name => "index_mailer_templates_on_path"

  create_table "notes", :force => true do |t|
    t.text     "body"
    t.integer  "notable_id"
    t.string   "notable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "user_id"
    t.string   "created_at_step"
  end

  add_index "notes", ["notable_type", "notable_id"], :name => "index_notes_on_notable_type_and_notable_id"

  create_table "permission_requests", :force => true do |t|
    t.integer  "access_request_id",             :null => false
    t.integer  "permission_id",                 :null => false
    t.boolean  "permission_granted"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "approved_by_manager_at"
    t.datetime "approved_by_resource_owner_at"
    t.boolean  "approved_by_manager"
    t.boolean  "approved_by_resource_owner"
    t.boolean  "approved_by_hr"
    t.datetime "approved_by_hr_at"
  end

  add_index "permission_requests", ["access_request_id"], :name => "index_permission_requests_on_access_request_id"

  create_table "permission_types", :force => true do |t|
    t.string   "name",              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "resource_group_id"
  end

  add_index "permission_types", ["name"], :name => "index_permission_types_on_name"
  add_index "permission_types", ["resource_group_id", "name"], :name => "index_permission_types_on_resource_group_id_and_name"
  add_index "permission_types", ["resource_group_id"], :name => "index_permission_types_on_resource_group_id"

  create_table "permissions", :force => true do |t|
    t.integer  "permission_type_id", :null => false
    t.integer  "resource_id",        :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "permissions", ["permission_type_id", "resource_id"], :name => "index_permissions_on_permission_type_id_and_resource_id"
  add_index "permissions", ["resource_id"], :name => "index_permissions_on_resource_id"

  create_table "permissions_users", :id => false, :force => true do |t|
    t.integer "permission_id", :null => false
    t.integer "user_id",       :null => false
  end

  add_index "permissions_users", ["permission_id", "user_id"], :name => "index_permissions_users_on_permission_id_and_user_id"
  add_index "permissions_users", ["user_id", "permission_id"], :name => "index_permissions_users_on_user_id_and_permission_id"

  create_table "preferences", :force => true do |t|
    t.string   "name",       :null => false
    t.integer  "owner_id",   :null => false
    t.string   "owner_type", :null => false
    t.integer  "group_id"
    t.string   "group_type"
    t.string   "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "resource_groups", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_groups", ["name"], :name => "index_resource_groups_on_name"

  create_table "resources", :force => true do |t|
    t.string   "name",              :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "resource_group_id"
  end

  add_index "resources", ["name"], :name => "index_resources_on_name"
  add_index "resources", ["resource_group_id", "name"], :name => "index_resources_on_resource_group_id_and_name"
  add_index "resources", ["resource_group_id"], :name => "index_resources_on_resource_group_id"

  create_table "resources_users", :id => false, :force => true do |t|
    t.integer "resource_id", :null => false
    t.integer "user_id",     :null => false
  end

  add_index "resources_users", ["resource_id", "user_id"], :name => "index_resources_users_on_resource_id_and_user_id"
  add_index "resources_users", ["user_id", "resource_id"], :name => "index_resources_users_on_user_id_and_resource_id"

  create_table "roles", :force => true do |t|
    t.string "name", :null => false
  end

  add_index "roles", ["name"], :name => "index_roles_on_name"

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id", :null => false
    t.integer "user_id", :null => false
  end

  add_index "roles_users", ["user_id", "role_id"], :name => "index_roles_users_on_user_id_and_role_id"

  create_table "user_sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "user_sessions", ["session_id"], :name => "index_user_sessions_on_session_id"
  add_index "user_sessions", ["updated_at"], :name => "index_user_sessions_on_updated_at"

  create_table "users", :force => true do |t|
    t.string   "first_name",         :limit => 40
    t.string   "last_name",          :limit => 40
    t.string   "login",              :limit => 40,  :default => ""
    t.string   "email",              :limit => 100,                        :null => false
    t.string   "perishable_token",   :limit => 64
    t.datetime "activated_at"
    t.string   "persistence_token"
    t.string   "current_state",                     :default => "passive", :null => false
    t.datetime "deleted_at"
    t.integer  "login_count",                       :default => 0,         :null => false
    t.integer  "failed_login_count",                :default => 0,         :null => false
    t.string   "current_login_ip"
    t.string   "last_login_ip"
    t.datetime "last_request_at"
    t.datetime "current_login_at"
    t.datetime "last_login_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "job_id"
    t.integer  "manager_id"
    t.boolean  "manager_flag",                      :default => false,     :null => false
    t.integer  "lft"
    t.integer  "rgt"
    t.integer  "coworker_number"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "employment_type_id"
    t.integer  "company_id"
    t.integer  "submitted_by_id"
    t.integer  "terminated_by_id"
    t.boolean  "nonhuman_flg",                      :default => false
    t.string   "nickname"
    t.string   "crypted_password"
    t.string   "password_salt"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["employment_type_id"], :name => "index_users_on_employment_type_id"
  add_index "users", ["lft", "rgt"], :name => "index_users_on_lft_and_rgt"
  add_index "users", ["login"], :name => "index_users_on_login"
  add_index "users", ["manager_id"], :name => "index_users_on_manager_id"
  add_index "users", ["nonhuman_flg"], :name => "index_users_on_nonhuman_flg"
  add_index "users", ["rgt", "lft"], :name => "index_users_on_rgt_and_lft"

end
