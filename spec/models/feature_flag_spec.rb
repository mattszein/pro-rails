require "rails_helper"

RSpec.describe FeatureFlag, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:feature_flag_audiences).dependent(:delete_all) }
    it { is_expected.to have_many(:audiences).through(:feature_flag_audiences) }
    it { is_expected.to have_many(:account_entries).class_name("FeatureFlagAccount").dependent(:delete_all) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:key) }

    it "validates uniqueness of key" do
      create(:feature_flag, key: "dup_key")
      expect(build(:feature_flag, key: "dup_key")).not_to be_valid
    end

    it "requires the key to be registered" do
      flag = build(:feature_flag, key: "never_registered", auto_register: false)
      expect(flag).not_to be_valid
      expect(flag.errors[:key]).to be_present
    end
  end

  describe "#grants?" do
    it "denies when blocked, even with a matching audience" do
      flag = create(:feature_flag)
      account = create(:account, :with_role)
      create(:feature_flag_audience, feature_flag: flag, audience: create(:audience))
      create(:feature_flag_account, :blocked, feature_flag: flag, account: account)

      expect(flag.grants?(account)).to be false
    end

    it "allows when explicitly allowed, even without a matching audience" do
      flag = create(:feature_flag)
      account = create(:account)
      create(:feature_flag_account, :allowed, feature_flag: flag, account: account)

      expect(flag.grants?(account)).to be true
    end

    it "allows when any attached audience matches" do
      flag = create(:feature_flag)
      account = create(:account, :with_role)
      non_matching = build(:audience, :without_condition)
      non_matching.audience_conditions.build(condition_key: "verified_users", value: true)
      non_matching.save!
      matching = create(:audience) # default: adminit_users -> true
      create(:feature_flag_audience, feature_flag: flag, audience: non_matching)
      create(:feature_flag_audience, feature_flag: flag, audience: matching)

      expect(flag.grants?(account)).to be true
    end

    it "denies otherwise" do
      flag = create(:feature_flag)
      account = create(:account, :with_role)

      expect(flag.grants?(account)).to be false
    end
  end

  describe "#open_access?" do
    let(:flag) { create(:feature_flag) }

    it "is true with an attached audience" do
      create(:feature_flag_audience, feature_flag: flag, audience: create(:audience))
      expect(flag.reload).to be_open_access
    end

    it "is true with an allowed account entry" do
      create(:feature_flag_account, :allowed, feature_flag: flag)
      expect(flag.reload).to be_open_access
    end

    it "is false with nothing attached or only a blocked entry" do
      expect(flag).not_to be_open_access
      create(:feature_flag_account, :blocked, feature_flag: flag)
      expect(flag.reload).not_to be_open_access
    end
  end

  describe "#attachable_audiences" do
    it "excludes archived audiences and audiences already attached to the flag" do
      flag = create(:feature_flag)
      attachable = create(:audience)
      already_attached = create(:audience, :attached_to, feature_flag: flag)
      archived = create(:audience, :archived)

      result = flag.attachable_audiences

      expect(result).to include(attachable)
      expect(result).not_to include(already_attached, archived)
    end
  end

  describe "#display_name / #description / #breadcrumb_title" do
    it "translates the key through feature_flags.flags.<key>.name/.description" do
      flag = create(:feature_flag, key: "new_dashboard")
      I18n.backend.store_translations(:en, feature_flags: {flags: {new_dashboard: {name: "New dashboard", description: "The redesigned dashboard."}}})

      expect(flag.display_name).to eq("New dashboard")
      expect(flag.description).to eq("The redesigned dashboard.")
      expect(flag.breadcrumb_title).to eq("New dashboard")
    end

    it "falls back to the raw key/nil when no translation exists" do
      flag = create(:feature_flag, key: "untranslated_flag")
      expect(flag.display_name).to eq("untranslated_flag")
      expect(flag.description).to be_nil
    end
  end

  describe "#destroy" do
    it "always aborts" do
      flag = create(:feature_flag)
      expect { flag.destroy }.not_to change(described_class, :count)
    end
  end

  describe "scopes" do
    describe ".search_key" do
      it "matches a partial, case-insensitive key" do
        matching = create(:feature_flag, key: "new_dashboard")
        create(:feature_flag, key: "other_thing")

        expect(described_class.search_key("dash")).to contain_exactly(matching)
      end
    end

    describe ".open_access / .empty_access / .by_access_state" do
      it "counts a flag with an attached audience as open" do
        flag = create(:feature_flag)
        audience = create(:audience)
        create(:feature_flag_audience, feature_flag: flag, audience: audience)

        expect(described_class.open_access).to include(flag)
        expect(described_class.empty_access).not_to include(flag)
      end

      it "counts a flag with an allowed account entry as open" do
        flag = create(:feature_flag)
        create(:feature_flag_account, :allowed, feature_flag: flag)

        expect(described_class.open_access).to include(flag)
      end

      it "does not count a flag holding only blocked entries as open" do
        flag = create(:feature_flag)
        create(:feature_flag_account, :blocked, feature_flag: flag)

        expect(described_class.open_access).not_to include(flag)
        expect(described_class.empty_access).to include(flag)
      end

      it "counts a flag with no access-list rows as empty" do
        flag = create(:feature_flag)

        expect(described_class.empty_access).to include(flag)
        expect(described_class.open_access).not_to include(flag)
      end

      it "by_access_state delegates to open/empty" do
        open_flag = create(:feature_flag)
        create(:feature_flag_account, :allowed, feature_flag: open_flag)
        empty_flag = create(:feature_flag)

        expect(described_class.by_access_state("open")).to contain_exactly(open_flag)
        expect(described_class.by_access_state("empty")).to contain_exactly(empty_flag)
        expect(described_class.by_access_state(nil)).to contain_exactly(open_flag, empty_flag)
      end
    end
  end

  describe ".declared" do
    it "includes only rows whose key the registry currently declares" do
      declared_flag = create(:feature_flag, key: "declared_flag")
      retired_flag = create(:feature_flag, key: "retired_flag")
      FeatureFlags::Registry.registry.delete(:retired_flag) # simulate retirement

      expect(described_class.declared).to contain_exactly(declared_flag)
      expect(described_class.declared).not_to include(retired_flag)
    end
  end

  describe ".materialize_declared!" do
    it "inserts a row for every declared key that has none" do
      with_feature_flag(:brand_new_flag) do
        expect { described_class.materialize_declared! }
          .to change { described_class.exists?(key: "brand_new_flag") }.from(false).to(true)
      end
    end

    it "does not duplicate a row for a key that already exists" do
      create(:feature_flag, key: "already_there")

      with_feature_flag(:already_there) do
        expect { described_class.materialize_declared! }
          .not_to change(described_class, :count)
      end
    end
  end
end
