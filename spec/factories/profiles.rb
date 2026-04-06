FactoryBot.define do
  factory :profile do
    association :account
    sequence(:username) { |n| "user_#{n}" }
    bio { "A short bio." }

    initialize_with { account.profile || new }

    trait :with_avatar do
      avatar { Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/files/avatar.png"), "image/png") }
    end
  end
end
