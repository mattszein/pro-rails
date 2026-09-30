FactoryBot.define do
  factory :feature_flag do
    sequence(:key) { |n| "test_flag_#{n}" }

    transient do
      # A factory-built key must register itself to stay valid against
      # FeatureFlag#key_registered. Pass `auto_register: false` to build a
      # flag whose key is NOT declared (an undeclared/retired flag).
      auto_register { true }
    end

    after(:build) do |flag, evaluator|
      if evaluator.auto_register && !FeatureFlags::Registry.registered?(flag.key)
        FeatureFlags::Registry.register(flag.key)
      end
    end
  end
end
