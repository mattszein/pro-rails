FactoryBot.define do
  factory :message, class: "Support::Message" do
    association :conversation, factory: :conversation
    association :account
    content { "This is a test message." }
  end

  factory :conversation, class: "Support::Conversation" do
    association :ticket
  end
end
