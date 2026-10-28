require "rails_helper"

RSpec.describe "Support ticket AI user actions", type: :interactor do
  let(:user) { create(:account, :verified) }

  describe Support::Tickets::ResolveWithAi do
    it "finishes the ticket, marks AI resolved and writes a system note" do
      ticket = create(:ticket, :ai_awaiting_user, created: user)
      result = described_class.call(ticket: ticket, account: user)

      expect(result).to be_success
      expect(ticket.reload).to be_finished.and be_ai_resolved
      expect(ticket.notes.system.first).to have_attributes(body: "Resolved by the user with AI assistance.", account: nil)
    end

    %i[ai_analyzing ai_handoff_requested ai_stepped_back].each do |trait|
      it "fails for #{trait} and writes nothing" do
        ticket = create(:ticket, trait, created: user)
        result = described_class.call(ticket: ticket, account: user)
        expect(result).to be_failure
        expect(result.error).to eq(I18n.t("ticket.transitions.can_only_resolve_with_ai"))
        expect(ticket.reload).to be_open
        expect(ticket.notes).to be_empty
      end
    end
  end

  describe Support::Tickets::RequestHuman do
    %i[ai_awaiting_user ai_analyzing].each do |trait|
      it "hands off from #{trait} and writes a system note without calling the model" do
        expect(SupportAi::Responder).not_to receive(:new)
        ticket = create(:ticket, trait, created: user)
        result = described_class.call(ticket: ticket, account: user)

        expect(result).to be_success
        expect(ticket.reload).to be_ai_handoff_requested
        expect(ticket.notes.system.pluck(:body)).to eq(["User requested a human"])
      end
    end

    %i[ai_handoff_requested ai_stepped_back ai_resolved].each do |trait|
      it "fails when #{trait}" do
        ticket = create(:ticket, trait, created: user)
        result = nil
        expect { result = described_class.call(ticket: ticket, account: user) }.not_to have_enqueued_job(Support::AiProcessJob)
        expect(result).to be_failure
        expect(ticket.notes).to be_empty
      end
    end
  end
end
