module FeatureFlags
  # A declared flag key. Display name/description are looked up as
  # translations (feature_flags.flags.<key>.name/.description).
  Flag = Data.define(:key)
end
