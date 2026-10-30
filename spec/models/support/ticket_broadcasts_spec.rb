require "rails_helper"

RSpec.describe Support::Ticket, "user page broadcasts" do
  include ActiveJob::TestHelper

  let(:stream) { ActionView::RecordIdentifier.dom_id(ticket) }

  # Every turbo-stream payload broadcast to the user's ticket stream while the block runs.
  def payloads_for
    payloads = []
    perform_enqueued_jobs do
      expect { yield }.to have_broadcasted_to(stream).at_least(:once).with { |data| payloads << data }
    end
    payloads
  end

  def composer?(payloads)
    payloads.any? { |d| d.include?("message_form") && d.include?("support_message[content]") }
  end

  context "when the ticket becomes messageable" do
    let(:ticket) { create(:ticket, status: :finished, assigned: create(:account, :verified)) }

    it "broadcasts the real composer instead of a refresh-the-page banner" do
      payloads = payloads_for { ticket.reopen!(by: create(:account)) }

      expect(composer?(payloads)).to be(true)
    end
  end

  context "when the assistant's reply flips ai_state but the ticket stays messageable" do
    let(:ticket) { create(:ticket, :ai_analyzing) }

    it "does not re-broadcast the composer (it would wipe the user's draft) but updates the status banner" do
      payloads = payloads_for { ticket.await_user_reply! }

      expect(composer?(payloads)).to be(false)
      expect(payloads.any? { |d| d.include?("ai_status") && d.include?(I18n.t("support.ticket_status_banner.ai_awaiting_user")) }).to be(true)
    end
  end

  context "when a human takes over from the assistant" do
    let(:ticket) { create(:ticket, :ai_awaiting_user) }

    it "keeps the composer untouched" do
      payloads = payloads_for { ticket.take!(by: create(:account, :verified)) }

      expect(composer?(payloads)).to be(false)
    end
  end

  context "when the composer must turn into a banner" do
    let(:ticket) { create(:ticket, :in_progress) }

    it "broadcasts the status banner" do
      payloads = payloads_for { ticket.finish!(by: create(:account)) }

      expect(payloads.any? { |d| d.include?("message_form") && d.include?(I18n.t("support.ticket_status_banner.finished")) }).to be(true)
      expect(composer?(payloads)).to be(false)
    end
  end
end
