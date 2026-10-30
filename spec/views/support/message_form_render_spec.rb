require "rails_helper"

# Turbo broadcasts render partials through ApplicationController.render: no request, no
# current_account, no allowed_to?. Every partial the ticket broadcasts must render from its
# locals alone, for every status / ai_state combination.
RSpec.describe "conversation partials rendered for a broadcast" do
  def render_partial(name, locals)
    ApplicationController.render(partial: "support/conversations/#{name}", locals: locals)
  end

  Support::Ticket.statuses.each_key do |status|
    Support::Ticket.ai_states.each_key do |ai_state|
      it "renders message_form and ai_status for #{status} / #{ai_state}" do
        # A human owner and an engaged AI never coexist (Support::Ticket invariant).
        assignee = create(:account, :verified) unless %w[analyzing awaiting_user handoff_requested].include?(ai_state)
        ticket = create(:ticket, status: status, ai_state: ai_state, assigned: assignee)

        form = nil
        expect { form = render_partial("message_form", {ticket: ticket}) }.not_to raise_error
        expect { render_partial("ai_status", {ticket: ticket}) }.not_to raise_error

        expect(form).to include(ActionView::RecordIdentifier.dom_id(ticket, "message_form"))
        if ticket.messageable?
          expect(form).to include("<form")
          expect(form).to include(I18n.t("support.messages.placeholder"))
        else
          expect(form).not_to include(I18n.t("support.messages.placeholder"))
        end
      end
    end
  end

  it "gates the reopen form to the requester with turbo-show on a finished ticket" do
    ticket = create(:ticket, :finished)
    html = render_partial("message_form", {ticket: ticket})

    expect(html).to match(/<turbo-show when="current-user-id" is="#{ticket.created_id}">\s*<div[^>]*>\s*<p[^>]*>#{Regexp.escape(I18n.t("support.reopen_form.finished_notice"))}/m)
    expect(html).to include("is_not=\"#{ticket.created_id}\"")
  end

  it "renders AI messages with article cards and resolution buttons" do
    ticket = create(:ticket, :ai_awaiting_user)
    article = create(:article, :published, title: "Broadcast article")
    message = create(:message, :ai, conversation: ticket.conversation,
      metadata: {"article_ids" => [article.id], "resolution_proposed" => true})

    html = render_partial("message", {message: message})

    expect(html).to include("Broadcast article")
    expect(html).to include("data-resolution-actions")
    expect(html).to include("is=\"#{ticket.created_id}\"")
  end

  it "omits resolution buttons once a later message exists or the ticket is no longer open for the assistant" do
    ticket = create(:ticket, :ai_awaiting_user)
    message = create(:message, :ai, conversation: ticket.conversation, metadata: {"resolution_proposed" => true})
    create(:message, conversation: ticket.conversation, account: ticket.created, created_at: 1.minute.from_now)

    expect(render_partial("message", {message: message})).not_to include("data-resolution-actions")

    ticket2 = create(:ticket, :ai_handoff_requested)
    message2 = create(:message, :ai, conversation: ticket2.conversation, metadata: {"resolution_proposed" => true})
    expect(render_partial("message", {message: message2})).not_to include("data-resolution-actions")
  end

  it "ignores unpublished and unknown article ids" do
    ticket = create(:ticket, :ai_awaiting_user)
    draft = create(:article, title: "Hidden draft")
    message = create(:message, :ai, conversation: ticket.conversation,
      metadata: {"article_ids" => [draft.id, 0, "x"], "resolution_proposed" => false})

    expect(render_partial("message", {message: message})).not_to include("Hidden draft")
  end
end
