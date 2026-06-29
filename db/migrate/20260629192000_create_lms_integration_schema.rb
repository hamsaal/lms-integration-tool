class CreateLmsIntegrationSchema < ActiveRecord::Migration[7.1]
  def change
    create_table :organizations do |t|
      t.string :name, null: false
      t.string :external_ref, null: false
      t.timestamps
    end
    add_index :organizations, :external_ref, unique: true

    create_table :users do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email, null: false
      t.integer :role, null: false, default: 0
      t.string :external_ref, null: false
      t.timestamps
    end
    add_index :users, %i[organization_id email], unique: true
    add_index :users, %i[organization_id external_ref], unique: true

    create_table :courses do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :title, null: false
      t.string :course_code, null: false
      t.string :external_ref, null: false
      t.integer :status, null: false, default: 0
      t.timestamps
    end
    add_index :courses, %i[organization_id course_code], unique: true
    add_index :courses, %i[organization_id external_ref], unique: true
    add_index :courses, %i[organization_id status]

    create_table :enrollments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :role, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.timestamps
    end
    add_index :enrollments, %i[user_id course_id], unique: true
    add_index :enrollments, %i[course_id role status]

    create_table :assignments do |t|
      t.references :course, null: false, foreign_key: true
      t.string :title, null: false
      t.string :external_ref
      t.datetime :due_at
      t.decimal :points_possible, precision: 8, scale: 2, null: false, default: 100
      t.integer :status, null: false, default: 0
      t.timestamps
    end
    add_index :assignments, %i[course_id due_at]
    add_index :assignments, %i[course_id status]
    add_index :assignments, %i[course_id external_ref], unique: true, where: "external_ref IS NOT NULL"

    create_table :submissions do |t|
      t.references :assignment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :submitted_at
      t.decimal :score, precision: 8, scale: 2
      t.integer :workflow_state, null: false, default: 0
      t.text :body
      t.timestamps
    end
    add_index :submissions, %i[assignment_id user_id], unique: true
    add_index :submissions, :workflow_state
    add_index :submissions, %i[user_id workflow_state]

    create_table :grades do |t|
      t.references :submission, null: false, foreign_key: true, index: false
      t.references :assignment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :score, precision: 8, scale: 2, null: false
      t.string :passback_status, null: false, default: "pending"
      t.datetime :synced_at
      t.timestamps
    end
    add_index :grades, :submission_id, unique: true
    add_index :grades, %i[assignment_id user_id], unique: true
    add_index :grades, %i[passback_status synced_at]

    create_table :tool_launches do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.jsonb :launch_context, null: false, default: {}
      t.string :nonce, null: false
      t.datetime :launched_at, null: false
      t.timestamps
    end
    add_index :tool_launches, %i[organization_id launched_at]
    add_index :tool_launches, :nonce, unique: true

    create_table :audit_logs do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :actor_user, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :target_type, null: false
      t.bigint :target_id
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    add_index :audit_logs, %i[organization_id created_at]
    add_index :audit_logs, %i[target_type target_id]

    create_table :integration_job_runs do |t|
      t.references :organization, null: false, foreign_key: true
      t.integer :job_type, null: false
      t.integer :status, null: false, default: 0
      t.datetime :started_at
      t.datetime :finished_at
      t.string :error_message
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :integration_job_runs, %i[organization_id job_type status]
    add_index :integration_job_runs, :created_at
  end
end
