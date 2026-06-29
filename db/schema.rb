# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2026_06_29_192000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "assignments", force: :cascade do |t|
    t.bigint "course_id", null: false
    t.string "title", null: false
    t.string "external_ref"
    t.datetime "due_at"
    t.decimal "points_possible", precision: 8, scale: 2, default: "100.0", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "due_at"], name: "index_assignments_on_course_id_and_due_at"
    t.index ["course_id", "external_ref"], name: "index_assignments_on_course_id_and_external_ref", unique: true, where: "(external_ref IS NOT NULL)"
    t.index ["course_id", "status"], name: "index_assignments_on_course_id_and_status"
    t.index ["course_id"], name: "index_assignments_on_course_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "actor_user_id"
    t.string "action", null: false
    t.string "target_type", null: false
    t.bigint "target_id"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["actor_user_id"], name: "index_audit_logs_on_actor_user_id"
    t.index ["organization_id", "created_at"], name: "index_audit_logs_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_audit_logs_on_organization_id"
    t.index ["target_type", "target_id"], name: "index_audit_logs_on_target_type_and_target_id"
  end

  create_table "courses", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "title", null: false
    t.string "course_code", null: false
    t.string "external_ref", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "course_code"], name: "index_courses_on_organization_id_and_course_code", unique: true
    t.index ["organization_id", "external_ref"], name: "index_courses_on_organization_id_and_external_ref", unique: true
    t.index ["organization_id", "status"], name: "index_courses_on_organization_id_and_status"
    t.index ["organization_id"], name: "index_courses_on_organization_id"
  end

  create_table "enrollments", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.integer "role", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id", "role", "status"], name: "index_enrollments_on_course_id_and_role_and_status"
    t.index ["course_id"], name: "index_enrollments_on_course_id"
    t.index ["user_id", "course_id"], name: "index_enrollments_on_user_id_and_course_id", unique: true
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "grades", force: :cascade do |t|
    t.bigint "submission_id", null: false
    t.bigint "assignment_id", null: false
    t.bigint "user_id", null: false
    t.decimal "score", precision: 8, scale: 2, null: false
    t.string "passback_status", default: "pending", null: false
    t.datetime "synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id", "user_id"], name: "index_grades_on_assignment_id_and_user_id", unique: true
    t.index ["assignment_id"], name: "index_grades_on_assignment_id"
    t.index ["passback_status", "synced_at"], name: "index_grades_on_passback_status_and_synced_at"
    t.index ["submission_id"], name: "index_grades_on_submission_id", unique: true
    t.index ["user_id"], name: "index_grades_on_user_id"
  end

  create_table "integration_job_runs", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.integer "job_type", null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.string "error_message"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_integration_job_runs_on_created_at"
    t.index ["organization_id", "job_type", "status"], name: "idx_on_organization_id_job_type_status_1c5270305a"
    t.index ["organization_id"], name: "index_integration_job_runs_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "external_ref", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_ref"], name: "index_organizations_on_external_ref", unique: true
  end

  create_table "submissions", force: :cascade do |t|
    t.bigint "assignment_id", null: false
    t.bigint "user_id", null: false
    t.datetime "submitted_at"
    t.decimal "score", precision: 8, scale: 2
    t.integer "workflow_state", default: 0, null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id", "user_id"], name: "index_submissions_on_assignment_id_and_user_id", unique: true
    t.index ["assignment_id"], name: "index_submissions_on_assignment_id"
    t.index ["user_id", "workflow_state"], name: "index_submissions_on_user_id_and_workflow_state"
    t.index ["user_id"], name: "index_submissions_on_user_id"
    t.index ["workflow_state"], name: "index_submissions_on_workflow_state"
  end

  create_table "tool_launches", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id", null: false
    t.bigint "course_id", null: false
    t.jsonb "launch_context", default: {}, null: false
    t.string "nonce", null: false
    t.datetime "launched_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["course_id"], name: "index_tool_launches_on_course_id"
    t.index ["nonce"], name: "index_tool_launches_on_nonce", unique: true
    t.index ["organization_id", "launched_at"], name: "index_tool_launches_on_organization_id_and_launched_at"
    t.index ["organization_id"], name: "index_tool_launches_on_organization_id"
    t.index ["user_id"], name: "index_tool_launches_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.string "email", null: false
    t.integer "role", default: 0, null: false
    t.string "external_ref", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "email"], name: "index_users_on_organization_id_and_email", unique: true
    t.index ["organization_id", "external_ref"], name: "index_users_on_organization_id_and_external_ref", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "assignments", "courses"
  add_foreign_key "audit_logs", "organizations"
  add_foreign_key "audit_logs", "users", column: "actor_user_id"
  add_foreign_key "courses", "organizations"
  add_foreign_key "enrollments", "courses"
  add_foreign_key "enrollments", "users"
  add_foreign_key "grades", "assignments"
  add_foreign_key "grades", "submissions"
  add_foreign_key "grades", "users"
  add_foreign_key "integration_job_runs", "organizations"
  add_foreign_key "submissions", "assignments"
  add_foreign_key "submissions", "users"
  add_foreign_key "tool_launches", "courses"
  add_foreign_key "tool_launches", "organizations"
  add_foreign_key "tool_launches", "users"
  add_foreign_key "users", "organizations"
end
