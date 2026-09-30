class Adminit::FeatureFlagsController < Adminit::ApplicationController
  include Tableable

  before_action :set_feature_flag, only: [:audience_select, :attach_audience, :detach_audience, :account_select, :add_account, :remove_account]
  verify_authorized

  def index
    authorize!
    @columns = helpers.feature_flag_columns
    @pagy, @feature_flags = apply_table_params(
      FeatureFlag.declared.includes(:audiences, :account_entries),
      columns: @columns
    )
  end

  def show
    @feature_flag = FeatureFlag.includes(audiences: :audience_conditions, account_entries: :account).find(params[:id])
    authorize! @feature_flag
  end

  def audience_select
    @attachable_audiences = @feature_flag.attachable_audiences
  end

  def account_select
  end

  # Attach/detach an audience, allow/block an account — single-row writes on
  # the flag's own detail page, no interactor: no side effect beyond the row.

  def attach_audience
    audience = @feature_flag.attachable_audiences.find(params[:audience_id])
    @feature_flag.feature_flag_audiences.find_or_create_by!(audience: audience)

    redirect_to adminit_feature_flag_path(@feature_flag), notice: t("adminit.feature_flags.audience_attached")
  rescue ActiveRecord::RecordInvalid => e
    redirect_to adminit_feature_flag_path(@feature_flag), alert: e.record.errors.full_messages.to_sentence
  end

  def detach_audience
    @feature_flag.feature_flag_audiences.find_by!(audience_id: params[:audience_id]).destroy!

    redirect_to adminit_feature_flag_path(@feature_flag), notice: t("adminit.feature_flags.audience_detached")
  end

  def add_account
    account = Account.find(params[:account_id])
    entry = @feature_flag.account_entries.find_or_initialize_by(account: account)
    entry.access = params[:access]

    if entry.save
      redirect_to adminit_feature_flag_path(@feature_flag), notice: t("adminit.feature_flags.account_entry_added")
    else
      redirect_to adminit_feature_flag_path(@feature_flag), alert: entry.errors.full_messages.to_sentence
    end
  end

  def remove_account
    @feature_flag.account_entries.find_by!(account_id: params[:account_id]).destroy!

    redirect_to adminit_feature_flag_path(@feature_flag), notice: t("adminit.feature_flags.account_entry_removed")
  end

  private

  def set_feature_flag
    @feature_flag = FeatureFlag.find(params[:id])
    authorize! @feature_flag
  end
end
