module Adminit
  module Dashboard
    module Announcements
      class GeneralWidgetComponent < ApplicationViewComponent
        option :account

        def list_title
          I18n.t("adminit.dashboard_widgets.announcements.general.list_title")
        end

        def announcements
          @announcements ||= Announcement.scheduled.order(scheduled_at: :asc).limit(5)
        end

        def view_all_path
          helpers.adminit_announcements_path
        end

        def view_all_label
          I18n.t("adminit.dashboard_widgets.announcements.general.view_all")
        end

        def stats
          @stats ||= ::AnnouncementStatsQuery.call
        end

        def chart_height
          Adminit::DashboardHelper::CHART_HEIGHT
        end

        def chart_options
          ::Dashboard::ChartOptions.radial_bar_multiple(
            labels: status_labels,
            series: status_percentages,
            semantic_colors: ["success", "info", "warning"],
            total_label: I18n.t("shared.labels.total"),
            total_value: stats[:total]
          )
        end

        private

        def status_counts
          [stats[:published], stats[:scheduled], stats[:draft]]
        end

        def status_labels
          [
            "#{I18n.t("enums.announcement.status.published")} (#{stats[:published]})",
            "#{I18n.t("enums.announcement.status.scheduled")} (#{stats[:scheduled]})",
            "#{I18n.t("enums.announcement.status.draft")} (#{stats[:draft]})"
          ]
        end

        def status_percentages
          total = stats[:total].to_f
          return [0, 0, 0] if total.zero?

          status_counts.map { |count| (count / total * 100).round }
        end
      end
    end
  end
end
