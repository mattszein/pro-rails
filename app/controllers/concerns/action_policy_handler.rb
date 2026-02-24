# frozen_string_literal: true

module ActionPolicyHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActionPolicy::Unauthorized do |_ex|
      msg = I18n.t("adminit.authorization.unauthorized")

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = msg

          render turbo_stream: turbo_stream.update(
            "flashes_id",
            partial: "shared/flashes"
          )
        end

        format.html do
          redirect_back_or_to(root_path, alert: msg)
        end
      end
    end
  end
end
