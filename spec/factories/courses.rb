FactoryBot.define do
  factory :course do
    organization
    sequence(:title) { |n| "Course #{n}" }
    sequence(:course_code) { |n| "COURSE-#{n}" }
    sequence(:external_ref) { |n| "course-#{n}" }
    status { :active }
  end
end
