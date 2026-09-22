FactoryBot.define do
  factory :audience_condition do
    association :audience
    condition_key { "adminit_users" }
    value { true }

    trait :adminit_users do
      condition_key { "adminit_users" }
      value { true }
    end

    trait :roles do
      condition_key { "roles" }
      value { [0] } # override with real role ids: value: [role.id]
    end

    trait :verified_users do
      condition_key { "verified_users" }
      value { true }
    end

    trait :registration_age do
      condition_key { "registration_age" }
      value { {"amount" => 1, "unit" => "years"} }
    end
  end
end
