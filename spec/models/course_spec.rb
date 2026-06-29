require "rails_helper"

RSpec.describe Course, type: :model do
  it { is_expected.to belong_to(:organization) }
  it { is_expected.to have_many(:assignments).dependent(:destroy) }
  it { is_expected.to validate_presence_of(:title) }
  it { is_expected.to validate_presence_of(:course_code) }

  it "enforces unique course codes per organization" do
    organization = create(:organization)
    create(:course, organization:, course_code: "BIO-101")

    duplicate = build(:course, organization:, course_code: "BIO-101")

    expect(duplicate).not_to be_valid
  end
end
