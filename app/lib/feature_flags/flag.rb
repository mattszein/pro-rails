module FeatureFlags
  # A declared flag key. Carries only the key — display name and description
  # are looked up as translations (feature_flags.flags.<key>.name/.description)
  # so the two translations and the key move together.
  Flag = Data.define(:key)
end
