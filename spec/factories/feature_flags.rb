FactoryBot.define do
  factory :feature_flag do
    sequence(:key) { |n| "test_flag_#{n}" }

    transient do
      # FeatureFlags::Flags ships with no registrations — every declared
      # flag is a team's own addition — so a factory-built key must
      # register itself to stay valid against FeatureFlag#key_registered.
      # rails_helper resets FeatureFlags::Registry after every example, so
      # this never leaks between specs. Pass `auto_register: false` for a
      # spec that means to build a flag whose key is NOT declared (an
      # undeclared or retired-from-code flag).
      auto_register { true }
    end

    after(:build) do |flag, evaluator|
      if evaluator.auto_register && !FeatureFlags::Registry.registered?(flag.key)
        FeatureFlags::Registry.register(flag.key)
      end
    end
  end
end
