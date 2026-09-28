# Declares every feature flag. Autoloaded (not an initializer) so edits
# hot-reload in development via config/initializers/feature_flags.rb.
#
# `test_feature_flag` is a working example wired end-to-end (seeded audience,
# gated dashboard message) — teams add their own `Registry.register(:key)`
# calls the same way when they adopt the feature.
module FeatureFlags
  module Flags
    module_function

    def install
      Registry.reset!
      Registry.register(:test_feature_flag)
    end
  end
end
