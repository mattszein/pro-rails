require "rails_helper"

RSpec.describe PublishAnnouncementJob, type: :job do
  describe "#perform" do
    context "when announcement is scheduled and ready" do
      let(:announcement) { create(:announcement, :scheduled) }

      it "calls Announcements::Publish interactor" do
        expect(Announcements::Publish).to receive(:call).with(announcement: announcement).and_call_original

        described_class.new.perform(announcement.id, announcement.scheduled_at.to_i)
      end

      it "publishes the announcement" do
        expect { described_class.new.perform(announcement.id, announcement.scheduled_at.to_i) }
          .to change { announcement.reload.status }.from("scheduled").to("published")
      end
    end

    context "when announcement does not exist" do
      it "returns without publishing" do
        expect(Announcements::Publish).not_to receive(:call)

        described_class.new.perform(999999, Time.current.to_i)
      end
    end

    context "when announcement was rescheduled" do
      let(:announcement) { create(:announcement, :scheduled) }

      it "returns without publishing" do
        stale_scheduled_at = announcement.scheduled_at.to_i - 3600

        expect(Announcements::Publish).not_to receive(:call)

        described_class.new.perform(announcement.id, stale_scheduled_at)
      end
    end

    context "when announcement is no longer scheduled" do
      let(:announcement) { create(:announcement, :draft, scheduled_at: 1.day.from_now) }

      it "returns without publishing" do
        expect(Announcements::Publish).not_to receive(:call)

        described_class.new.perform(announcement.id, announcement.scheduled_at.to_i)
      end
    end

    context "when announcement is already published" do
      let(:announcement) { create(:announcement, :published) }

      it "returns without publishing" do
        expect(Announcements::Publish).not_to receive(:call)

        described_class.new.perform(announcement.id, announcement.scheduled_at.to_i)
      end
    end

    context "when Publish interactor fails" do
      let(:announcement) { create(:announcement, :scheduled) }

      it "logs the error" do
        allow(Announcements::Publish).to receive(:call).and_return(
          double(failure?: true, error: "Something went wrong")
        )

        expect(Rails.logger).to receive(:error).with(/PublishJob Failed for Announcement #{announcement.id}/)

        described_class.new.perform(announcement.id, announcement.scheduled_at.to_i)
      end
    end

    context "when Publish interactor succeeds" do
      let(:announcement) { create(:announcement, :scheduled) }

      it "logs success" do
        allow(Announcements::Publish).to receive(:call).and_return(
          double(failure?: false)
        )

        expect(Rails.logger).to receive(:info).with(/Published Announcement #{announcement.id} successfully/)

        described_class.new.perform(announcement.id, announcement.scheduled_at.to_i)
      end
    end
  end

  describe "job configuration" do
    it "is queued on the default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
