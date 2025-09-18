FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role#{n}" }
    trait :superadmin do
      name { Role::SUPERADMIN }
    end
  end
end
