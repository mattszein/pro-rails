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
end
