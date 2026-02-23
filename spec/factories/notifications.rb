FactoryBot.define do
  factory :noticed_event, class: "Noticed::Event" do
    type { "AnnouncementNotifier" }
    association :record, factory: [:announcement, :published]
    params { {message: "Test notification"} }
  end

  factory :noticed_notification, class: "Noticed::Notification" do
    type { "AnnouncementNotifier::Notification" }
    association :event, factory: :noticed_event
    association :recipient, factory: [:account, :verified]

    trait :read do
      read_at { Time.current }
    end
  end
end
