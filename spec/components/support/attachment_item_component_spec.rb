require "rails_helper"

RSpec.describe Support::AttachmentItemComponent, type: :component do
  def blob(filename:, content_type:, body:)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(body), filename: filename, content_type: content_type
    )
  end

  context "with a non-image file (e.g. a PDF)" do
    let(:attachment) { blob(filename: "invoice.pdf", content_type: "application/pdf", body: "%PDF-1.4") }

    it "renders a document icon, the filename and the size, without an <img>" do
      render_inline(described_class.new(attachment: attachment))

      expect(page).to have_css("a[target='_blank'] svg")
      expect(page).to have_text("invoice.pdf")
      expect(page).to have_text("8 Bytes")
      expect(page).not_to have_css("img")
    end

    it "links to the blob download" do
      render_inline(described_class.new(attachment: attachment))

      expect(page).to have_css("a[href*='/rails/active_storage/blobs/'][href*='invoice.pdf']")
    end
  end

  context "with an image" do
    let(:attachment) do
      blob(filename: "avatar.png", content_type: "image/png", body: Rails.root.join("spec/fixtures/files/avatar.png").binread)
    end

    it "renders a thumbnail instead of the document icon" do
      render_inline(described_class.new(attachment: attachment))

      expect(page).to have_css("img")
      expect(page).not_to have_css("svg")
    end
  end
end
