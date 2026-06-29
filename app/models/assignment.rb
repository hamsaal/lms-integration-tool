class Assignment < ApplicationRecord
  belongs_to :course
  has_many :submissions, dependent: :destroy
  has_many :grades, dependent: :destroy

  enum :status, { draft: 0, published: 1, closed: 2 }

  validates :title, :points_possible, presence: true
  validates :points_possible, numericality: { greater_than: 0 }
  validates :external_ref, uniqueness: { scope: :course_id }, allow_blank: true

  scope :published_assignments, -> { published }
  scope :due_soon, -> { order(Arel.sql("due_at ASC NULLS LAST"), :id) }
end
