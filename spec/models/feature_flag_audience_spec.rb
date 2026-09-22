require "rails_helper"

RSpec.describe FeatureFlagAudience, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:feature_flag) }
    it { is_expected.to belong_to(:audience) }
  end

  describe "validations" do
    it "validates uniqueness of audience scoped to feature_flag" do
      flag = create(:feature_flag)
      audience = create(:audience)
      create(:feature_flag_audience, feature_flag: flag, audience: audience)

      duplicate = build(:feature_flag_audience, feature_flag: flag, audience: audience)
      expect(duplicate).not_to be_valid
    end

    it "allows the same audience on a different flag" do
      audience = create(:audience)
      create(:feature_flag_audience, audience: audience)

      expect(build(:feature_flag_audience, audience: audience)).to be_valid
    end
  end

  # Supports S31 (proven fully in Phase 2, once FeatureFlag.declared exists to
  # distinguish a retired flag from an undeclared row): the join row cascades
  # from the flag side (on_delete: :cascade) while an Audience#destroy is
  # blocked while any such row exists (see spec/models/audience_spec.rb) —
  # deleting a flag's join rows must never touch the audience itself.
  describe "cascade direction" do
    it "destroys the join row when its flag is destroyed, without touching the audience" do
      flag = create(:feature_flag)
      audience = create(:audience)
      join = create(:feature_flag_audience, feature_flag: flag, audience: audience)
      # FeatureFlag#destroy aborts unconditionally (defensive), so this
      # exercises the DB-level cascade directly.
      flag.feature_flag_audiences.delete_all

      expect { join.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(described_class.count).to eq(0)
      expect(audience.reload).to be_present
    end
  end
end
