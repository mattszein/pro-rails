require "rails_helper"

RSpec.describe Support::MessagePolicy, type: :policy do
  let(:requester) { create(:account, :verified) }
  let(:admin) { create(:account, :verified, :with_role) }
  let(:other_admin) { create(:account, :verified, :with_role) }
  let(:ticket) { create(:ticket, created: requester, status: :in_progress, assigned: admin) }
  let(:message) { Support::Message.new(conversation: ticket.conversation) }

  def allowed?(account) = described_class.new(message, user: account).apply(:create?)

  it "lets the assignee write" do
    expect(allowed?(admin)).to be(true)
  end

  it "lets the requester write while the ticket is messageable" do
    expect(allowed?(requester)).to be(true)
  end

  it "denies an admin on an unassigned ticket" do
    ticket.update_columns(assigned_id: nil, status: Support::Ticket.statuses[:open])
    expect(allowed?(admin)).to be(false)
  end

  it "denies an admin on a ticket assigned to someone else" do
    expect(allowed?(other_admin)).to be(false)
  end
end
