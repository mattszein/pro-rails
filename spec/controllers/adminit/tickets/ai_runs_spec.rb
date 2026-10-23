# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("spec/controllers/shared/responds.rb")

describe Adminit::Tickets::AiRunsController, type: :controller do
  include_context "user and permissions adminit"
  render_views

  let(:creator_account) { create(:account, :verified) }
  let(:ticket) { create(:ticket, created: creator_account) }
  let(:transcript) do
    [
      {"role" => "system", "content" => "Be helpful"},
      {"role" => "user", "content" => "<script>alert(1)</script>"},
      {"role" => "assistant", "content" => "", "tool_calls" => [{"id" => "c1", "name" => "search_articles", "arguments" => {"query" => "refund"}}]},
      {"role" => "tool", "content" => "found 2", "tool_call_id" => "c1"}
    ]
  end
  let(:run) { create(:ai_run, ticket: ticket, step: :handle, model: "demo-model", transcript: transcript, output: {"reply" => "ok"}) }

  before do
    create(:permission, resource: :ticket, roles: [user.role, user_superadmin.role])
    request.headers["Turbo-Frame"] = "modal"
  end

  describe "GET #show" do
    subject { get :show, params: {ticket_id: ticket.id, id: run.id} }

    include_context "adminit_auth"

    context "when authorized" do
      before { login_user(user) }

      it "is authorized" do
        expect { subject }.to be_authorized_to(:manage?, ticket).with(Adminit::TicketPolicy).with_context(user: user)
      end

      it_behaves_like "respond to success"

      it "renders the transcript, tool calls and escapes content" do
        subject
        body = response.body

        expect(body).to include("Be helpful", "search_articles", "&quot;query&quot;: &quot;refund&quot;", "found 2", "demo-model")
        expect(body).to include("&lt;script&gt;alert(1)&lt;/script&gt;")
        expect(body).not_to include("<script>alert(1)</script>")
      end

      it "shows the KB gap badge, create link and escaped queries for a gap run" do
        gap = create(:ai_run, ticket: ticket, step: :handle, output: {"kb_gap" => true, "kb_queries" => ["<script>alert(2)</script>", "refund"]})
        get :show, params: {ticket_id: ticket.id, id: gap.id}

        body = response.body
        expect(body).to include(I18n.t("adminit.tickets.ai_runs.kb_gap"), I18n.t("adminit.tickets.ai_runs.create_article"), "/adminit/articles/new?")
        expect(body).to include("&lt;script&gt;alert(2)&lt;/script&gt;", "refund")
        expect(body).not_to include("<script>alert(2)</script>")
      end

      it "shows no KB gap section for a run without a gap" do
        expect(subject.body).not_to include("kb-gap")
      end

      it "shows the empty-transcript note for legacy runs" do
        legacy = create(:ai_run, ticket: ticket, transcript: [], tool_calls: [{"name" => "x_tool"}])
        get :show, params: {ticket_id: ticket.id, id: legacy.id}

        expect(response.body).to include(I18n.t("adminit.tickets.ai_runs.no_transcript"), "x_tool")
      end

      it "does not expose a run through another ticket" do
        other = create(:ai_run, ticket: create(:ticket, created: creator_account))
        get :show, params: {ticket_id: ticket.id, id: other.id}

        expect(response).to have_http_status(:redirect)
        expect(response.body).not_to include("ai-run-detail")
      end
    end
  end
end
