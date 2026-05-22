require "rails/generators"

module ProRails
  module Generators
    class DashboardWidgetGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      argument :kinds, type: :array, default: ["general"], banner: "kind1 kind2 kind3"

      def create_component_files
        kinds.each do |kind|
          template "widget_component.rb.tt",
            "app/components/adminit/dashboard/#{file_name}/#{kind}_widget_component.rb"
          template "widget_component.html.erb.tt",
            "app/components/adminit/dashboard/#{file_name}/#{kind}_widget_component.html.erb"
        end
      end

      def create_query_objects
        template "query_object.rb.tt", "app/queries/#{file_name}_stats_query.rb"
      end

      def append_registry_entries
        kinds.each do |kind|
          registry_entry = <<~RUBY

            Dashboard::WidgetRegistry.register(
              key: :#{file_name}_#{kind}, resource: :#{file_name.singularize}, kind: :#{kind},
              policy_class: "Adminit::#{class_name.singularize}Policy",
              component_class: "Adminit::Dashboard::#{class_name.pluralize}::#{kind.camelize}WidgetComponent",
              turbo_frame_id: "dashboard_#{file_name}_#{kind}"
            )
          RUBY
          append_to_file "config/initializers/dashboard_widgets.rb", registry_entry
        end
      end

      def append_i18n_keys
        i18n_entry_en = build_i18n_entry("en")
        i18n_entry_es = build_i18n_entry("es")

        inject_into_file "config/locales/en/adminit.yml", after: "    dashboard_widgets:\n" do
          i18n_entry_en
        end

        inject_into_file "config/locales/es/adminit.yml", after: "    dashboard_widgets:\n" do
          i18n_entry_es
        end
      end

      def create_specs
        kinds.each do |kind|
          template "widget_component_spec.rb.tt",
            "spec/components/adminit/dashboard/#{file_name}/#{kind}_widget_component_spec.rb"
        end
      end

      private

      def build_i18n_entry(locale)
        titles = kinds.map do |kind|
          title = (kind == "general") ? "All #{class_name.pluralize.titleize}" : "#{class_name.pluralize.titleize} #{kind.titleize}"
          "        #{kind}:\n          title: \"#{title}\""
        end.join("\n")

        "      #{file_name}:\n#{titles}\n"
      end
    end
  end
end
