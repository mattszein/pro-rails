FactoryBot.define do
  factory :ticket, class: "Support::Ticket" do
    sequence(:title) { |n| "Ticket ##{n}" }
    description { "This is a test ticket description." }
    priority { 3 }
    status { :open }
    category { :account_access }
    association :created, factory: :account

    trait :assigned do
      association :assigned, factory: :account
    end

    trait :in_progress do
      status { :in_progress }
      association :assigned, factory: :account
    end

    trait :finished do
      status { :finished }
      association :assigned, factory: :account
    end

    trait :reopened do
      status { :reopened }
      association :assigned, factory: :account
    end

    trait :ai_analyzing do
      ai_state { :analyzing }
    end

    trait :ai_awaiting_user do
      ai_state { :awaiting_user }
    end

    trait :ai_handoff_requested do
      ai_state { :handoff_requested }
    end

    trait :ai_stepped_back do
      ai_state { :stepped_back }
    end

    trait :ai_resolved do
      status { :finished }
      ai_state { :resolved }
    end

    trait :closed do
      status { :closed }
      association :assigned, factory: :account
    end
  end
end
