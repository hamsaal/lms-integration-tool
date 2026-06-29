require "rails_helper"

RSpec.describe Enrollment, type: :model do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:course) }

  it "requires user and course to belong to the same organization" do
    enrollment = build(:enrollment, user: create(:user), course: create(:course))

    expect(enrollment).not_to be_valid
    expect(enrollment.errors[:user]).to include("must belong to the same organization as the course")
  end

  it "prevents duplicate course enrollments" do
    organization = create(:organization)
    user = create(:user, organization:)
    course = create(:course, organization:)
    create(:enrollment, user:, course:)

    duplicate = build(:enrollment, user:, course:)

    expect(duplicate).not_to be_valid
  end
end
