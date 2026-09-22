class Adminit::FeatureFlagsController < Adminit::ApplicationController
  include Tableable

  before_action :set_feature_flag, only: [:show]
  verify_authorized

  def index
    authorize!
    FeatureFlag.materialize_declared!
    @columns = helpers.feature_flag_columns
    @pagy, @feature_flags = apply_table_params(
      FeatureFlag.declared.includes(:audiences, :account_entries),
      columns: @columns
    )
  end

  def show
    @attachable_audiences = Audience.attachable(@feature_flag)
  end

  private

  def set_feature_flag
    @feature_flag = FeatureFlag.find(params[:id])
    authorize! @feature_flag, to: :update?
  end
end
