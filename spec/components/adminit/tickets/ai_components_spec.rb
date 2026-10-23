require "rails_helper"

RSpec.describe "Adminit ticket AI components", type: :component do
  describe Adminit::TicketInfoComponent do
    it "shows no AI badge when the assistant is off" do
      render_inline(described_class.new(ticket: create(:ticket)))

      expect(page).not_to have_text(I18n.t("enums.ticket.ai_state.analyzing"))
      expect(page).not_to have_text(I18n.t("adminit.tickets.ai_playbook"))
    end

    it "shows the AI-state badge and the applied playbook name" do
      ticket = create(:ticket, :ai_handoff_requested)

      render_inline(described_class.new(ticket: ticket, playbook_name: "Billing flow"))

      expect(page).to have_css(".bg-orange-300", text: "Needs human", minimum: 1)
      expect(page).to have_text("Billing flow")
    end

    it "translates the badge" do
      I18n.with_locale(:es) do
        render_inline(described_class.new(ticket: create(:ticket, :ai_awaiting_user)))
      end

      expect(page).to have_text("Esperando al usuario")
    end
  end

  describe Adminit::Tickets::NoteComponent do
    it "labels AI notes distinctly" do
      render_inline(described_class.new(note: create(:note, :ai, body: "Looks like a refund")))

      expect(page).to have_css(".border-violet-400")
      expect(page).to have_css(".bg-violet-300", text: I18n.t("adminit.notes.ai"))
      expect(page).to have_text(I18n.t("adminit.notes.ai"))
      expect(page).to have_text("Looks like a refund")
    end

    it "leaves system notes unchanged" do
      render_inline(described_class.new(note: create(:note, :system, body: "Assigned")))

      expect(page).to have_css(".border-slate-400")
      expect(page).not_to have_css(".border-violet-400")
    end
  end

  describe Adminit::Tickets::AiRunsComponent do
    let(:ticket) { create(:ticket, :ai_awaiting_user) }

    it "shows an empty state" do
      render_inline(described_class.new(runs: []))
      expect(page).to have_text(I18n.t("adminit.tickets.no_ai_runs"))
    end

    it "lists runs newest first with tokens, latency, tools and a truncated error" do
      old = create(:ai_run, ticket: ticket, step: :triage, model: "m-old", created_at: 2.hours.ago)
      failed = create(:ai_run, ticket: ticket, step: :respond, status: :failed, model: "m-new", input_tokens: 10,
        output_tokens: 5, latency_ms: 321, tool_calls: [{"name" => "search_articles"}], error: "x" * 200)

      render_inline(described_class.new(runs: [old, failed]))

      rows = page.all("[data-role='ai-run']")
      expect(rows.size).to eq(2)
      expect(rows.first.text).to include("m-new", "10 / 5", "321", "search_articles", "Failed")
      expect(rows.first.text).not_to include("x" * 100)
      expect(rows.last.text).to include("m-old")
    end

    it "links each run to its viewer in the modal frame when given a ticket" do
      run = create(:ai_run, ticket: ticket)

      render_inline(described_class.new(runs: [run], ticket: ticket))

      link = page.find("a", text: I18n.t("adminit.tickets.ai_runs.view"))
      expect(link[:href]).to end_with("/adminit/tickets/#{ticket.id}/ai_runs/#{run.id}")
      expect(link["data-turbo-frame"]).to eq("modal")
    end
  end

  describe "KB gap in Adminit::Tickets::AiRunsComponent" do
    let(:ticket) { create(:ticket, :ai_awaiting_user, title: "Export & share (CSV)?", category: :technical_issue) }

    it "shows the badge and a prefilled Create article link for a handle run with kb_gap" do
      run = create(:ai_run, ticket: ticket, step: :handle, output: {"kb_gap" => true, "kb_queries" => ["csv export"]})

      render_inline(Adminit::Tickets::AiRunsComponent.new(runs: [run], ticket: ticket))

      expect(page).to have_css("[data-role='kb-gap']", text: I18n.t("adminit.tickets.ai_runs.kb_gap"))
      href = page.find("a", text: I18n.t("adminit.tickets.ai_runs.create_article"))[:href]
      expect(href).to match(%r{\A/(en/)?adminit/articles/new\?})
      query = Rack::Utils.parse_query(URI(href).query)
      expect(query).to eq("title" => "Export & share (CSV)?", "category" => "technical_issue")
      expect(href).to include("title=Export+%26+share")
    end

    it "shows nothing for runs without a gap, other steps or no ticket" do
      no_gap = create(:ai_run, ticket: ticket, step: :handle, output: {"kb_gap" => false})
      triage = create(:ai_run, ticket: ticket, step: :triage, output: {"kb_gap" => true})
      empty = create(:ai_run, ticket: ticket, step: :respond, output: {})

      render_inline(Adminit::Tickets::AiRunsComponent.new(runs: [no_gap, triage, empty], ticket: ticket))
      expect(page).not_to have_css("[data-role='kb-gap']")

      gap = create(:ai_run, ticket: ticket, step: :handle, output: {"kb_gap" => true})
      render_inline(Adminit::Tickets::AiRunsComponent.new(runs: [gap]))
      expect(page).not_to have_css("[data-role='kb-gap']")
    end

    it "does not query the database" do
      run = create(:ai_run, ticket: ticket, step: :handle, output: {"kb_gap" => true})
      queries = []
      callback = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        render_inline(Adminit::Tickets::AiRunsComponent.new(runs: [run], ticket: ticket))
      end
      expect(queries).to be_empty
    end
  end

  describe Adminit::Tickets::AiRunTranscriptComponent do
    let(:ticket) { create(:ticket, :ai_awaiting_user) }

    it "renders roles, tool calls with arguments, labelled results, output and escapes content" do
      run = create(:ai_run, ticket: ticket, error: "boom", output: {"reply" => "hi"}, transcript: [
        {"role" => "user", "content" => "<b>x</b>"},
        {"role" => "assistant", "tool_calls" => [{"id" => "c1", "name" => "search_articles", "arguments" => {"q" => "a"}}]},
        {"role" => "tool", "content" => "res", "tool_call_id" => "c1"}
      ])

      render_inline(described_class.new(run: run, playbook_name: "Billing flow"))

      expect(page).to have_css("[data-role='transcript-entry']", count: 3)
      expect(page).to have_text("search_articles / c1")
      expect(page).to have_text("Billing flow")
      expect(page).to have_css("[data-role='ai-run-error']", text: "boom")
      expect(page).to have_text('"reply": "hi"')
      expect(page).to have_text("<b>x</b>")
      expect(page).not_to have_css("pre b")
    end

    it "explains a missing transcript" do
      render_inline(described_class.new(run: create(:ai_run, ticket: ticket)))

      expect(page).to have_css("[data-role='no-transcript']", text: I18n.t("adminit.tickets.ai_runs.no_transcript"))
    end
  end
end
