class Settings::BaseController < DashboardController
  before_action :set_settings_submenu

  private

  def set_settings_submenu
    vc = view_context

    vc.content_for :subnav do
      vc.render Core::SubmenuComponent.new(
        current_section: "profile"
      )
    end
  end
end
