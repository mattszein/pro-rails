module Adminit
  module FeatureFlags
    # Attach and detach — the access list is not a resource an operator is
    # permissioned for separately, so this authorizes the parent flag
    # (Adminit::FeatureFlagPolicy, to: :update?) rather than owning a policy
    # of its own. Each action is a single-row write with no side effect
    # beyond that row (TECH-PLAN §3.5) — no interactor, no stamp: the flag
    # carries no attribution column to coordinate.
    class AudiencesController < Adminit::ApplicationController
      before_action :set_feature_flag

      def create
        # Scoped to the same attach list the show page offers (S19):
        # active, not already attached. An archived or already-attached id
        # is rejected here too, not only omitted from the view.
        audience = Audience.attachable(@feature_flag).find(params[:audience_id])
        @feature_flag.feature_flag_audiences.find_or_create_by!(audience: audience)

        redirect_to adminit_feature_flag_path(@feature_flag), notice: t("adminit.feature_flags.audience_attached")
      rescue ActiveRecord::RecordInvalid => e
        redirect_to adminit_feature_flag_path(@feature_flag), alert: e.record.errors.full_messages.to_sentence
      end

      def destroy
        audience = @feature_flag.audiences.find(params[:id])
        @feature_flag.feature_flag_audiences.where(audience: audience).delete_all

        redirect_to adminit_feature_flag_path(@feature_flag), notice: t("adminit.feature_flags.audience_detached")
      end

      private

      def set_feature_flag
        @feature_flag = FeatureFlag.find(params[:feature_flag_id])
        authorize! @feature_flag, to: :update?, with: Adminit::FeatureFlagPolicy
      end
    end
  end
end
