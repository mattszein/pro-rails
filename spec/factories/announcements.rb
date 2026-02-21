FactoryBot.define do
  factory :announcement do
    sequence(:title) { |n| "Announcement ##{n}" }
    body { "This is an important announcement about our platform updates." }
    status { :draft }
    association :author, factory: :account

    trait :draft do
      status { :draft }
    end

    trait :scheduled do
      status { :scheduled }
      scheduled_at { 1.day.from_now }
    end

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :ready_to_publish do
      status { :scheduled }
      scheduled_at { 1.hour.ago }
    end
  end
end
