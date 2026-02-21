require "rails_helper"

RSpec.describe Announcements::Unschedule do
  describe ".call" do
    context "when announcement is scheduled" do
      let(:announcement) { create(:announcement, :scheduled) }

      it "succeeds" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_success
      end

      it "transitions announcement to draft" do
        expect { described_class.call(announcement: announcement) }
          .to change { announcement.reload.status }.from("scheduled").to("draft")
      end
    end

    context "when announcement is draft" do
      let(:announcement) { create(:announcement, :draft) }

      it "fails" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_failure
      end

      it "returns error message" do
        result = described_class.call(announcement: announcement)
        expect(result.error).to eq("Can only unschedule scheduled announcements")
      end
    end

    context "when announcement is published" do
      let(:announcement) { create(:announcement, :published) }

      it "fails" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_failure
      end

      it "returns error message" do
        result = described_class.call(announcement: announcement)
        expect(result.error).to eq("Can only unschedule scheduled announcements")
      end
    end
  end
end
