require "rails_helper"

RSpec.describe Support::Ticket, type: :model do
  describe "attachments" do
    let(:ticket) { create(:ticket) }
    let(:valid_image) do
      {
        io: StringIO.new("valid image data"),
        filename: "test.png",
        content_type: "image/png"
      }
    end
    let(:large_image) do
      {
        io: StringIO.new("0" * (3 * 1024 * 1024)), # 3MB file
        filename: "large.png",
        content_type: "image/png"
      }
    end
    let(:invalid_file) do
      {
        io: StringIO.new("test file"),
        filename: "test.txt",
        content_type: "text/plain"
      }
    end

    it "allows attaching valid images" do
      ticket.attachments.attach(valid_image)
      expect(ticket).to be_valid
      expect(ticket.attachments.count).to eq(1)
    end

    it "validates file size" do
      ticket.attachments.attach(large_image)
      expect(ticket).not_to be_valid
      expect(ticket.errors[:attachments]).to include(match(/too large/))
    end

    it "validates content type" do
      ticket.attachments.attach(invalid_file)
      expect(ticket).not_to be_valid
      expect(ticket.errors[:attachments]).to include(match(/invalid file type/))
    end

    it "validates maximum number of attachments" do
      (FileUploadConfig.max_files_per_ticket + 1).times do
        ticket.attachments.attach(
          io: StringIO.new("test"),
          filename: "test.png",
          content_type: "image/png"
        )
      end
      expect(ticket).not_to be_valid
      expect(ticket.errors[:attachments]).to include(match(/cannot exceed/))
    end

    it "does not persist a new ticket with too many attachments" do
      new_ticket = build(:ticket)
      (FileUploadConfig.max_files_per_ticket + 1).times do
        new_ticket.attachments.attach(io: StringIO.new("test"), filename: "test.png", content_type: "image/png")
      end

      expect(new_ticket.save).to be(false)
      expect(new_ticket.errors[:attachments]).to include(match(/cannot exceed/))
      expect(new_ticket).not_to be_persisted
    end

    it "allows attaching multiple valid files" do
      3.times do |i|
        ticket.attachments.attach(
          io: StringIO.new("test #{i}"),
          filename: "test_#{i}.png",
          content_type: "image/png"
        )
      end
      expect(ticket).to be_valid
      expect(ticket.attachments.count).to eq(3)
    end
  end

  describe "scopes" do
    describe ".search_title" do
      it "matches a case-insensitive partial title" do
        matching = create(:ticket, title: "Cannot log in")
        create(:ticket, title: "Billing question")

        expect(Support::Ticket.search_title("log in")).to contain_exactly(matching)
      end

      it "is case-insensitive" do
        matching = create(:ticket, title: "Cannot Log In")
        expect(Support::Ticket.search_title("log in")).to contain_exactly(matching)
      end
    end

    describe ".assigned_to" do
      it "returns tickets assigned to the given account id" do
        account = create(:account, :verified)
        other_account = create(:account, :verified)
        ticket = create(:ticket, assigned: account)
        create(:ticket, assigned: other_account)

        expect(Support::Ticket.assigned_to(account.id)).to contain_exactly(ticket)
      end
    end

    describe ".recent_open" do
      it "returns open tickets ordered by updated_at desc" do
        old_ticket = create(:ticket)
        new_ticket = create(:ticket)
        old_ticket.update_column(:updated_at, 2.days.ago)
        create(:ticket, :closed)

        expect(Support::Ticket.recent_open).to eq([new_ticket, old_ticket])
      end

      it "honors the limit" do
        create_list(:ticket, 3)
        expect(Support::Ticket.recent_open(limit: 2).count).to eq(2)
      end
    end

    describe ".assigned_open_for" do
      let(:account) { create(:account, :verified) }
      let(:other_account) { create(:account, :verified) }

      it "returns open tickets assigned to the account" do
        ticket = create(:ticket, assigned: account)
        create(:ticket, assigned: other_account)
        create(:ticket, :closed, assigned: account)

        expect(Support::Ticket.assigned_open_for(account)).to eq([ticket])
      end

      it "honors the limit" do
        create_list(:ticket, 5, assigned: account)
        expect(Support::Ticket.assigned_open_for(account, limit: 3).count).to eq(3)
      end
    end
  end

  describe ".dashboard_stats" do
    let(:account) { create(:account, :verified) }

    it "returns ticket stats" do
      create(:ticket, status: :open, created: account)
      create(:ticket, status: :in_progress, created: account, assigned: account)
      create(:ticket, status: :finished, created: account, assigned: account)
      create(:ticket, status: :closed, created: account, assigned: account)

      stats = Support::Ticket.dashboard_stats

      expect(stats[:total]).to eq(4)
      expect(stats[:open]).to eq(1)
      expect(stats[:in_progress]).to eq(1)
      expect(stats[:resolved]).to eq(2)
      expect(stats[:by_status]).to include("open" => 1, "in_progress" => 1, "finished" => 1, "closed" => 1)
    end

    it "counts open tickets waiting for a human" do
      create(:ticket, :ai_handoff_requested)
      create(:ticket, :ai_handoff_requested)
      create(:ticket, :in_progress, ai_state: :stepped_back)
      create(:ticket, :ai_awaiting_user)

      expect(Support::Ticket.dashboard_stats[:needs_human]).to eq(2)
    end
  end

  # Turbo broadcasts render partials through ApplicationController.render, outside any controller,
  # so a partial must get everything from its locals (no @ivars set by an action).
  describe "admin ticket partial rendered for a broadcast" do
    let(:ticket) { create(:ticket) }

    def render_partial
      ApplicationController.render(partial: "adminit/tickets/ticket", locals: {ticket: ticket})
    end

    it "renders a ticket with no notes or messages" do
      expect(render_partial).to include(I18n.t("adminit.tickets.no_notes"))
    end

    it "renders notes, messages and a non-image attachment" do
      ticket.notes.create!(body: "internal note body")
      create(:message, conversation: ticket.conversation, content: "hello from the thread")
      ticket.attachments.attach(io: StringIO.new("%PDF-1.4"), filename: "invoice.pdf", content_type: "application/pdf")

      html = render_partial

      expect(html).to include("internal note body")
      expect(html).to include("hello from the thread")
      expect(html).to include("invoice.pdf")
    end
  end

  describe "AI state" do
    it "defaults to off" do
      expect(create(:ticket)).to be_ai_off
    end

    describe "#ai_engaged?" do
      it "is true for analyzing, awaiting_user and handoff_requested" do
        expect(build(:ticket, :ai_analyzing)).to be_ai_engaged
        expect(build(:ticket, :ai_awaiting_user)).to be_ai_engaged
        expect(build(:ticket, :ai_handoff_requested)).to be_ai_engaged
      end

      it "is false for off, stepped_back and resolved" do
        expect(build(:ticket)).not_to be_ai_engaged
        expect(build(:ticket, :ai_stepped_back)).not_to be_ai_engaged
        expect(build(:ticket, :ai_resolved)).not_to be_ai_engaged
      end
    end

    describe "#ai_pass_current?" do
      let(:ticket) { create(:ticket, :ai_analyzing) }
      let(:account) { ticket.created }

      it "is true while analyzing with no newer human message" do
        trigger = create(:message, conversation: ticket.conversation, account: account)
        expect(ticket).to be_ai_pass_current(trigger)
      end

      it "is false when the ticket is not analyzing" do
        ticket.update!(ai_state: :stepped_back)
        expect(ticket).not_to be_ai_pass_current
      end

      it "is false when the user wrote after the trigger message" do
        trigger = create(:message, conversation: ticket.conversation, account: account)
        create(:message, conversation: ticket.conversation, account: account)
        expect(ticket).not_to be_ai_pass_current(trigger)
      end

      it "without a trigger message is true when there is no human message" do
        expect(ticket).to be_ai_pass_current
      end

      it "without a trigger message is false once any human message exists" do
        create(:message, conversation: ticket.conversation, account: account)
        expect(ticket).not_to be_ai_pass_current
      end
    end

    describe "#awaiting_ai_resolution?" do
      it "is true for open tickets the AI is waiting on" do
        expect(build(:ticket, :ai_awaiting_user)).to be_awaiting_ai_resolution
      end

      it "is false while analyzing, for other AI states and for finished tickets" do
        expect(build(:ticket, :ai_analyzing)).not_to be_awaiting_ai_resolution
        expect(build(:ticket, :ai_handoff_requested)).not_to be_awaiting_ai_resolution
        expect(build(:ticket)).not_to be_awaiting_ai_resolution
        expect(build(:ticket, :ai_awaiting_user, status: :in_progress)).not_to be_awaiting_ai_resolution
      end
    end

    describe "#messageable?" do
      it "is true when in progress or reopened" do
        expect(build(:ticket, :in_progress)).to be_messageable
        expect(build(:ticket, :reopened)).to be_messageable
      end

      it "is true for open tickets while the AI awaits the user or a human" do
        expect(build(:ticket, :ai_awaiting_user)).to be_messageable
        expect(build(:ticket, :ai_handoff_requested)).to be_messageable
      end

      it "is false while the assistant analyzes (the pass is uninterrupted) but the AI stays engaged" do
        ticket = build(:ticket, :ai_analyzing)
        expect(ticket).not_to be_messageable
        expect(ticket).to be_ai_engaged
      end

      it "is false for plain open, stepped-back or finished tickets" do
        expect(build(:ticket)).not_to be_messageable
        expect(build(:ticket, :ai_stepped_back)).not_to be_messageable
        expect(build(:ticket, :finished)).not_to be_messageable
        expect(build(:ticket, :closed)).not_to be_messageable
      end
    end

    describe "transitions" do
      it "start_ai_analysis! moves off or awaiting_user to analyzing" do
        expect(create(:ticket).tap(&:start_ai_analysis!)).to be_ai_analyzing
        expect(create(:ticket, :ai_awaiting_user).tap(&:start_ai_analysis!)).to be_ai_analyzing
      end

      it "start_ai_analysis! rejects other states" do
        %i[ai_analyzing ai_handoff_requested ai_stepped_back ai_resolved].each do |trait|
          expect { create(:ticket, trait).start_ai_analysis! }.to raise_error(Support::Ticket::InvalidTransition)
        end
      end

      it "await_user_reply! only from analyzing" do
        expect(create(:ticket, :ai_analyzing).tap(&:await_user_reply!)).to be_ai_awaiting_user
        expect { create(:ticket).await_user_reply! }.to raise_error(Support::Ticket::InvalidTransition)
        expect { create(:ticket, :ai_awaiting_user).await_user_reply! }.to raise_error(Support::Ticket::InvalidTransition)
      end

      it "request_ai_handoff! from analyzing or awaiting_user" do
        expect(create(:ticket, :ai_analyzing).tap(&:request_ai_handoff!)).to be_ai_handoff_requested
        expect(create(:ticket, :ai_awaiting_user).tap(&:request_ai_handoff!)).to be_ai_handoff_requested
        expect { create(:ticket, :ai_handoff_requested).request_ai_handoff! }.to raise_error(Support::Ticket::InvalidTransition)
        expect { create(:ticket).request_ai_handoff! }.to raise_error(Support::Ticket::InvalidTransition)
      end

      it "disable_ai! turns an analyzing ticket off and nothing else" do
        expect(create(:ticket, :ai_analyzing).tap(&:disable_ai!)).to be_ai_off
        %i[ai_awaiting_user ai_handoff_requested ai_stepped_back].each do |trait|
          expect { create(:ticket, trait).disable_ai! }.to raise_error(Support::Ticket::InvalidTransition, I18n.t("ticket.transitions.can_only_disable_ai"))
        end
        expect { create(:ticket).disable_ai! }.to raise_error(Support::Ticket::InvalidTransition)
      end

      it "resolve_with_ai! finishes the ticket and resolves the AI in one update" do
        ticket = create(:ticket, :ai_awaiting_user)
        ticket.resolve_with_ai!
        ticket.reload
        expect(ticket).to be_finished
        expect(ticket).to be_ai_resolved
      end

      it "resolve_with_ai! requires an open ticket awaiting the user" do
        expect { create(:ticket, :ai_analyzing).resolve_with_ai! }.to raise_error(Support::Ticket::InvalidTransition)
        expect { create(:ticket, status: :in_progress, ai_state: :awaiting_user).resolve_with_ai! }.to raise_error(Support::Ticket::InvalidTransition)
      end

      it "uses the translated error message" do
        expect { create(:ticket).resolve_with_ai! }.to raise_error(Support::Ticket::InvalidTransition, I18n.t("ticket.transitions.can_only_resolve_with_ai"))
      end
    end

    describe "ai_state_changed_at" do
      it "is set when ai_state changes" do
        ticket = create(:ticket)
        expect(ticket.ai_state_changed_at).to be_nil
        freeze_time do
          ticket.start_ai_analysis!
          expect(ticket.reload.ai_state_changed_at).to eq(Time.current)
        end
      end

      it "is untouched by other updates" do
        ticket = create(:ticket, :ai_analyzing)
        ticket.update!(ai_state_changed_at: 1.day.ago)
        stamp = ticket.reload.ai_state_changed_at
        ticket.update!(title: "Changed")
        expect(ticket.reload.ai_state_changed_at).to eq(stamp)
      end
    end

    describe "AI transitions on a stale instance" do
      {
        start_ai_analysis!: [:ai_analyzing, nil],
        await_user_reply!: [:ai_awaiting_user, :ai_analyzing],
        disable_ai!: [:ai_off, :ai_analyzing],
        request_ai_handoff!: [:ai_stepped_back, :ai_analyzing]
      }.each do |transition, (moved_state, initial_trait)|
        it "#{transition} re-checks the state after the lock" do
          ticket = initial_trait ? create(:ticket, initial_trait) : create(:ticket)
          stale = described_class.find(ticket.id)
          described_class.find(ticket.id).update_columns(ai_state: described_class.ai_states.fetch(moved_state.to_s.delete_prefix("ai_")))
          expect { stale.public_send(transition) }.to raise_error(Support::Ticket::InvalidTransition)
        end
      end

      it "resolve_with_ai! re-checks the state after the lock" do
        ticket = create(:ticket, :ai_awaiting_user)
        stale = described_class.find(ticket.id)
        described_class.find(ticket.id).update!(status: :in_progress)
        expect { stale.resolve_with_ai! }.to raise_error(Support::Ticket::InvalidTransition)
      end
    end

    describe "resolve_with_ai! notes" do
      it "resolve_with_ai! writes the resolution system note" do
        ticket = create(:ticket, :ai_awaiting_user)
        ticket.resolve_with_ai!
        expect(ticket.notes.system.first).to have_attributes(body: "Resolved by the user with AI assistance.", account: nil)
      end

      it "writes no note when the transition is rejected" do
        ticket = create(:ticket)
        expect { ticket.resolve_with_ai! }.to raise_error(Support::Ticket::InvalidTransition)
        expect(ticket.notes).to be_empty
      end
    end

    describe "AI/assignment invariant" do
      it "is invalid when built assigned and engaged" do
        %i[ai_analyzing ai_awaiting_user ai_handoff_requested].each do |trait|
          ticket = build(:ticket, trait, assigned: create(:account), created: create(:account))
          expect(ticket).not_to be_valid
          expect(ticket.errors[:ai_state]).to be_present
        end
      end

      it "is invalid when an engaged ticket is assigned by a plain update" do
        ticket = create(:ticket, :ai_analyzing)
        expect(ticket.update(assigned: create(:account))).to be(false)
        expect(ticket.errors[:ai_state]).to include(I18n.t("activerecord.errors.models.support/ticket.attributes.ai_state.engaged_while_assigned"))
      end

      it "is invalid when the AI is engaged on an assigned ticket" do
        ticket = create(:ticket, :assigned)
        expect(ticket.update(ai_state: :analyzing)).to be(false)
      end

      it "allows assigned tickets with the AI off, stepped back or resolved" do
        %i[ai_stepped_back ai_resolved].each { |trait| expect(create(:ticket, :assigned, trait)).to be_valid }
        expect(create(:ticket, :assigned)).to be_valid
      end

      it "start_ai_analysis! refuses assigned tickets" do
        ticket = create(:ticket, :assigned)
        expect { ticket.start_ai_analysis! }.to raise_error(Support::Ticket::InvalidTransition)
        expect(ticket.reload).to be_ai_off
      end
    end

    describe "associations" do
      it "destroys ai_runs with the ticket" do
        ticket = create(:ticket)
        create(:ai_run, ticket: ticket)
        expect { ticket.destroy! }.to change(Support::AiRun, :count).by(-1)
      end
    end
  end
end
