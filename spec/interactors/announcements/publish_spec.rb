require "rails_helper"

RSpec.describe Announcements::Publish do
  describe ".call" do
    context "when announcement is scheduled" do
      let(:announcement) { create(:announcement, :scheduled) }

      it "succeeds" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_success
      end

      it "transitions announcement to published" do
        expect { described_class.call(announcement: announcement) }
          .to change { announcement.reload.status }.from("scheduled").to("published")
      end

      it "sets published_at" do
        freeze_time do
          described_class.call(announcement: announcement)
          expect(announcement.reload.published_at).to eq(Time.current)
        end
      end
    end

    context "when announcement is already published" do
      let(:announcement) { create(:announcement, :published) }

      it "fails" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_failure
      end

      it "returns error message" do
        result = described_class.call(announcement: announcement)
        expect(result.error).to eq("Already published")
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
        expect(result.error).to eq("Must be scheduled first")
      end
    end
  end
end
