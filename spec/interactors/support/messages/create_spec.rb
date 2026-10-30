require "rails_helper"

RSpec.describe Support::Messages::Create, type: :interactor do
  let(:user) { create(:account, :verified) }
  let(:admin) { create(:account, :verified, :with_role) }
  let(:state) { :off }
  let(:ticket) { create(:ticket, created: user, ai_state: state) }

  def message_by(account, content: "hello")
    ticket.conversation.messages.build(account: account, content: content)
  end

  def call_step(account, **opts)
    described_class.call(message: message_by(account, **opts))
  end

  it "saves a human message" do
    result = call_step(user)
    expect(result).to be_success
    expect(result.message).to be_persisted.and have_attributes(sender: "human", account: user)
  end

  it "fails with the validation error and does nothing else" do
    result = nil
    expect { result = call_step(user, content: "") }.not_to have_enqueued_job(Support::AiProcessJob)
    expect(result).to be_failure
    expect(result.message).not_to be_persisted
  end

  describe "requester writing" do
    context "awaiting the user" do
      let(:state) { :awaiting_user }

      it "resumes analysis and enqueues the job for the message" do
        result = nil
        expect { result = call_step(user) }.to have_enqueued_job(Support::AiProcessJob).with(ticket.id, "user_message", a_kind_of(Integer))
        expect(ticket.reload).to be_ai_analyzing
        expect(result.message).to be_persisted
      end

      it "keeps the message when the enqueue fails" do
        allow(Support::AiProcessJob).to receive(:perform_later).and_raise(ActiveJob::EnqueueError)
        result = call_step(user)
        expect(result).to be_success
        expect(result.message).to be_persisted
      end
    end

    context "already analyzing" do
      let(:state) { :analyzing }

      it "only enqueues; the state is unchanged" do
        expect { call_step(user) }.to have_enqueued_job(Support::AiProcessJob)
        expect(ticket.reload).to be_ai_analyzing
      end
    end

    %i[off handoff_requested stepped_back resolved].each do |inert|
      context "when #{inert}" do
        let(:state) { inert }

        it "has no AI side effects" do
          expect { call_step(user) }.not_to have_enqueued_job(Support::AiProcessJob)
          expect(ticket.reload.ai_state).to eq(inert.to_s)
          expect(ticket.notes).to be_empty
        end
      end
    end
  end

  describe "admin writing" do
    %i[analyzing awaiting_user handoff_requested].each do |engaged|
      context "when #{engaged}" do
        let(:state) { engaged }

        it "takes over from the AI with a system note" do
          expect { call_step(admin) }.not_to have_enqueued_job(Support::AiProcessJob)
          expect(ticket.reload).to be_ai_stepped_back
          expect(ticket.notes.system.first).to have_attributes(body: "AI stepped back.", account: nil)
        end
      end
    end

    %i[off stepped_back resolved].each do |inert|
      context "when #{inert}" do
        let(:state) { inert }

        it "changes nothing AI-related" do
          call_step(admin)
          expect(ticket.reload.ai_state).to eq(inert.to_s)
          expect(ticket.notes).to be_empty
        end
      end
    end
  end
end
