FactoryBot.define do
  factory :submission do
    assignment
    user { association(:user, organization: assignment.course.organization) }
    submitted_at { Time.current }
    workflow_state { :submitted }
    body { "Short activity response." }
  end
end
