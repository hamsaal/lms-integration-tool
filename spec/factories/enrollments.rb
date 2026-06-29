FactoryBot.define do
  factory :enrollment do
    course
    user { association(:user, organization: course.organization) }
    role { :student }
    status { :active }
  end
end
