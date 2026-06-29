require "rails_helper"

RSpec.describe Submission, type: :model do
  it { is_expected.to belong_to(:assignment) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_one(:grade).dependent(:destroy) }

  it "requires the learner to be actively enrolled as a student" do
    organization = create(:organization)
    user = create(:user, organization:)
    course = create(:course, organization:)
    assignment = create(:assignment, course:)

    submission = build(:submission, user:, assignment:)

    expect(submission).not_to be_valid
    expect(submission.errors[:user]).to include("must be an active student in the course")
  end

  it "allows active student submissions" do
    organization = create(:organization)
    user = create(:user, organization:)
    course = create(:course, organization:)
    create(:enrollment, user:, course:)
    assignment = create(:assignment, course:)

    expect(build(:submission, user:, assignment:)).to be_valid
  end
end
