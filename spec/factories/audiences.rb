FactoryBot.define do
  factory :audience do
    sequence(:name) { |n| "Audience #{n}" }
    description { "A test audience" }

    transient do
      with_condition { true }
    end

    after(:build) do |audience, evaluator|
      if evaluator.with_condition && audience.audience_conditions.empty?
        audience.audience_conditions << build(:audience_condition, audience: audience)
      end
    end

    trait :archived do
      archived_at { Time.current }
    end

    trait :without_condition do
      with_condition { false }
    end

    trait :attached_to do
      transient do
        feature_flag { nil }
      end

      after(:create) do |audience, evaluator|
        create(:feature_flag_audience, audience: audience, feature_flag: evaluator.feature_flag || create(:feature_flag))
      end
    end
  end
end
