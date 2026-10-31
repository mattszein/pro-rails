require "rails_helper"

RSpec.describe "Support ticket AI user actions", type: :interactor do
  let(:user) { create(:account, :verified) }

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
