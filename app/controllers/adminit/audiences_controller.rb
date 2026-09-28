class Adminit::AudiencesController < Adminit::ApplicationController
  include Tableable

  before_action :set_audience, only: [:show, :edit, :update, :archive, :unarchive]
  verify_authorized

  def index
    authorize!
    @columns = helpers.audience_columns
    @pagy, @audiences = apply_table_params(Audience.with_flag_usage.order(:name), columns: @columns)
  end

  def show
  end

  def new
    authorize!
    @audience = Audience.new
    @audience.build_missing_conditions
  end

  def edit
    @audience.build_missing_conditions
  end

  def create
    authorize!
    @audience = Audience.new(audience_params)
    if @audience.save
      respond_saved(resource_message(:created, @audience))
    else
      respond_form_error(:new)
    end
  end

  def update
    if @audience.update(audience_params)
      respond_saved(resource_message(:updated, @audience))
    else
      respond_form_error(:edit)
    end
  end

  def archive
    @audience.archive!
    redirect_to adminit_audience_path(@audience), notice: t("adminit.audiences.archived")
  end

  def unarchive
    @audience.unarchive!
    redirect_to adminit_audience_path(@audience), notice: t("adminit.audiences.unarchived")
  end

  private

  # New/edit render inside a modal (Turbo Frame), same as announcements: the
  # turbo_stream branch redirects the frame's contents to the show page on
  # success, or re-renders the form in place on failure.
  def respond_saved(message)
    respond_to do |format|
      format.html { redirect_to adminit_audience_path(@audience), notice: message }
      format.turbo_stream do
        flash[:notice] = message
        render turbo_stream: turbo_stream.action(:redirect, adminit_audience_path(@audience))
      end
    end
  end

  def respond_form_error(template)
    @audience.build_missing_conditions
    respond_to do |format|
      format.html { render template, status: :unprocessable_content }
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "audience_form",
          partial: "adminit/audiences/form",
          locals: {audience: @audience}
        ), status: :unprocessable_content
      end
    end
  end

  def set_audience
    @audience = Audience.find(params[:id])
    authorize! @audience
  end

  def audience_params
    permitted = params.require(:audience).permit(:name, :description)
    permitted[:audience_conditions_attributes] = audience_conditions_params
    permitted
  end

  # Value shape (boolean / id array / {amount, unit}) depends on the
  # condition's declared type, so rows are permitted by registered
  # condition_key rather than a static `permit` shape.
  def audience_conditions_params
    rows = params[:audience][:audience_conditions_attributes]
    return [] if rows.blank?

    rows.to_unsafe_h.values.filter_map do |row|
      condition_key = row[:condition_key].presence
      next unless condition_key && AudienceConditions::Registry.registered?(condition_key)

      condition = AudienceConditions::Registry.fetch(condition_key)

      condition_row_attributes(condition, row)
    end
  end

  def condition_row_attributes(condition, row)
    enabled = ActiveModel::Type::Boolean.new.cast(row[:enabled])
    existing_id = row[:id].presence

    return existing_id ? {id: existing_id, _destroy: true} : nil unless enabled

    attrs = {condition_key: condition.key.to_s, value: cast_value(condition, row)}
    attrs[:id] = existing_id if existing_id
    attrs
  end

  def cast_value(condition, row)
    case condition.type
    when :boolean
      ActiveModel::Type::Boolean.new.cast(row[:value])
    when :affirmative
      true
    when :id_list
      Array(row[:value]).compact_blank.map(&:to_i)
    when :duration
      {"amount" => row.dig(:value, :amount), "unit" => row.dig(:value, :unit)}
    end
  end
end
