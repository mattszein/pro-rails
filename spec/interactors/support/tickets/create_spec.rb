require "rails_helper"

RSpec.describe Support::Tickets::Create, type: :interactor do
  let(:account) { create(:account, :verified) }
  let(:ticket) { build(:ticket, created: account) }

  def with_ai_enabled(value)
    allow(SupportAiConfig).to receive(:enabled).and_return(value)
  end

  context "when the assistant is globally disabled" do
    before { with_ai_enabled(false) }

    it "saves an AI-off ticket and enqueues nothing" do
      create(:ai_playbook)
      expect { described_class.call(ticket: ticket) }.not_to have_enqueued_job(Support::AiProcessJob)
      expect(ticket.reload).to be_ai_off
    end
  end

  context "when enabled but no playbook is enabled" do
    before { with_ai_enabled(true) }

    it "leaves the AI off" do
      create(:ai_playbook, :disabled)
      expect { described_class.call(ticket: ticket) }.not_to have_enqueued_job(Support::AiProcessJob)
      expect(ticket.reload).to be_ai_off
    end
  end

  context "when enabled with an enabled playbook" do
    before do
      with_ai_enabled(true)
      create(:ai_playbook)
    end

    it "is born analyzing and enqueues the job with the saved id" do
      result = nil
      expect { result = described_class.call(ticket: ticket) }
        .to have_enqueued_job(Support::AiProcessJob).with { |id, trigger, _| expect([id, trigger]).to eq([ticket.id, :ticket_created]) }
      expect(result).to be_success
      expect(ticket.reload).to be_ai_analyzing
      expect(ticket.ai_state_changed_at).to be_present
    end

    it "keeps the ticket when enqueueing fails" do
      allow(Support::AiProcessJob).to receive(:perform_later).and_raise(ActiveJob::EnqueueError, "queue down")
      result = nil
      expect { result = described_class.call(ticket: ticket) }.to change(Support::Ticket, :count).by(1)
      expect(result).to be_success
      expect(ticket.reload).to be_ai_analyzing
    end

    it "does not swallow unrelated errors" do
      allow(Support::AiProcessJob).to receive(:perform_later).and_raise(NoMethodError)
      expect { described_class.call(ticket: ticket) }.to raise_error(NoMethodError)
    end

    it "enqueues only after the ticket is committed" do
      seen = nil
      allow(Support::AiProcessJob).to receive(:perform_later) { |id, *| seen = Support::Ticket.find_by(id: id) }
      described_class.call(ticket: ticket)
      expect(seen).to be_present
    end
  end

  it "fails with the validation error and enqueues nothing" do
    with_ai_enabled(true)
    create(:ai_playbook)
    invalid = build(:ticket, created: account, title: nil)
    result = nil
    expect { result = described_class.call(ticket: invalid) }.not_to have_enqueued_job
    expect(result).to be_failure
    expect(result.error).to be_present
    expect(invalid.errors[:title]).to be_present
  end
end
