require "rails_helper"

RSpec.describe Support::AiStatusComponent, type: :component do
  def banner_text(ticket)
    render_inline(described_class.new(ticket: ticket))
    page.text.squish
  end

  it "shows the helping banner without the talk-to-person button while analyzing" do
    ticket = create(:ticket, :ai_analyzing)

    expect(banner_text(ticket)).to include(I18n.t("support.ticket_status_banner.ai_analyzing"))
    expect(page).not_to have_link(I18n.t("support.ai_status.talk_to_person"))
  end

  it "shows the helping banner and the button while awaiting the user" do
    ticket = create(:ticket, :ai_awaiting_user)

    expect(banner_text(ticket)).to include(I18n.t("support.ticket_status_banner.ai_awaiting_user"))
    expect(page).to have_css("turbo-show[is='#{ticket.created_id}'] a[data-turbo-method='post'][href*='/request_human']", text: I18n.t("support.ai_status.talk_to_person"))
  end

  it "shows the waiting banner without the button after a handoff request" do
    ticket = create(:ticket, :ai_handoff_requested)

    expect(banner_text(ticket)).to include(I18n.t("support.ticket_status_banner.ai_handoff_requested"))
    expect(page).not_to have_link(I18n.t("support.ai_status.talk_to_person"))
  end

  it "shows the resolved banner for an AI-resolved ticket" do
    ticket = create(:ticket, :ai_resolved)

    expect(banner_text(ticket)).to include(I18n.t("support.ticket_status_banner.ai_resolved"))
    expect(page).not_to have_link(I18n.t("support.ai_status.talk_to_person"))
  end

  it "renders only the empty wrapper when off or stepped back" do
    [create(:ticket), create(:ticket, :in_progress, ai_state: :stepped_back)].each do |ticket|
      render_inline(described_class.new(ticket: ticket))
      expect(page).to have_css("##{ActionView::RecordIdentifier.dom_id(ticket, :ai_status)}")
      expect(page).not_to have_css("[data-role='ai-status-banner']")
    end
  end
end
