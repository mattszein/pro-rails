FactoryBot.define do
  factory :ticket do
    sequence(:title) { |n| "Ticket ##{n}" }
    description { "This is a test ticket description." }
    priority { 3 }
    status { :open }
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
