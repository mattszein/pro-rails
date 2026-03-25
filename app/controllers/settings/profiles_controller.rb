module Settings
  class ProfilesController < BaseController
    before_action :set_profile
    verify_authorized

    def edit
      authorize! @profile
    end

    def update
      authorize! @profile

      if @profile.update(profile_params)
        redirect_to edit_settings_profile_path, notice: t("settings.profiles.update.success")
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def set_profile
      @profile = current_account.profile || current_account.create_profile!
    end

    def profile_params
      params.require(:profile).permit(:username, :bio, :avatar)
    end
  end
end
