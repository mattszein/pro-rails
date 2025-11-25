# frozen_string_literal: true

module RecordNotFoundHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |exception|
      msg = I18n.t("errors.record_not_found")

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = msg

          render turbo_stream: turbo_stream.update(
            "flashes_id",
            partial: "shared/flashes"
          ), status: :not_found
        end

        format.html do
          redirect_back fallback_location: root_path, alert: msg
        end

        format.json do
          render json: {error: msg}, status: :not_found
        end
      end
    end
  end
end
