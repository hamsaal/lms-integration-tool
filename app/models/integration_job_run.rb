class IntegrationJobRun < ApplicationRecord
  belongs_to :organization

  enum :job_type, { roster_import: 0, grade_sync: 1 }
  enum :status, { queued: 0, running: 1, completed: 2, failed: 3 }

  validates :job_type, :status, presence: true
end
