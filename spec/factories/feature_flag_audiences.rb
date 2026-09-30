FactoryBot.define do
  factory :feature_flag_audience do
    association :feature_flag
    association :audience
  end
end
