class User < ApplicationRecord
  belongs_to :organization
  has_many :enrollments, dependent: :destroy
  has_many :courses, through: :enrollments
  has_many :submissions, dependent: :destroy
  has_many :grades, dependent: :destroy

  enum :role, { student: 0, teacher: 1, admin: 2 }

  validates :name, :email, :external_ref, presence: true
  validates :email, uniqueness: { scope: :organization_id }
  validates :external_ref, uniqueness: { scope: :organization_id }

  scope :for_organization, ->(organization_id) { where(organization_id:) }
end
