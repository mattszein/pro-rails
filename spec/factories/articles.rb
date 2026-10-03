FactoryBot.define do
  factory :article, class: "Support::Article" do
    sequence(:title) { |n| "Article ##{n}" }
    sequence(:slug) { |n| "article-#{n}" }
    summary { "A short summary of the article." }
    body { "<p>This is the article body.</p>" }
    category { :account_access }
    locale { "en" }
    status { :draft }
    association :author, factory: :account

    trait :published do
      status { :published }
      published_at { Time.current }
    end

    trait :spanish do
      locale { "es" }
    end

    trait :general do
      category { nil }
    end
  end
end
