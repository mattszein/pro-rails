module Settings
  class AvatarsController < BaseController
    before_action :require_account
    before_action :set_avatar, only: [:show, :update, :generate, :select, :evolve, :toggle_visibility]
    verify_authorized
    helper_method :wizard_step_component

    def index
      authorize! Avatar, with: Settings::AvatarPolicy
      @avatars = current_account.profile.avatars
        .includes(image_attachment: :blob)
        .for_gallery
      @in_progress_avatars = current_account.profile.avatars
        .where(status: [:draft, :generating, :failed])
        .order(created_at: :desc)
    end

    def new
      authorize! Avatar, with: Settings::AvatarPolicy
    end

    def create
      authorize! Avatar, with: Settings::AvatarPolicy

      if params.dig(:avatar, :image).present?
        handle_manual_upload
      else
        handle_wizard_start
      end
    end

    def show
      authorize! @avatar, with: Settings::AvatarPolicy
      if @avatar.draft? && @avatar.generated?
        @avatar.generation_method
        max_step = @avatar.max_wizard_step
        step = params[:step].to_i
        @wizard_step = (1..max_step).cover?(step) ? step.to_s : nil
      end
    end

    def update
      authorize! @avatar, with: Settings::AvatarPolicy

      unless @avatar.draft?
        render turbo_stream: turbo_stream.update(
          "avatar_wizard_step",
          html: helpers.content_tag(:p, t("avatars.errors.not_editable"), class: "text-red-500")
        ), status: :unprocessable_content
        return
      end

      dna_update = normalize_dna_params
      next_step = params[:next_step]

      new_dna = if freeform_spark_changed?(dna_update)
        downstream = %w[mood_board_prompts mood_board_selected style_suggestions
          style_choice concepts concept_choice]
        @avatar.dna.except(*downstream).merge(dna_update)
      else
        @avatar.dna.merge(dna_update)
      end

      @avatar.update!(dna: new_dna)

      if @avatar.generation_method == "freeform" && next_step.present?
        enqueue_freeform_content_generation(next_step)
        @avatar.reload
      end

      html = if next_step.present?
        render_to_string(wizard_step_component(@avatar.generation_method, next_step))
      else
        render_to_string(Settings::AvatarWizard::StepReviewComponent.new(avatar: @avatar))
      end

      render turbo_stream: turbo_stream.update("avatar_wizard_step", html: html)
    rescue ActiveRecord::RecordInvalid => e
      render turbo_stream: turbo_stream.update(
        "avatar_wizard_step",
        html: helpers.content_tag(:p, e.message, class: "text-red-500")
      ), status: :unprocessable_content
    end

    def generate
      authorize! @avatar, with: Settings::AvatarPolicy

      was_failed = @avatar.failed?

      result = Avatars::Generate.call(
        avatar: @avatar,
        image_model: params[:image_model]
      )

      if result.success?
        generating_html = view_context.render(Settings::AvatarWizard::GeneratingComponent.new(avatar: @avatar))
        if was_failed
          render turbo_stream: turbo_stream.replace(
            ActionView::RecordIdentifier.dom_id(@avatar, "result"),
            html: generating_html
          )
        else
          render turbo_stream: turbo_stream.update("avatar_wizard_step", html: generating_html)
        end
      elsif result.rate_limited
        redirect_to settings_avatars_path,
          alert: t("avatars.errors.rate_limit_exceeded")
      else
        redirect_to settings_avatars_path, alert: result.error
      end
    end

    def select
      authorize! @avatar, with: Settings::AvatarPolicy

      result = Avatars::Select.call(
        avatar: @avatar,
        profile: current_account.profile
      )

      if result.success?
        redirect_to edit_settings_profile_path,
          notice: t("avatars.select.success")
      else
        redirect_to settings_avatars_path, alert: result.error
      end
    end

    def evolve
      authorize! @avatar, with: Settings::AvatarPolicy

      result = Avatars::Evolve.call(avatar: @avatar)

      if result.success?
        redirect_to settings_avatar_path(result.avatar),
          notice: t("avatars.evolve.success")
      elsif result.rate_limited
        redirect_to settings_avatars_path,
          alert: t("avatars.errors.rate_limit_exceeded")
      else
        redirect_to settings_avatars_path, alert: result.error
      end
    end

    def toggle_visibility
      authorize! @avatar, with: Settings::AvatarPolicy

      @avatar.update!(visible: !@avatar.visible)

      render turbo_stream: turbo_stream.replace(
        ActionView::RecordIdentifier.dom_id(@avatar, "visibility"),
        partial: "settings/avatars/visibility_toggle",
        locals: {avatar: @avatar}
      )
    end

    private

    def set_avatar
      @avatar = current_account.profile.avatars.find(params[:id])
    end

    def normalize_dna_params
      params.require(:avatar).permit(
        dna: [:style, :archetype, :color_mood, :mood, :background,
          :spark_text, :text_model, :style_choice, :concept_choice, :color_preference,
          elements: [], custom_colors: [], mood_board_selected: []]
      ).fetch(:dna, {})
    end

    def handle_manual_upload
      result = Avatars::Upload.call(
        profile: current_account.profile,
        image_file: params[:avatar][:image]
      )

      if result.success?
        redirect_to edit_settings_profile_path,
          notice: t("avatars.upload.success")
      else
        redirect_to edit_settings_profile_path, alert: result.error
      end
    end

    def freeform_spark_changed?(dna_update)
      @avatar.generation_method == "freeform" &&
        dna_update["spark_text"].present? &&
        dna_update["spark_text"] != @avatar.dna["spark_text"]
    end

    def enqueue_freeform_content_generation(next_step)
      return unless %w[2 3 4].include?(next_step)
      Avatars::GenerateFreeformContentJob.perform_later(@avatar.id, next_step)
    end

    def handle_wizard_start
      generation_method = params.dig(:avatar, :method)
      unless %w[guided freeform].include?(generation_method)
        redirect_to new_settings_avatar_path, alert: t("avatars.errors.invalid_method")
        return
      end

      method_int = Avatar::Generatable::METHODS[generation_method]
      avatar = current_account.profile.avatars.create!(
        kind: :generated,
        status: :draft,
        method: method_int,
        dna_version: 1,
        dna: {}
      )

      redirect_to settings_avatar_path(avatar)
    end

    def wizard_step_component(method_name, step)
      config = Settings::AvatarWizard::StepConfig.for(method_name, step)
      Settings::AvatarWizard::StepConfig.component_class(config).new(avatar: @avatar, config: config)
    end
  end
end
