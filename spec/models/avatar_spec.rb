require "rails_helper"

RSpec.describe Avatar, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:profile) }
    it { is_expected.to have_one_attached(:image) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:kind).with_values(manual: 0, generated: 1) }
    it { is_expected.to define_enum_for(:status).with_values(draft: 0, generating: 1, completed: 2, failed: 3) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:kind) }
    it { is_expected.to validate_presence_of(:status) }

    context "when generated" do
      subject { build(:avatar, :generated) }

      it "validates presence of method" do
        subject.write_attribute(:method, nil)
        expect(subject).not_to be_valid
        expect(subject.errors[:method]).to be_present
      end

      it "validates presence of dna_version" do
        subject.dna_version = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:dna_version]).to be_present
      end
    end

    context "when completed" do
      it "requires image attached" do
        avatar = build(:avatar, status: :completed)
        expect(avatar).not_to be_valid
        expect(avatar.errors[:image]).to be_present
      end

      it "is valid with image attached" do
        avatar = create(:avatar, :with_image)
        expect(avatar.valid?).to be true
      end
    end
  end

  describe "scopes" do
    describe ".visible" do
      it "returns only visible avatars" do
        visible_avatar = create(:avatar, :with_image, visible: true)
        hidden_avatar = create(:avatar, :with_image, visible: false)

        expect(Avatar.visible).to include(visible_avatar)
        expect(Avatar.visible).not_to include(hidden_avatar)
      end
    end

    describe ".for_gallery" do
      it "returns completed avatars ordered by created_at desc" do
        older = create(:avatar, :with_image, status: :completed, created_at: 2.days.ago)
        newer = create(:avatar, :with_image, status: :completed, created_at: 1.day.ago)
        draft = create(:avatar, :generated)

        result = Avatar.for_gallery
        expect(result).to include(newer, older)
        expect(result).not_to include(draft)
        expect(result.first).to eq(newer)
      end
    end

    describe ".generated_today" do
      it "counts only generated kind with generating/completed status created today" do
        profile = create(:profile)
        manual = create(:avatar, :with_image, profile: profile, kind: :manual)
        old_gen = create(:avatar, :completed_generation, :with_image, profile: profile, created_at: 2.days.ago)
        today_gen = create(:avatar, :completed_generation, :with_image, profile: profile, created_at: Time.current)
        draft_gen = create(:avatar, :generated, profile: profile)

        result = Avatar.where(profile_id: profile.id).generated_today
        expect(result).to include(today_gen)
        expect(result).not_to include(manual, old_gen, draft_gen)
      end
    end
  end

  describe "transition methods" do
    describe "#start_generating!" do
      context "when draft and generated" do
        let(:avatar) { create(:avatar, :generated) }

        it "transitions to generating" do
          avatar.start_generating!
          expect(avatar.reload).to be_generating
        end
      end

      context "when not draft" do
        let(:avatar) { create(:avatar, :completed_generation, :with_image) }

        it "raises InvalidTransition" do
          expect { avatar.start_generating! }.to raise_error(Avatar::InvalidTransition)
        end
      end

      context "when manual" do
        let(:avatar) { create(:avatar, :with_image, kind: :manual, status: :draft) }

        it "raises InvalidTransition" do
          expect { avatar.start_generating! }.to raise_error(Avatar::InvalidTransition)
        end
      end
    end

    describe "#complete!" do
      context "when generating" do
        let(:avatar) { create(:avatar, :generating) }

        it "transitions to completed" do
          # Must attach image first for the state to be valid
          avatar.image.attach(
            io: Rails.root.join("spec/fixtures/files/avatar.png").open,
            filename: "avatar.png",
            content_type: "image/png"
          )
          avatar.complete!
          expect(avatar.reload).to be_completed
        end
      end

      context "when not generating" do
        let(:avatar) { create(:avatar, :with_image) }

        it "raises InvalidTransition" do
          expect { avatar.complete! }.to raise_error(Avatar::InvalidTransition)
        end
      end
    end

    describe "#fail!" do
      context "when generating" do
        let(:avatar) { create(:avatar, :generating) }

        it "transitions to failed" do
          avatar.fail!
          expect(avatar.reload).to be_failed
        end
      end

      context "when not generating" do
        let(:avatar) { create(:avatar, :with_image) }

        it "raises InvalidTransition" do
          expect { avatar.fail! }.to raise_error(Avatar::InvalidTransition)
        end
      end
    end
  end

  describe "query methods" do
    describe "#editable?" do
      it "returns true for draft generated avatars" do
        avatar = build(:avatar, :generated)
        expect(avatar.editable?).to be true
      end

      it "returns false for completed avatars" do
        avatar = build(:avatar, :with_image, status: :completed)
        expect(avatar.editable?).to be false
      end

      it "returns false for manual avatars" do
        avatar = build(:avatar, :with_image, kind: :manual, status: :draft)
        expect(avatar.editable?).to be false
      end
    end

    describe "#selectable?" do
      it "returns true for completed avatars" do
        avatar = build(:avatar, :with_image, status: :completed)
        expect(avatar.selectable?).to be true
      end

      it "returns false for draft avatars" do
        avatar = build(:avatar, :generated)
        expect(avatar.selectable?).to be false
      end
    end

    describe "#evolvable?" do
      it "returns true for completed generated avatars" do
        avatar = build(:avatar, :completed_generation, :with_image)
        expect(avatar.evolvable?).to be true
      end

      it "returns false for completed manual avatars" do
        avatar = build(:avatar, :with_image, kind: :manual)
        expect(avatar.evolvable?).to be false
      end

      it "returns false for draft generated avatars" do
        avatar = build(:avatar, :generated)
        expect(avatar.evolvable?).to be false
      end
    end
  end
end
