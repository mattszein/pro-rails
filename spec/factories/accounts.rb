# spec/factories/accounts.rb
FactoryBot.define do
  factory :account do
    sequence(:email) { |n| "user#{n}@#{TestConstants::TEST_EMAIL_DOMAIN}" }
    password { TestConstants::TEST_PASSWORD }
    status { "unverified" }

    # Trait for verified accounts
    trait :verified do
      status { "verified" }
    end

    # Trait for closed accounts
    trait :closed do
      status { "closed" }
    end

    trait :with_role do
      association :role
    end

    trait :superadmin do
      association :role, factory: [:role, :superadmin]
    end
  end
end
