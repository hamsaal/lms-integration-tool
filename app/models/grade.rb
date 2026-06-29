class Grade < ApplicationRecord
  belongs_to :submission
  belongs_to :assignment
  belongs_to :user

  STATUSES = %w[pending synced failed].freeze

  validates :score, numericality: { greater_than_or_equal_to: 0 }
  validates :passback_status, inclusion: { in: STATUSES }
  validates :submission_id, uniqueness: true
  validates :assignment_id, uniqueness: { scope: :user_id }

  scope :pending, -> { where(passback_status: "pending") }
  scope :synced, -> { where(passback_status: "synced") }
  scope :failed, -> { where(passback_status: "failed") }
end
