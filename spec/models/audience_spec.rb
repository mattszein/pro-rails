require "rails_helper"

RSpec.describe Audience, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:audience_conditions).dependent(:destroy) }
    it { is_expected.to have_many(:feature_flag_audiences) }
    it { is_expected.to have_many(:feature_flags).through(:feature_flag_audiences) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }

    it "validates uniqueness of name" do
      create(:audience, name: "Beta testers")
      expect(build(:audience, name: "Beta testers")).not_to be_valid
    end

    # S20 — an archived name cannot be reused.
    it "does not allow an archived audience's name to be reused" do
      create(:audience, :archived, name: "Beta testers")
      expect(build(:audience, name: "Beta testers")).not_to be_valid
    end

    # S26 — a name with every condition off is not saved.
    it "requires at least one condition" do
      audience = build(:audience, :without_condition)
      expect(audience).not_to be_valid
      expect(audience.errors[:base]).to include(
        I18n.t("activerecord.errors.models.audience.attributes.base.at_least_one_condition")
      )
    end

    it "is valid with at least one condition" do
      expect(build(:audience)).to be_valid
    end
  end

  describe "#destroy" do
    it "aborts while attached to a flag" do
      audience = create(:audience, :attached_to)
      expect { audience.destroy }.not_to change(described_class, :count)
    end

    it "succeeds when not attached to any flag" do
      audience = create(:audience)
      expect { audience.destroy }.to change(described_class, :count).by(-1)
    end
  end

  describe "scopes" do
    describe ".active / .archived" do
      it "splits on archived_at" do
        active = create(:audience)
        archived = create(:audience, :archived)

        expect(described_class.active).to include(active)
        expect(described_class.active).not_to include(archived)
        expect(described_class.archived).to include(archived)
        expect(described_class.archived).not_to include(active)
      end
    end

    describe ".attachable" do
      it "excludes archived audiences and audiences already attached to the flag" do
        flag = create(:feature_flag)
        attachable = create(:audience)
        already_attached = create(:audience, :attached_to, feature_flag: flag)
        archived = create(:audience, :archived)

        result = described_class.attachable(flag)

        expect(result).to include(attachable)
        expect(result).not_to include(already_attached, archived)
      end
    end

    describe ".with_flag_usage" do
      it "counts only declared flags — a retired flag's attachment counts as zero (S21)" do
        declared_flag = create(:feature_flag, key: "declared_for_usage")
        retired_flag = create(:feature_flag, key: "retired_for_usage")
        # Simulate the capability finishing: the key leaves the vocabulary.
        FeatureFlags::Registry.registry.delete(:retired_for_usage)

        audience = create(:audience)
        create(:feature_flag_audience, audience: audience, feature_flag: declared_flag)
        create(:feature_flag_audience, audience: audience, feature_flag: retired_flag)
        unattached = create(:audience)

        row = described_class.with_flag_usage.find(audience.id)
        expect(row.flag_usage_count.to_i).to eq(1)

        unattached_row = described_class.with_flag_usage.find(unattached.id)
        expect(unattached_row.flag_usage_count.to_i).to eq(0)
      end
    end
  end

  describe "#in_use? / #destroyable?" do
    it "is in use once attached to a flag" do
      audience = create(:audience, :attached_to)
      expect(audience).to be_in_use
      expect(audience).not_to be_destroyable
    end

    it "is not in use otherwise" do
      audience = create(:audience)
      expect(audience).not_to be_in_use
      expect(audience).to be_destroyable
    end
  end

  describe "#archived? / #archive! / #unarchive!" do
    it "toggles archived_at" do
      audience = create(:audience)
      expect(audience).not_to be_archived

      audience.archive!
      expect(audience.reload).to be_archived

      audience.unarchive!
      expect(audience.reload).not_to be_archived
    end
  end

  describe "#breadcrumb_title" do
    it "is the audience's name" do
      audience = create(:audience, name: "Beta testers")
      expect(audience.breadcrumb_title).to eq("Beta testers")
    end
  end

  describe "#matches?" do
    it "returns false when the account matches no condition (S3)" do
      audience = create(:audience) # default condition: adminit_users -> true
      unrolled_account = create(:account) # no role -> adminit_access? false

      expect(audience.matches?(unrolled_account)).to be false
    end

    it "requires every turned-on condition to hold (S10, S11)" do
      audience = build(:audience, :without_condition)
      audience.audience_conditions.build(condition_key: "verified_users", value: true)
      audience.audience_conditions.build(condition_key: "registration_age", value: {"amount" => 1, "unit" => "years"})
      audience.save!

      old_verified = create(:account, :verified, created_at: 2.years.ago)
      recent_verified = create(:account, :verified, created_at: 1.day.ago)

      expect(audience.matches?(old_verified)).to be true # S10 — both hold
      expect(audience.matches?(recent_verified)).to be false # S11 — age misses
    end

    # S29 — a condition the vocabulary no longer declares fails the whole
    # audience, not just that condition.
    it "returns false for the whole audience when it holds an unregistered condition_key" do
      audience = build(:audience, :without_condition)
      audience.audience_conditions.build(condition_key: "adminit_users", value: true)
      audience.save!
      # Simulate a condition whose key later left the vocabulary — bypass
      # validation the same way a retired condition would arrive in
      # production data.
      audience.audience_conditions.first.update_column(:condition_key, "retired_condition")

      account = create(:account, :with_role)
      expect(audience.reload.matches?(account)).to be false
    end

    it "returns false for an audience with no conditions (S25's conditionless state)" do
      audience = build(:audience, :without_condition)
      audience.audience_conditions.build(condition_key: "adminit_users", value: true)
      audience.save!
      audience.audience_conditions.destroy_all

      account = create(:account, :with_role)
      expect(audience.reload.matches?(account)).to be false
    end
  end

  describe ".prune_role" do
    it "removes the role id and drops the condition row when the list empties (S25)" do
      role = create(:role)
      audience = build(:audience, :without_condition)
      audience.audience_conditions.build(condition_key: "roles", value: [role.id])
      audience.save!

      described_class.prune_role(role.id)

      expect(audience.reload.audience_conditions).to be_empty
    end

    it "keeps the condition row when other roles remain selected" do
      keep_role = create(:role)
      remove_role = create(:role)
      audience = build(:audience, :without_condition)
      audience.audience_conditions.build(condition_key: "roles", value: [keep_role.id, remove_role.id])
      audience.save!

      described_class.prune_role(remove_role.id)

      condition = audience.reload.audience_conditions.sole
      expect(condition.value).to eq([keep_role.id])
    end

    it "does not veto the at-least-one-condition rule when it empties an audience" do
      role = create(:role)
      audience = build(:audience, :without_condition)
      audience.audience_conditions.build(condition_key: "roles", value: [role.id])
      audience.save!

      expect { described_class.prune_role(role.id) }.not_to raise_error
      expect(audience.reload).to be_persisted
      expect(audience.audience_conditions).to be_empty
    end
  end
end
