require "rails_helper"

RSpec.describe "Support::Ai steps", type: :interactor do
  let(:ticket) { create(:ticket, :ai_analyzing, priority: 4, category: :other) }
  let(:playbook) { create(:ai_playbook, capabilities: capabilities) }
  let(:capabilities) { [] }

  describe Support::Ai::Triage do
    it "stores the triage output and records a succeeded run" do
      stub_responder(triage: ai_result(triage_output(priority: 2)))
      result = described_class.call(ticket: ticket, trigger: "ticket_created")

      expect(result.triage[:priority]).to eq(2)
      run = ticket.ai_runs.last
      expect(run).to have_attributes(step: "triage", status: "succeeded", run_trigger: "ticket_created")
    end

    it "is non-fatal: logs a failed run and leaves triage nil" do
      stub_responder(triage: SupportAi::Error.new("provider down"))
      result = described_class.call(ticket: ticket, trigger: "ticket_created")

      expect(result).to be_success
      expect(result.triage).to be_nil
      expect(ticket.ai_runs.last).to have_attributes(step: "triage", status: "failed", error: "provider down")
    end

    it "reuses a previously succeeded triage instead of calling the model again" do
      create(:ai_run, ticket: ticket, step: :triage, status: :succeeded, run_trigger: :ticket_created, output: triage_output(priority: 1))
      expect(SupportAi::Responder).not_to receive(:new)
      result = described_class.call(ticket: ticket, trigger: "ticket_created")
      expect(result.triage[:priority]).to eq(1)
    end
  end

  describe Support::Ai::SelectPlaybook do
    it "puts the matching playbook on the context" do
      pb = create(:ai_playbook, :default)
      result = described_class.call(ticket: ticket, trigger: "ticket_created", triage: nil)
      expect(result.playbook).to eq(pb)
    end

    it "uses the triaged priority to match" do
      create(:ai_playbook, :default)
      urgent = create(:ai_playbook, min_priority: 5, max_priority: 5)
      result = described_class.call(ticket: ticket, trigger: "ticket_created", triage: {priority: 5}.with_indifferent_access)
      expect(result.playbook).to eq(urgent)
    end

    it "turns the AI off and stops when nothing matches" do
      result = described_class.call(ticket: ticket, trigger: "ticket_created")
      expect(result).to be_failure
      expect(ticket.reload).to be_ai_off
    end

    it "does not touch a ticket an admin already took when nothing matches" do
      ticket.update!(ai_state: :stepped_back)
      result = described_class.call(ticket: ticket, trigger: "ticket_created")
      expect(result).to be_failure
      expect(ticket.reload).to be_ai_stepped_back
    end

    context "on a user reply" do
      it "matches with the current rules" do
        create(:ai_playbook, :default)
        specific = create(:ai_playbook, category_keys: [ticket.category])
        expect(described_class.call(ticket: ticket, trigger: "user_message").playbook).to eq(specific)
      end

      it "falls back to the default" do
        pb = create(:ai_playbook, :default)
        expect(described_class.call(ticket: ticket, trigger: "user_message").playbook).to eq(pb)
      end

      it "hands off to a human when no playbook is available" do
        result = described_class.call(ticket: ticket, trigger: "user_message")
        expect(result).to be_failure
        expect(ticket.reload).to be_ai_handoff_requested
      end
    end
  end

  describe Support::Ai::ApplyTriage do
    let(:triage) { triage_output(priority: 2, category: "billing", summary: "Billing issue").with_indifferent_access }

    def call_step
      described_class.call(ticket: ticket, playbook: playbook, triage: triage)
    end

    it "does nothing without capabilities" do
      call_step
      expect(ticket.reload).to have_attributes(priority: 4, category: "other")
      expect(ticket.notes).to be_empty
    end

    context "with auto_set_priority" do
      let(:capabilities) { ["auto_set_priority"] }

      it "updates the priority and writes an English system note" do
        call_step
        expect(ticket.reload.priority).to eq(2)
        expect(ticket.category).to eq("other")
        expect(ticket.notes.system.first).to have_attributes(account: nil, body: "AI set priority 2 (was 4): Billing issue")
      end

      it "writes no note when the value is unchanged" do
        ticket.update!(priority: 2)
        expect { call_step }.not_to change(Support::Note, :count)
      end
    end

    context "with auto_correct_category" do
      let(:capabilities) { ["auto_correct_category"] }

      it "changes the category with a note" do
        call_step
        expect(ticket.reload.category).to eq("billing")
        expect(ticket.priority).to eq(4)
        expect(ticket.notes.system.first.body).to eq("AI changed category to billing (was other)")
      end
    end

    it "is a no-op when triage failed" do
      expect { described_class.call(ticket: ticket, playbook: create(:ai_playbook, capabilities: %w[auto_set_priority]), triage: nil) }.not_to change(Support::Note, :count)
    end
  end

  describe Support::Ai::Handle do
    def call_step(**ctx)
      described_class.call({ticket: ticket, playbook: playbook, trigger: "ticket_created", triage: nil}.merge(ctx))
    end

    it "stores the reply and records one handle run" do
      responder = stub_responder(handle: ai_result(handle_output))
      result = call_step(triage: triage_output.with_indifferent_access)

      expect(result.reply[:reply]).to eq("Try resetting your password.")
      expect(result.handle_run).to have_attributes(step: "handle", status: "succeeded", playbook: playbook)
      expect(responder).to have_received(:handle).with(triage: hash_including(priority: 3), reply: true, trigger_message: nil)
    end

    it "passes the trigger message through" do
      message = create(:message, conversation: ticket.conversation, account: ticket.created)
      responder = stub_responder(handle: ai_result(handle_output))
      call_step(trigger_message: message)
      expect(responder).to have_received(:handle).with(hash_including(trigger_message: message))
    end

    it "writes no ai note without investigate_note" do
      stub_responder(handle: ai_result(handle_output))
      expect { call_step }.not_to change(Support::Note, :count)
    end

    context "with investigate_note" do
      let(:capabilities) { ["investigate_note"] }

      it "writes ONE ai note: the findings plus the help-center line" do
        stub_responder(handle: ai_result(handle_output(findings: "Expired session.")))
        result = call_step
        expect(ticket.notes.ai.count).to eq(1)
        expect(ticket.notes.ai.first).to have_attributes(account: nil, body: "Expired session.\nHelp center: no article answered this.")
        expect(result.note_written).to be(true)
      end

      it "lists the attached article titles in the help-center line" do
        article = create(:article, :published, title: "Changing your password")
        stub_responder(handle: ai_result(handle_output(findings: "User wants a new password.", article_ids: [article.id])))
        call_step
        expect(ticket.notes.ai.first.body).to eq("User wants a new password.\nHelp center: Changing your password")
      end
    end

    context "with similar_tickets" do
      let(:capabilities) { %w[investigate_note similar_tickets] }
      let(:other) { create(:account) }

      before { ticket.update!(category: :billing, title: "Invoice charged twice") }

      it "appends a deterministic admin-only line to the single ai note, without calling the model for it" do
        match = create(:ticket, :finished, created: other, category: :billing, title: "Invoice problem", description: "SECRET DESC")
        create(:ticket, :finished, created: other, category: :technical_issue, title: "Invoice crash")
        create(:ticket, created: other, category: :billing, title: "Invoice still open")
        stub_responder(handle: ai_result(handle_output(findings: "User was charged twice.")))

        call_step

        expect(ticket.notes.ai.pluck(:body)).to eq([
          "User was charged twice.\nHelp center: no article answered this.\nSimilar resolved tickets: ##{match.id} Invoice problem (#{match.created_at.strftime("%Y-%m")})"
        ])
        expect(ticket.notes.ai.first.body).not_to include("SECRET DESC")
        expect(ticket.ai_runs.pluck(:step)).to eq(%w[handle])
      end

      it "adds no line when nothing similar exists" do
        stub_responder(handle: ai_result(handle_output(findings: "User was charged twice.")))
        call_step
        expect(ticket.notes.ai.first.body).not_to include("Similar resolved tickets")
      end

      it "adds nothing without the note capability" do
        create(:ticket, :finished, created: other, category: :billing, title: "Invoice problem")
        stub_responder(handle: ai_result(handle_output))
        call_step(playbook: create(:ai_playbook, capabilities: %w[similar_tickets]))
        expect(ticket.notes).to be_empty
      end

      it "skips playbooks without similar_tickets" do
        create(:ticket, :finished, created: other, category: :billing, title: "Invoice problem")
        stub_responder(handle: ai_result(handle_output))
        call_step(playbook: create(:ai_playbook, capabilities: %w[investigate_note]))
        expect(ticket.notes.ai.first.body).not_to include("Similar resolved")
      end
    end

    it "strips a leading note label the model added" do
      ["Internal note (for admin): Expired session.", "**Internal note:** Expired session.", "Note: Expired session."].each do |findings|
        ticket.notes.destroy_all
        stub_responder(handle: ai_result(handle_output(findings: findings)))
        call_step(playbook: create(:ai_playbook, capabilities: ["investigate_note"]))
        expect(ticket.notes.ai.first.body).to eq("Expired session.\nHelp center: no article answered this.")
      end
    end

    it "keeps findings that merely start with the word note" do
      stub_responder(handle: ai_result(handle_output(findings: "Note that the user wants an export.")))
      call_step(playbook: create(:ai_playbook, capabilities: ["investigate_note"]))
      expect(ticket.notes.ai.first.body).to start_with("Note that the user wants an export.")
    end

    it "truncates the stored note at 1,200 characters" do
      stub_responder(handle: ai_result(handle_output(findings: "x" * 2_000)))
      call_step(playbook: create(:ai_playbook, capabilities: ["investigate_note"]))
      body = ticket.notes.ai.first.body
      findings, line = body.split("\n")
      expect(findings.length).to eq(Support::Ai::Handle::NOTE_LIMIT)
      expect(findings).to end_with("…")
      expect(line).to eq("Help center: no article answered this.")
    end

    it "stores kb_gap and kb_queries in the run output" do
      stub_responder(handle: ai_result(handle_output(kb_gap: true, kb_queries: %w[a b])))
      result = call_step
      expect(result.handle_run.output).to include("kb_gap" => true, "kb_queries" => %w[a b])
    end

    context "with a KB gap" do
      let(:gap) { handle_output(kb_gap: true, kb_queries: %w[export csv]) }

      it "writes no separate KB gap note and no note without investigate_note" do
        stub_responder(handle: ai_result(gap))
        result = call_step
        expect(ticket.notes).to be_empty
        expect(result.note_written).to be_falsey
      end

      it "writes a single note with the no-article line" do
        stub_responder(handle: ai_result(gap.merge(findings: "User wants an export.")))
        call_step(playbook: create(:ai_playbook, capabilities: ["investigate_note"]))
        expect(ticket.notes.ai.pluck(:body)).to eq(["User wants an export.\nHelp center: no article answered this."])
      end

      it "writes nothing when the step fails" do
        stub_responder(handle: SupportAi::Error.new("bad"))
        expect { call_step(playbook: create(:ai_playbook, capabilities: ["investigate_note"])) }.to raise_error(SupportAi::Error)
        expect(ticket.notes).to be_empty
      end
    end

    it "asks for findings only (reply nil) for triage_only playbooks" do
      responder = stub_responder(handle: ai_result(handle_output(reply: nil)))
      result = call_step(playbook: create(:ai_playbook, :triage_only))
      expect(responder).to have_received(:handle).with(hash_including(reply: false))
      expect(result.reply).to be_nil
    end

    it "asks for findings only when triage escalated" do
      responder = stub_responder(handle: ai_result(handle_output(reply: nil)))
      result = call_step(triage: triage_output(escalate: true).with_indifferent_access)
      expect(responder).to have_received(:handle).with(hash_including(reply: false))
      expect(result.reply).to be_nil
    end

    it "is fatal: logs a failed run, re-raises and writes no note" do
      stub_responder(handle: SupportAi::Error.new("bad output"))
      expect { call_step(playbook: create(:ai_playbook, capabilities: ["investigate_note"])) }.to raise_error(SupportAi::Error, "bad output")
      expect(ticket.ai_runs.last).to have_attributes(step: "handle", status: "failed", error: "bad output")
      expect(ticket.notes).to be_empty
    end
  end

  describe Support::Ai::Respond do
    def call_step(**ctx)
      described_class.call({ticket: ticket, playbook: playbook, trigger: "ticket_created", triage: nil}.merge(ctx))
    end

    it "stores the reply and records the run" do
      stub_responder(respond: ai_result(respond_output))
      result = call_step
      expect(result.reply[:reply]).to eq("Try resetting your password.")
      expect(result.respond_run).to have_attributes(step: "respond", status: "succeeded")
    end

    it "passes the trigger message to the responder" do
      message = create(:message, conversation: ticket.conversation, account: ticket.created)
      responder = stub_responder(respond: ai_result(respond_output))
      call_step(trigger_message: message)
      expect(responder).to have_received(:respond).with(trigger_message: message)
    end

    it "is skipped for triage_only playbooks" do
      expect(SupportAi::Responder).not_to receive(:new)
      expect(call_step(playbook: create(:ai_playbook, :triage_only)).reply).to be_nil
    end

    it "is skipped when triage escalated" do
      expect(SupportAi::Responder).not_to receive(:new)
      expect(call_step(triage: triage_output(escalate: true).with_indifferent_access).reply).to be_nil
    end

    it "is fatal: logs a failed run and re-raises" do
      stub_responder(respond: SupportAi::Error.new("bad output"))
      expect { call_step }.to raise_error(SupportAi::Error, "bad output")
      expect(ticket.ai_runs.last).to have_attributes(step: "respond", status: "failed", error: "bad output")
    end
  end
end
