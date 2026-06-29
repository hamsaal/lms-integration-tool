class Enrollment < ApplicationRecord
  belongs_to :user
  belongs_to :course

  enum :role, { student: 0, teacher: 1 }
  enum :status, { active: 0, dropped: 1 }

  validates :role, :status, presence: true
  validates :user_id, uniqueness: { scope: :course_id }
  validate :same_organization

  scope :active_enrollments, -> { active }

  private

  def same_organization
    return if user.blank? || course.blank?
    return if user.organization_id == course.organization_id

    errors.add(:user, "must belong to the same organization as the course")
  end
end
