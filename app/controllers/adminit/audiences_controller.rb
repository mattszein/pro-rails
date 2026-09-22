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
    seed_condition_rows(@audience)
  end

  def edit
    seed_condition_rows(@audience)
  end

  def create
    authorize!
    @audience = Audience.new(audience_params)
    if @audience.save
      redirect_to adminit_audience_path(@audience), notice: resource_message(:created, @audience)
    else
      seed_condition_rows(@audience)
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @audience.update(audience_params)
      redirect_to adminit_audience_path(@audience), notice: resource_message(:updated, @audience)
    else
      seed_condition_rows(@audience)
      render :edit, status: :unprocessable_content
    end
  end

  # Archiving/unarchiving is a single-field update on the model — no
  # interactor, no touch on the flags that attach this audience (S18, S23).
  def archive
    @audience.archive!
    redirect_to adminit_audience_path(@audience), notice: t("adminit.audiences.archived")
  end

  def unarchive
    @audience.unarchive!
    redirect_to adminit_audience_path(@audience), notice: t("adminit.audiences.unarchived")
  end

  private

  def set_audience
    @audience = Audience.find(params[:id])
    # `authorize!` with no explicit rule infers it from action_name
    # (show?/update?/archive?/unarchive?), which resolves through
    # ActionPolicy's default_rule to manage? the same as every other rule
    # this policy is asked about.
    authorize! @audience
  end

  # Every registry entry gets a row on the form, even if this audience does
  # not hold that condition yet — an on/off toggle needs something to
  # toggle. Adding a condition to the vocabulary adds no view code: the next
  # entry just appears here.
  def seed_condition_rows(audience)
    existing_keys = audience.audience_conditions.map(&:condition_key)
    # Not an ActiveRecord relation — Registry.all is an in-memory array.
    AudienceConditions::Registry.all.each do |condition| # rubocop:disable Rails/FindEach
      next if existing_keys.include?(condition.key.to_s)
      audience.audience_conditions.build(condition_key: condition.key.to_s)
    end
  end

  def audience_params
    permitted = params.require(:audience).permit(:name, :description)
    permitted[:audience_conditions_attributes] = condition_attributes
    permitted
  end

  # The value column's shape (boolean / id array / {amount, unit} hash)
  # depends on the condition's declared type, which Rails' strong
  # parameters cannot express as a single static `permit` shape — TECH-PLAN
  # §8 unknown #11. Each row is read from the known, registry-declared
  # condition_key rather than trusted blindly, so this is not a params
  # blind spot: an unrecognized condition_key is simply dropped, and every
  # value still passes through AudienceCondition's own vocabulary
  # validation on save.
  def condition_attributes
    rows = params[:audience][:audience_conditions_attributes]
    return [] if rows.blank?

    # `to_unsafe_h` is the sanctioned escape hatch here, not a blind mass
    # assignment: every field below is read by its known name, condition_key
    # is checked against the registry before anything else is trusted, and
    # the reconstructed value still passes AudienceCondition's own
    # vocabulary validation on save.
    rows.to_unsafe_h.values.filter_map do |row|
      condition_key = row[:condition_key].presence
      next unless condition_key && AudienceConditions::Registry.registered?(condition_key)

      condition = AudienceConditions::Registry.fetch(condition_key)

      shape_condition_row(condition, row)
    end
  end

  def shape_condition_row(condition, row)
    enabled = ActiveModel::Type::Boolean.new.cast(row[:enabled])
    existing_id = row[:id].presence

    return existing_id ? {id: existing_id, _destroy: true} : nil unless enabled

    attrs = {condition_key: condition.key.to_s, value: shape_value(condition, row)}
    attrs[:id] = existing_id if existing_id
    attrs
  end

  def shape_value(condition, row)
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
