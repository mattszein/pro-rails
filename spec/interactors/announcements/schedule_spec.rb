require "rails_helper"

RSpec.describe Announcements::Schedule do
  describe ".call" do
    context "when announcement is schedulable" do
      let(:announcement) { create(:announcement, :draft, scheduled_at: 1.day.from_now) }

      it "succeeds" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_success
      end

      it "transitions announcement to scheduled" do
        expect { described_class.call(announcement: announcement) }
          .to change { announcement.reload.status }.from("draft").to("scheduled")
      end

      it "enqueues PublishAnnouncementJob" do
        expect { described_class.call(announcement: announcement) }
          .to have_enqueued_job(PublishAnnouncementJob)
          .with(announcement.id, announcement.scheduled_at.to_i)
      end

      it "schedules job for the correct time" do
        described_class.call(announcement: announcement)
        expect(PublishAnnouncementJob).to have_been_enqueued.at(announcement.scheduled_at)
      end
    end

    context "when announcement is already scheduled" do
      let(:announcement) { create(:announcement, :scheduled) }

      it "fails" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_failure
      end

      it "returns error message" do
        result = described_class.call(announcement: announcement)
        expect(result.error).to eq("Already scheduled")
      end

      it "does not enqueue job" do
        expect { described_class.call(announcement: announcement) }
          .not_to have_enqueued_job(PublishAnnouncementJob)
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
        expect(result.error).to eq("Cannot schedule a published announcement")
      end
    end

    context "when announcement has no scheduled_at" do
      let(:announcement) { create(:announcement, :draft, scheduled_at: nil) }

      it "fails" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_failure
      end

      it "returns error message" do
        result = described_class.call(announcement: announcement)
        expect(result.error).to eq("Scheduled time is required")
      end
    end

    context "when scheduled_at is in the past" do
      let(:announcement) { create(:announcement, :draft, scheduled_at: 1.day.from_now) }

      before { announcement.update_column(:scheduled_at, 10.minutes.ago) }

      it "fails" do
        result = described_class.call(announcement: announcement)
        expect(result).to be_failure
      end

      it "returns error message" do
        result = described_class.call(announcement: announcement)
        expect(result.error).to eq("Scheduled time must be in the future")
      end
    end
  end
end
