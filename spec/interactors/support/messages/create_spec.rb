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
    ticket.update!(ai_state: :handoff_requested) # open + off is not messageable for the requester
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
        expect { result = call_step(user) }.to have_enqueued_job(Support::AiProcessJob).with(ticket.id, :user_message, a_kind_of(Integer))
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

      it "refuses the message: nothing saved, no job, state unchanged" do
        result = nil
        expect { result = call_step(user) }.not_to have_enqueued_job(Support::AiProcessJob)
        expect(result).to be_failure
        expect(result.message).not_to be_persisted
        expect(ticket.conversation.messages.reload).to be_empty
        expect(ticket.reload).to be_ai_analyzing
      end
    end

    context "when the ticket moved to analyzing after the policy ran (stale instance)" do
      let(:state) { :awaiting_user }

      it "refuses the message because the lock reloads the fresh state" do
        message = message_by(user) # its ticket instance still says awaiting_user
        Support::Ticket.find(ticket.id).start_ai_analysis!

        result = nil
        expect { result = described_class.call(message: message) }.not_to have_enqueued_job(Support::AiProcessJob)
        expect(result).to be_failure
        expect(message).not_to be_persisted
        expect(ticket.reload).to be_ai_analyzing
      end
    end

    %i[finished closed].each do |status|
      context "on a #{status} ticket" do
        let(:state) { :awaiting_user }

        it "refuses the message" do
          ticket.update_columns(status: Support::Ticket.statuses.fetch(status))
          result = nil
          expect { result = call_step(user) }.not_to have_enqueued_job(Support::AiProcessJob)
          expect(result).to be_failure
          expect(result.message).not_to be_persisted
        end
      end
    end

    context "when the message cannot be saved" do
      let(:state) { :awaiting_user }

      it "does not flip the state or enqueue" do
        result = nil
        expect { result = call_step(user, content: "") }.not_to have_enqueued_job(Support::AiProcessJob)
        expect(result).to be_failure
        expect(ticket.reload).to be_ai_awaiting_user
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
    # An admin can only write on a ticket assigned to them (policy); assigning released the AI.
    let(:ticket) { create(:ticket, created: user, assigned: admin, status: :in_progress, ai_state: state) }

    %i[off stepped_back resolved].each do |inert|
      context "when #{inert}" do
        let(:state) { inert }

        it "changes nothing AI-related" do
          expect { call_step(admin) }.not_to have_enqueued_job(Support::AiProcessJob)
          expect(ticket.reload.ai_state).to eq(inert.to_s)
          expect(ticket.notes).to be_empty
        end
      end
    end
  end
end
