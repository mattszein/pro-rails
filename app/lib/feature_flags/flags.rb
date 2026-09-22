# Declares every feature flag. Lives in the autoload path (not an
# initializer) so edits are picked up by code reloading in development: the
# `to_prepare` hook in config/initializers/feature_flags.rb calls `install`
# again with the reloaded class.
#
# Ships with no registrations — teams add `FeatureFlags::Registry.register(...)`
# calls when they adopt the feature.
module FeatureFlags
  module Flags
    module_function

    def install
      Registry.reset!
      Registry.register(:new_dashboard)
    end
  end
end
