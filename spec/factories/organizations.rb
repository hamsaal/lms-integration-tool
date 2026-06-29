FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "School #{n}" }
    sequence(:external_ref) { |n| "org-#{n}" }
  end
end
