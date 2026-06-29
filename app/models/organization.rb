class Organization < ApplicationRecord
  has_many :users, dependent: :destroy
  has_many :courses, dependent: :destroy
  has_many :tool_launches, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :integration_job_runs, dependent: :destroy

  validates :name, :external_ref, presence: true
  validates :external_ref, uniqueness: true
end
