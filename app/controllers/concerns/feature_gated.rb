# The single entry point Consumption uses to reach Decision. Included once
# on SharedBaseController so both user-facing and admin sides resolve
# `feature_enabled?` in controllers and views.
module FeatureGated
  extend ActiveSupport::Concern

  included do
    helper_method :feature_enabled?
  end

  # Memoized per request — an instance variable, discarded with the controller.
  def feature_flags
    @feature_flags ||= FeatureFlags.for(current_account)
  end

  def feature_enabled?(key)
    feature_flags.enabled?(key)
  end

  # A gated address looks exactly like one that doesn't exist.
  def require_feature!(key)
    raise ActionController::RoutingError, "Not Found" unless feature_enabled?(key)
  end
end
