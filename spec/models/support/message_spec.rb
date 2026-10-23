require "rails_helper"

RSpec.describe Support::Message, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:content) }

    it "requires an account for human messages" do
      message = build(:message, account: nil)
      expect(message).not_to be_valid
      expect(message.errors[:account]).to be_present
    end

    it "forbids an account on ai messages" do
      message = build(:message, :ai, account: create(:account))
      expect(message).not_to be_valid
      expect(message.errors[:account]).to be_present
    end

    it "accepts an ai message without account" do
      expect(build(:message, :ai)).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:conversation).class_name("Support::Conversation") }
    it { is_expected.to belong_to(:account).required(false) }
  end

  describe "database check constraint" do
    let(:conversation) { create(:conversation) }

    def insert_row(sender:, account_id:)
      now = Time.current
      described_class.insert({conversation_id: conversation.id, content: "x", sender: sender, account_id: account_id, created_at: now, updated_at: now})
    end

    it "rejects a human message without account" do
      expect { insert_row(sender: 0, account_id: nil) }.to raise_error(ActiveRecord::StatementInvalid, /messages_sender_account_check/)
    end

    it "rejects an ai message with an account" do
      expect { insert_row(sender: 1, account_id: create(:account).id) }.to raise_error(ActiveRecord::StatementInvalid, /messages_sender_account_check/)
    end

    it "allows valid combinations" do
      expect { insert_row(sender: 1, account_id: nil) }.not_to raise_error
      expect { insert_row(sender: 0, account_id: create(:account).id) }.not_to raise_error
    end
  end

  describe ".chronological" do
    it "orders by creation time ascending" do
      conversation = create(:conversation)
      later = create(:message, conversation: conversation, created_at: 1.minute.ago)
      earlier = create(:message, :ai, conversation: conversation, created_at: 1.hour.ago)
      expect(conversation.messages.chronological).to eq([earlier, later])
    end
  end

  it "defaults metadata to an empty hash" do
    expect(create(:message).metadata).to eq({})
  end

  describe "rendering" do
    it "renders an ai message without an account" do
      message = create(:message, :ai)
      html = ApplicationController.render(partial: "support/conversations/message", locals: {message: message})
      expect(html).to include(message.content)
    end
  end
end
