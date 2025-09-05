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

    # Trait with specific email
    trait :with_email do
      transient do
        email_address { "specific@example.com" }
      end
      
      email { email_address }
    end

    trait :role do
      association :role, factory: :role
    end
    trait :superadmin do
      association :role, factory: :role, id: 1
    end
  end
end
