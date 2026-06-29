FactoryBot.define do
  factory :assignment do
    course
    sequence(:title) { |n| "Assignment #{n}" }
    sequence(:external_ref) { |n| "assignment-#{n}" }
    points_possible { 10 }
    status { :published }
  end
end
