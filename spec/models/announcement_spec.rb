require "rails_helper"

RSpec.describe Announcement, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:author).class_name("Account") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:body) }

    context "when status is scheduled" do
      let(:announcement) { build(:announcement, :scheduled) }

      it "requires scheduled_at" do
        announcement.scheduled_at = nil
        expect(announcement).not_to be_valid
        expect(announcement.errors[:scheduled_at]).to include("can't be blank")
      end

      it "validates scheduled_at is not in the past" do
        announcement.scheduled_at = 1.day.ago
        expect(announcement).not_to be_valid
        expect(announcement.errors[:scheduled_at]).to include("cannot be in the past")
      end

      it "allows scheduled_at in the future" do
        announcement.scheduled_at = 1.day.from_now
        expect(announcement).to be_valid
      end
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
  end

  describe "default scope" do
    let!(:old_announcement) { create(:announcement, created_at: 3.days.ago) }
    let!(:new_announcement) { create(:announcement, created_at: 1.day.ago) }
    let!(:middle_announcement) { create(:announcement, created_at: 2.days.ago) }

    it "orders by created_at desc" do
      expect(Announcement.all).to eq([new_announcement, middle_announcement, old_announcement])
    end
  end

  describe "business rule methods" do
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

    describe "#can_change_scheduled_at?" do
      it "returns true for draft announcements" do
        announcement = build(:announcement, :draft)
        expect(announcement.can_change_scheduled_at?).to be true
      end

      it "returns false for scheduled announcements" do
        announcement = build(:announcement, :scheduled)
        expect(announcement.can_change_scheduled_at?).to be false
      end

      it "returns false for published announcements" do
        announcement = build(:announcement, :published)
        expect(announcement.can_change_scheduled_at?).to be false
      end
    end

    describe "#can_transition_to_draft?" do
      it "returns true for draft announcements" do
        announcement = build(:announcement, :draft)
        expect(announcement.can_transition_to_draft?).to be true
      end

      it "returns true for scheduled announcements" do
        announcement = build(:announcement, :scheduled)
        expect(announcement.can_transition_to_draft?).to be true
      end

      it "returns false for published announcements" do
        announcement = build(:announcement, :published)
        expect(announcement.can_transition_to_draft?).to be false
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
        expect(announcement.errors[:scheduled_at]).to include("cannot be changed for scheduled announcements")
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
        expect(announcement.errors[:base]).to include("cannot be updated once published")
      end

      it "prevents any updates including status changes" do
        announcement.status = :draft
        expect(announcement).not_to be_valid
        expect(announcement.errors[:base]).to include("cannot be updated once published")
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

    it "does not prevent destroying scheduled announcements at model level" do
      announcement = create(:announcement, :scheduled)
      expect { announcement.destroy }.to change(Announcement, :count).by(-1)
    end

    it "does not prevent destroying published announcements at model level" do
      announcement = create(:announcement, :published)
      expect { announcement.destroy }.to change(Announcement, :count).by(-1)
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
