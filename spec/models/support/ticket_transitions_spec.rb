require "rails_helper"

RSpec.describe Support::Ticket, "workflow transitions", type: :model do
  let(:admin) { create(:account, :verified, :with_role) }
  let(:other_admin) { create(:account, :verified, :with_role) }
  let(:user) { create(:account, :verified) }

  def last_note(ticket) = ticket.notes.reorder(:id).last

  # Moves the ticket through another instance, then expects the stale one to refuse.
  def expect_stale_refusal(ticket, change)
    stale = described_class.find(ticket.id)
    described_class.find(ticket.id).update_columns(change)
    expect { yield stale }.to raise_error(Support::Ticket::InvalidTransition)
    expect(ticket.notes.reload).to be_empty
  end

  describe "#finish!" do
    it "finishes in_progress and reopened tickets and notes it" do
      %i[in_progress reopened].each do |trait|
        ticket = create(:ticket, trait)
        ticket.finish!(by: admin)
        expect(ticket.reload).to be_finished
        expect(last_note(ticket)).to have_attributes(kind: "system", body: "Ticket finished.", account: admin)
      end
    end

    it "rejects other statuses" do
      expect { create(:ticket).finish!(by: admin) }.to raise_error(Support::Ticket::InvalidTransition, I18n.t("ticket.transitions.can_only_finish"))
    end

    it "re-checks status after the lock (stale instance)" do
      ticket = create(:ticket, :in_progress)
      expect_stale_refusal(ticket, status: described_class.statuses[:finished]) { |t| t.finish!(by: admin) }
    end
  end

  describe "#reopen!" do
    it "reopens a finished ticket and notes it" do
      ticket = create(:ticket, :finished)
      ticket.reopen!(by: admin)
      expect(ticket.reload).to be_reopened
      expect(last_note(ticket)).to have_attributes(body: "Ticket reopened.", account: admin)
    end

    it "rejects non-finished tickets" do
      expect { create(:ticket).reopen!(by: admin) }.to raise_error(Support::Ticket::InvalidTransition)
    end

    it "re-checks status after the lock (stale instance)" do
      ticket = create(:ticket, :finished)
      expect_stale_refusal(ticket, status: described_class.statuses[:reopened]) { |t| t.reopen!(by: admin) }
    end
  end

  describe "#request_reopen!" do
    it "moves finished to reopen_requested with the reason in the note" do
      ticket = create(:ticket, :finished, created: user)
      ticket.request_reopen!(by: user, reason: "Still broken")
      expect(ticket.reload).to be_reopen_requested
      expect(last_note(ticket)).to have_attributes(body: "Reopen requested. Reason: Still broken", account: user)
    end

    it "omits the reason when blank" do
      ticket = create(:ticket, :finished)
      ticket.request_reopen!(by: user, reason: "")
      expect(last_note(ticket).body).to eq("Reopen requested.")
    end

    it "rejects non-finished tickets" do
      expect { create(:ticket).request_reopen!(by: user) }.to raise_error(Support::Ticket::InvalidTransition)
    end

    it "re-checks status after the lock (stale instance)" do
      ticket = create(:ticket, :finished)
      expect_stale_refusal(ticket, status: described_class.statuses[:reopened]) { |t| t.request_reopen!(by: user) }
    end
  end

  describe "#accept_reopen!" do
    it "reopens a reopen_requested ticket and notes it" do
      ticket = create(:ticket, status: :reopen_requested)
      ticket.accept_reopen!(by: admin)
      expect(ticket.reload).to be_reopened
      expect(last_note(ticket)).to have_attributes(body: "Reopen request accepted.", account: admin)
    end

    it "rejects other statuses" do
      expect { create(:ticket, :finished).accept_reopen!(by: admin) }.to raise_error(Support::Ticket::InvalidTransition)
    end

    it "re-checks status after the lock (stale instance)" do
      ticket = create(:ticket, status: :reopen_requested)
      expect_stale_refusal(ticket, status: described_class.statuses[:closed]) { |t| t.accept_reopen!(by: admin) }
    end
  end

  describe "#reject_reopen!" do
    it "closes a reopen_requested ticket and notes the reason" do
      ticket = create(:ticket, status: :reopen_requested)
      ticket.reject_reopen!(by: admin, reason: "Not valid")
      expect(ticket.reload).to be_closed
      expect(last_note(ticket)).to have_attributes(body: "Reopen request rejected. Ticket closed. Reason: Not valid", account: admin)
    end

    it "works without a reason" do
      ticket = create(:ticket, status: :reopen_requested)
      ticket.reject_reopen!(by: admin)
      expect(last_note(ticket).body).to eq("Reopen request rejected. Ticket closed.")
    end

    it "rejects other statuses" do
      expect { create(:ticket).reject_reopen!(by: admin) }.to raise_error(Support::Ticket::InvalidTransition)
    end

    it "re-checks status after the lock (stale instance)" do
      ticket = create(:ticket, status: :reopen_requested)
      expect_stale_refusal(ticket, status: described_class.statuses[:reopened]) { |t| t.reject_reopen!(by: admin) }
    end
  end

  describe "full reopen workflow" do
    it "walks take, finish, request, accept" do
      ticket = create(:ticket, created: user)
      ticket.take!(by: admin)
      ticket.finish!(by: admin)
      ticket.request_reopen!(by: user, reason: "It is still broken")
      ticket.accept_reopen!(by: admin)
      expect(ticket.reload).to be_reopened
      expect(ticket.assigned).to eq(admin)
      expect(ticket.notes.reorder(:id).pluck(:body)).to eq([
        "Ticket taken by #{admin.email}.",
        "Ticket finished.",
        "Reopen requested. Reason: It is still broken",
        "Reopen request accepted."
      ])
    end
  end

  describe "#assign! / #take!" do
    it "take! assigns an open ticket, moves it to in_progress and notes it" do
      ticket = create(:ticket)
      ticket.take!(by: admin)
      expect(ticket.reload).to be_in_progress
      expect(ticket.assigned).to eq(admin)
      expect(ticket.notes.pluck(:body)).to eq(["Ticket taken by #{admin.email}."])
      expect(last_note(ticket)).to have_attributes(account: admin, kind: "system")
    end

    it "assign! to another account notes who assigned it" do
      ticket = create(:ticket)
      ticket.assign!(to: other_admin, by: admin)
      expect(ticket.reload.assigned).to eq(other_admin)
      expect(last_note(ticket)).to have_attributes(body: "Assigned to #{other_admin.email} by #{admin.email}.", account: admin)
    end

    %i[reopen_requested reopened].each do |status|
      it "keeps the #{status} status when taken" do
        ticket = create(:ticket, status: status)
        ticket.take!(by: admin)
        expect(ticket.reload.status).to eq(status.to_s)
        expect(ticket.assigned).to eq(admin)
      end
    end

    %i[finished closed].each do |status|
      it "does not allow taking a #{status} ticket" do
        ticket = create(:ticket, status: status)
        expect { ticket.take!(by: admin) }.to raise_error(Support::Ticket::InvalidTransition, I18n.t("ticket.transitions.can_only_take"))
        expect(ticket.reload.assigned).to be_nil
      end
    end

    it "in_progress tickets that are unassigned are not takeable" do
      ticket = create(:ticket, status: :in_progress)
      expect { ticket.take!(by: admin) }.to raise_error(Support::Ticket::InvalidTransition)
    end

    it "raises AlreadyAssigned (an InvalidTransition) when assigned" do
      ticket = create(:ticket, :in_progress)
      expect { ticket.take!(by: admin) }.to raise_error(Support::Ticket::AlreadyAssigned, I18n.t("ticket.transitions.already_assigned"))
      expect(Support::Ticket::AlreadyAssigned).to be < Support::Ticket::InvalidTransition
    end

    it "refuses a stale instance when another admin took it first" do
      ticket = create(:ticket)
      stale = described_class.find(ticket.id)
      described_class.find(ticket.id).take!(by: other_admin)

      expect { stale.take!(by: admin) }.to raise_error(Support::Ticket::AlreadyAssigned)
      expect(ticket.reload.assigned).to eq(other_admin)
      expect(ticket.notes.count).to eq(1)
    end

    context "when the AI is engaged" do
      %i[ai_awaiting_user ai_handoff_requested ai_analyzing].each do |trait|
        it "steps the AI back with two notes in one update (#{trait})" do
          ticket = create(:ticket, trait)
          ticket.take!(by: admin)
          ticket.reload
          expect(ticket).to be_ai_stepped_back
          expect(ticket.ai_state_changed_at).to be_present
          expect(ticket.notes.pluck(:body)).to contain_exactly("Ticket taken by #{admin.email}.", "AI stepped back.")
          expect(ticket.notes.find_by(body: "AI stepped back.").account).to be_nil
        end
      end

      it "changes status, owner and AI state in a single UPDATE (one broadcast round)" do
        ticket = create(:ticket, :ai_analyzing)
        statements = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
          statements << payload[:sql] if payload[:sql].start_with?('UPDATE "tickets"')
        end
        ticket.take!(by: admin)
        ActiveSupport::Notifications.unsubscribe(subscriber)

        expect(statements.size).to eq(1)
      end
    end

    it "leaves the AI state alone and writes no AI note when it was not engaged" do
      ticket = create(:ticket, ai_state: :resolved)
      ticket.take!(by: admin)
      expect(ticket.reload).to be_ai_resolved
      expect(ticket.notes.pluck(:body)).to eq(["Ticket taken by #{admin.email}."])
    end
  end

  describe "#unassign!" do
    it "returns an in_progress ticket to open and notes it" do
      ticket = create(:ticket, status: :in_progress, assigned: admin)
      ticket.unassign!(by: admin)
      expect(ticket.reload).to be_open
      expect(ticket.assigned).to be_nil
      expect(last_note(ticket)).to have_attributes(body: "Left the ticket. Back to open.", account: admin)
    end

    it "keeps a reopened ticket reopened" do
      ticket = create(:ticket, status: :reopened, assigned: admin)
      ticket.unassign!(by: admin)
      expect(ticket.reload).to be_reopened
      expect(ticket.assigned).to be_nil
      expect(last_note(ticket).body).to eq("Left the ticket.")
    end

    it "leaves an open, stepped back ticket unmessageable with the waiting banner" do
      ticket = create(:ticket, status: :in_progress, assigned: admin, ai_state: :stepped_back)
      ticket.unassign!(by: admin)
      ticket.reload

      expect(ticket).to be_open
      expect(ticket).to be_ai_stepped_back
      expect(ticket).not_to be_messageable

      html = ApplicationController.render(partial: "support/conversations/message_form", locals: {ticket: ticket})
      expect(html).to include(I18n.t("support.ticket_status_banner.default"))
      expect(html).not_to include(I18n.t("support.messages.placeholder"))
    end

    it "does not touch the AI state" do
      ticket = create(:ticket, status: :in_progress, assigned: admin, ai_state: :stepped_back)
      ticket.unassign!(by: admin)
      expect(ticket.reload).to be_ai_stepped_back
    end

    it "refuses accounts that are not the assignee" do
      ticket = create(:ticket, status: :in_progress, assigned: admin)
      expect { ticket.unassign!(by: other_admin) }.to raise_error(Support::Ticket::InvalidTransition, I18n.t("ticket.transitions.not_assigned"))
      expect(ticket.reload.assigned).to eq(admin)
    end

    it "refuses unassigned tickets" do
      expect { create(:ticket).unassign!(by: admin) }.to raise_error(Support::Ticket::InvalidTransition)
    end

    %i[finished reopen_requested closed].each do |status|
      it "refuses #{status} tickets" do
        ticket = create(:ticket, status: status, assigned: admin)
        expect { ticket.unassign!(by: admin) }.to raise_error(Support::Ticket::InvalidTransition, I18n.t("ticket.transitions.can_only_unassign"))
        expect(ticket.reload.assigned).to eq(admin)
      end
    end

    it "re-checks after the lock (stale instance)" do
      ticket = create(:ticket, status: :in_progress, assigned: admin)
      stale = described_class.find(ticket.id)
      described_class.find(ticket.id).update_columns(status: described_class.statuses[:finished])
      expect { stale.unassign!(by: admin) }.to raise_error(Support::Ticket::InvalidTransition)
      expect(ticket.reload.assigned).to eq(admin)
    end
  end
end
