require "rails_helper"

RSpec.describe Announcement, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:author).class_name("Account") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:body) }

    context "when status is scheduled" do
      subject { build(:announcement, :scheduled) }

      it { is_expected.to validate_presence_of(:scheduled_at) }
    end

    context "when status is not scheduled" do
      let(:announcement) { build(:announcement, :draft) }

      it "does not require scheduled_at" do
        announcement.scheduled_at = nil
        expect(announcement).to be_valid
      end
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, scheduled: 1, published: 2).backed_by_column_of_type(:integer) }
  end

  describe "scopes" do
    describe ".ready_to_publish" do
      let!(:scheduled_past) do
        announcement = create(:announcement, status: :scheduled, scheduled_at: 1.hour.from_now)
        announcement.update_column(:scheduled_at, 1.hour.ago)
        announcement
      end
      let!(:scheduled_future) { create(:announcement, status: :scheduled, scheduled_at: 1.hour.from_now) }
      let!(:draft) { create(:announcement, :draft) }
      let!(:published) { create(:announcement, :published) }

      it "returns only scheduled announcements with scheduled_at in the past" do
        expect(Announcement.ready_to_publish).to contain_exactly(scheduled_past)
      end
    end

    describe ".overdue" do
      let!(:overdue_announcement) do
        announcement = create(:announcement, status: :scheduled, scheduled_at: 1.hour.from_now)
        announcement.update_column(:scheduled_at, 10.minutes.ago)
        announcement
      end
      let!(:recent_scheduled) do
        announcement = create(:announcement, status: :scheduled, scheduled_at: 1.hour.from_now)
        announcement.update_column(:scheduled_at, 2.minutes.ago)
        announcement
      end
      let!(:draft) { create(:announcement, :draft) }

      it "returns scheduled announcements more than 5 minutes past scheduled_at" do
        expect(Announcement.overdue).to contain_exactly(overdue_announcement)
      end
    end

    describe ".ordered" do
      let!(:old_announcement) { create(:announcement, created_at: 3.days.ago) }
      let!(:new_announcement) { create(:announcement, created_at: 1.day.ago) }
      let!(:middle_announcement) { create(:announcement, created_at: 2.days.ago) }

      it "orders by created_at desc" do
        expect(Announcement.ordered).to eq([new_announcement, middle_announcement, old_announcement])
      end
    end
  end

  describe "state query methods" do
    describe "#schedulable?" do
      it "returns true for draft announcements with scheduled_at" do
        announcement = build(:announcement, :draft, scheduled_at: 1.day.from_now)
        expect(announcement.schedulable?).to be true
      end

      it "returns false for draft announcements without scheduled_at" do
        announcement = build(:announcement, :draft, scheduled_at: nil)
        expect(announcement.schedulable?).to be false
      end

      it "returns false for scheduled announcements" do
        announcement = build(:announcement, :scheduled)
        expect(announcement.schedulable?).to be false
      end

      it "returns false for published announcements" do
        announcement = build(:announcement, :published)
        expect(announcement.schedulable?).to be false
      end
    end

    describe "#scheduled_at_editable?" do
      it "returns true for draft announcements" do
        announcement = build(:announcement, :draft)
        expect(announcement.scheduled_at_editable?).to be true
      end

      it "returns false for scheduled announcements" do
        announcement = build(:announcement, :scheduled)
        expect(announcement.scheduled_at_editable?).to be false
      end

      it "returns false for published announcements" do
        announcement = build(:announcement, :published)
        expect(announcement.scheduled_at_editable?).to be false
      end
    end

    describe "#destroyable?" do
      it "returns true for draft announcements" do
        announcement = build(:announcement, :draft)
        expect(announcement.destroyable?).to be true
      end

      it "returns false for scheduled announcements" do
        announcement = build(:announcement, :scheduled)
        expect(announcement.destroyable?).to be false
      end

      it "returns false for published announcements" do
        announcement = build(:announcement, :published)
        expect(announcement.destroyable?).to be false
      end
    end

    describe "#editable?" do
      it "returns true for draft announcements" do
        announcement = build(:announcement, :draft)
        expect(announcement.editable?).to be true
      end

      it "returns true for scheduled announcements" do
        announcement = build(:announcement, :scheduled)
        expect(announcement.editable?).to be true
      end

      it "returns false for published announcements" do
        announcement = build(:announcement, :published)
        expect(announcement.editable?).to be false
      end
    end
  end

  describe "state transition methods" do
    describe "#schedule!" do
      context "when announcement is draft with valid scheduled_at" do
        let(:announcement) { create(:announcement, :draft, scheduled_at: 1.day.from_now) }

        it "transitions to scheduled status" do
          expect { announcement.schedule! }.to change { announcement.status }.from("draft").to("scheduled")
        end
      end

      context "when announcement is already published" do
        let(:announcement) { create(:announcement, :published) }

        it "raises InvalidTransition" do
          expect { announcement.schedule! }.to raise_error(Announcement::InvalidTransition, "Cannot schedule a published announcement")
        end
      end

      context "when announcement is already scheduled" do
        let(:announcement) { create(:announcement, :scheduled) }

        it "raises InvalidTransition" do
          expect { announcement.schedule! }.to raise_error(Announcement::InvalidTransition, "Already scheduled")
        end
      end

      context "when scheduled_at is nil" do
        let(:announcement) { create(:announcement, :draft, scheduled_at: nil) }

        it "raises InvalidTransition" do
          expect { announcement.schedule! }.to raise_error(Announcement::InvalidTransition, "Scheduled time is required")
        end
      end

      context "when scheduled_at is in the past beyond tolerance" do
        let(:announcement) { create(:announcement, :draft, scheduled_at: 1.day.from_now) }

        before do
          announcement.update_column(:scheduled_at, 10.minutes.ago)
        end

        it "raises InvalidTransition" do
          expect { announcement.schedule! }.to raise_error(Announcement::InvalidTransition, "Scheduled time must be in the future")
        end
      end

      context "when scheduled_at is within tolerance window" do
        let(:announcement) { create(:announcement, :draft, scheduled_at: 1.day.from_now) }

        before do
          announcement.update_column(:scheduled_at, 1.minute.ago)
        end

        it "allows scheduling" do
          expect { announcement.schedule! }.to change { announcement.status }.from("draft").to("scheduled")
        end
      end
    end

    describe "#unschedule!" do
      context "when announcement is scheduled" do
        let(:announcement) { create(:announcement, :scheduled) }

        it "transitions to draft status" do
          expect { announcement.unschedule! }.to change { announcement.status }.from("scheduled").to("draft")
        end
      end

      context "when announcement is not scheduled" do
        let(:announcement) { create(:announcement, :draft) }

        it "raises InvalidTransition" do
          expect { announcement.unschedule! }.to raise_error(Announcement::InvalidTransition, "Can only unschedule scheduled announcements")
        end
      end
    end

    describe "#publish!" do
      context "when announcement is scheduled" do
        let(:announcement) { create(:announcement, :scheduled) }

        it "transitions to published status" do
          expect { announcement.publish! }.to change { announcement.status }.from("scheduled").to("published")
        end

        it "sets published_at" do
          freeze_time do
            announcement.publish!
            expect(announcement.published_at).to eq(Time.current)
          end
        end
      end

      context "when announcement is already published" do
        let(:announcement) { create(:announcement, :published) }

        it "raises InvalidTransition" do
          expect { announcement.publish! }.to raise_error(Announcement::InvalidTransition, "Already published")
        end
      end

      context "when announcement is draft" do
        let(:announcement) { create(:announcement, :draft) }

        it "raises InvalidTransition" do
          expect { announcement.publish! }.to raise_error(Announcement::InvalidTransition, "Must be scheduled first")
        end
      end
    end
  end

  describe "update restrictions" do
    context "when announcement is scheduled" do
      let(:announcement) { create(:announcement, :scheduled) }

      it "prevents changing scheduled_at" do
        new_time = 2.days.from_now
        announcement.scheduled_at = new_time
        expect(announcement).not_to be_valid
        expect(announcement.errors[:scheduled_at]).to include("cannot be changed when scheduled. Unschedule first.")
      end

      it "allows updating other attributes" do
        announcement.title = "Updated Title"
        expect(announcement).to be_valid
      end
    end

    context "when announcement is published" do
      let(:announcement) { create(:announcement, :published) }

      it "prevents updating any attributes" do
        announcement.title = "Updated Title"
        expect(announcement).not_to be_valid
        expect(announcement.errors[:base]).to include("Cannot update a published announcement")
      end
    end

    context "when announcement is draft" do
      let(:announcement) { create(:announcement, :draft) }

      it "allows updating all attributes" do
        announcement.title = "Updated Title"
        announcement.body = "Updated Body"
        announcement.scheduled_at = 1.day.from_now
        expect(announcement).to be_valid
      end
    end
  end

  describe "destroy restrictions" do
    it "allows destroying draft announcements" do
      announcement = create(:announcement, :draft)
      expect { announcement.destroy }.to change(Announcement, :count).by(-1)
    end

    it "prevents destroying scheduled announcements" do
      announcement = create(:announcement, :scheduled)
      expect { announcement.destroy }.not_to change(Announcement, :count)
      expect(announcement.errors[:base]).to include("Only draft announcements can be deleted")
    end

    it "prevents destroying published announcements" do
      announcement = create(:announcement, :published)
      expect { announcement.destroy }.not_to change(Announcement, :count)
      expect(announcement.errors[:base]).to include("Only draft announcements can be deleted")
    end
  end

  describe "#scheduled_at= custom setter" do
    let(:announcement) { build(:announcement) }

    it "parses string date in MM/DD/YYYY HH:MM AM/PM format" do
      announcement.scheduled_at = "12/25/2025 03:30 PM"
      expect(announcement.scheduled_at).to eq(DateTime.new(2025, 12, 25, 15, 30))
    end

    it "accepts DateTime objects directly" do
      time = 1.day.from_now
      announcement.scheduled_at = time
      expect(announcement.scheduled_at).to be_within(1.second).of(time)
    end

    it "sets nil for invalid date strings" do
      announcement.scheduled_at = "invalid date"
      expect(announcement.scheduled_at).to be_nil
    end
  end
end
