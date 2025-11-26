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

    trait :closed do
      status { :closed }
      association :assigned, factory: :account
    end
  end
end
