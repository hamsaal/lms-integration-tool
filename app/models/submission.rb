class Submission < ApplicationRecord
  belongs_to :assignment
  belongs_to :user
  has_one :grade, dependent: :destroy

  enum :workflow_state, { submitted: 0, graded: 1, missing: 2, excused: 3 }

  validates :assignment_id, uniqueness: { scope: :user_id }
  validate :user_is_active_student

  scope :missing_submissions, -> { missing }
  scope :graded_submissions, -> { graded }

  private

  def user_is_active_student
    return if assignment.blank? || user.blank?

    enrolled = Enrollment.active.student.exists?(user_id: user.id, course_id: assignment.course_id)
    errors.add(:user, "must be an active student in the course") unless enrolled
  end
end
