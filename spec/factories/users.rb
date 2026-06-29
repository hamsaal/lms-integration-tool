FactoryBot.define do
  factory :user do
    organization
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user-#{n}@example.edu" }
    sequence(:external_ref) { |n| "user-#{n}" }
    role { :student }

    trait :teacher do
      role { :teacher }
    end

    trait :admin do
      role { :admin }
    end
  end
end
