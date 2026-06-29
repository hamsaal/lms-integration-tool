class Course < ApplicationRecord
  belongs_to :organization
  has_many :enrollments, dependent: :destroy
  has_many :users, through: :enrollments
  has_many :assignments, dependent: :destroy

  enum :status, { active: 0, archived: 1 }

  validates :title, :course_code, :external_ref, presence: true
  validates :course_code, uniqueness: { scope: :organization_id }
  validates :external_ref, uniqueness: { scope: :organization_id }

  scope :active_courses, -> { active }
  scope :ordered, -> { order(:course_code) }
end
