FactoryBot.define do
  factory :feature_flag_account do
    association :feature_flag
    association :account
    access { :allowed }

    trait :allowed do
      access { :allowed }
    end

    trait :blocked do
      access { :blocked }
    end
  end
end
