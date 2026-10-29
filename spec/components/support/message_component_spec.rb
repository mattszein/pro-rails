require "rails_helper"

RSpec.describe Support::MessageComponent, type: :component do
  let(:ticket) { create(:ticket, :ai_awaiting_user) }
  let(:conversation) { ticket.conversation }
  let(:human_message) { create(:message, conversation: conversation, content: "Help me") }
  let(:ai_message) do
    create(:message, :ai, conversation: conversation, content: "Try this.",
      metadata: {"article_ids" => [], "resolution_proposed" => false})
  end

  it "renders a human message with the author email and no AI treatment" do
    render_inline(described_class.new(message: human_message))

    expect(page).to have_text(human_message.account.email)
    expect(page).not_to have_text(I18n.t("support.message.ai_badge"))
    expect(page).not_to have_css("[data-role='articles']")
  end

  describe "AI message" do
    it "shows the assistant name and AI badge without touching account" do
      expect(ai_message.account).to be_nil

      render_inline(described_class.new(message: ai_message))

      expect(page).to have_text(I18n.t("support.message.ai_name"))
      expect(page).to have_text(I18n.t("support.message.ai_badge"))
      expect(page).to have_css(".from-secondary-50")
      expect(page).not_to have_css("turbo-show[is]", text: I18n.t("support.message.edit"))
    end

    it "renders article cards linking to the help center in a new tab" do
      article = create(:article, :published, title: "Reset it", summary: "How to reset", slug: "reset-it")
      message = create(:message, :ai, conversation: conversation, metadata: {"article_ids" => [article.id], "resolution_proposed" => false})

      render_inline(described_class.new(message: message))

      expect(page).to have_css("a[target='_blank'][href*='/help/reset-it']", text: "Reset it")
      expect(page).to have_text("How to reset")
    end

    context "with a resolution proposed" do
      let(:ai_message) do
        create(:message, :ai, conversation: conversation, metadata: {"article_ids" => [], "resolution_proposed" => true})
      end

      it "renders both buttons behind a requester-only turbo-show" do
        render_inline(described_class.new(message: ai_message))

        expect(page).to have_css("turbo-show[when='current-user-id'][is='#{ticket.created_id}'] [data-resolution-actions]")
        expect(page).to have_css("a[data-turbo-method='post'][href*='/support/tickets/#{ticket.id}/resolve_with_ai']", text: I18n.t("support.message.solved"))
        expect(page).to have_css("a[data-turbo-method='post'][href*='/support/tickets/#{ticket.id}/request_human']", text: I18n.t("support.message.not_solved"))
      end

      it "renders no buttons while the assistant is analyzing" do
        ticket.update!(ai_state: :analyzing)
        render_inline(described_class.new(message: ai_message))

        expect(page).not_to have_css("[data-resolution-actions]")
      end

      it "renders no buttons when the ticket is no longer awaiting a resolution" do
        ticket.update!(ai_state: :off)
        render_inline(described_class.new(message: ai_message))

        expect(page).not_to have_css("[data-resolution-actions]")
      end
    end

    it "renders no buttons when the message did not propose a resolution" do
      render_inline(described_class.new(message: ai_message))

      expect(page).not_to have_css("[data-resolution-actions]")
    end
  end
end
