require "rails_helper"

describe "feature_flags:sync" do
  before(:all) { Rails.application.load_tasks }

  after { Rake::Task["feature_flags:sync"].reenable }

  it "materializes a row for a declared flag with none yet" do
    with_feature_flag(:brand_new_flag) do
      expect { Rake::Task["feature_flags:sync"].invoke }
        .to change { FeatureFlag.exists?(key: "brand_new_flag") }.from(false).to(true)
    end
  end
end
