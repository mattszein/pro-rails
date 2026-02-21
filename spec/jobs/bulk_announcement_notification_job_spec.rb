require "rails_helper"

RSpec.describe BulkAnnouncementNotificationJob, type: :job do
  describe "#perform" do
    context "when announcement does not exist" do
      it "returns without delivering notifications" do
        expect(AnnouncementNotifier).not_to receive(:with)

        described_class.new.perform(999999)
      end
    end

    context "when announcement exists" do
      let(:announcement) { create(:announcement, :published) }

      it "delivers to all verified accounts" do
        announcement # force creation
        create_list(:account, 2, :verified)
        create(:account) # unverified
        expected_count = Account.verified.count

        expect { described_class.new.perform(announcement.id) }
          .to change(Noticed::Notification, :count).by(expected_count)
      end

      it "skips unverified accounts" do
        unverified = create(:account)

        described_class.new.perform(announcement.id)

        expect(unverified.notifications.last).to be_nil
      end

      it "creates notifications linked to the announcement" do
        recipient = create(:account, :verified)

        described_class.new.perform(announcement.id)

        notification = recipient.notifications.last
        expect(notification.event.record).to eq(announcement)
      end

      it "skips already-notified accounts" do
        already_notified = create(:account, :verified)
        not_yet_notified = create(:account, :verified)

        AnnouncementNotifier.with(record: announcement, message: announcement.title)
          .deliver(already_notified)

        expect { described_class.new.perform(announcement.id) }
          .to change(Noticed::Notification, :count).by(1)
          .and(change { not_yet_notified.notifications.count }.by(1))
      end
    end
  end

  describe "job configuration" do
    it "is queued on the notifications queue" do
      expect(described_class.new.queue_name).to eq("notifications")
    end
  end
end
