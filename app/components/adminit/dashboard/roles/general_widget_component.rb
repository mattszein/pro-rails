module Adminit
  module Dashboard
    module Roles
      class GeneralWidgetComponent < ApplicationViewComponent
        SPAN_CLASS = "col-span-1"

        option :account

        def title
          I18n.t("adminit.dashboard_widgets.roles.general.title")
        end

        def roles
          @roles ||= ::RolesListQuery.call
        end
      end
    end
  end
end
