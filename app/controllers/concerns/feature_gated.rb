# frozen_string_literal: true

# The single entry point Consumption uses to reach Decision (TECH-PLAN §3.4,
# §9). Included once on SharedBaseController so both the user-facing and
# admin sides resolve `feature_enabled?` in controllers and views.
module FeatureGated
  extend ActiveSupport::Concern

  included do
    helper_method :feature_enabled?
  end

  # Memoized for the life of the request — an ordinary instance variable, so
  # its lifetime is the controller object's and nothing has to clear it
  # between requests. Never hold this anywhere that outlives the request.
  def feature_flags
    @feature_flags ||= FeatureFlags.for(current_account)
  end

  def feature_enabled?(key)
    feature_flags.enabled?(key)
  end

  # Raises the application's existing not-found handling, so a gated address
  # is indistinguishable from one that does not exist (S1) — denied means
  # the capability is absent, including by direct address.
  def require_feature!(key)
    raise ActiveRecord::RecordNotFound unless feature_enabled?(key)
  end
end
