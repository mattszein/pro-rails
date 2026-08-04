require "rails/generators"

module ProRails
  module Generators
    class DashboardWidgetGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("templates", __dir__)

      argument :kinds, type: :array, default: ["general"], banner: "kind1 kind2 kind3"

      def create_component_files
        kinds.each do |kind|
          @kind = kind
          template "widget_component.rb.tt",
            "app/components/adminit/dashboard/#{file_name.pluralize}/#{kind}_widget_component.rb"
          template "widget_component.html.erb.tt",
            "app/components/adminit/dashboard/#{file_name.pluralize}/#{kind}_widget_component.html.erb"
        end
      end

      REGISTRY_FILE = "app/lib/dashboard/widgets.rb"
      REGISTRY_MARKER = /^ *# pro_rails:dashboard_widget_generator/

      def append_registry_entries
        kinds.each do |kind|
          registry_entry = <<-RUBY
      WidgetRegistry.register(
        key: :#{file_name}_#{kind}, resource: :#{file_name.singularize}, kind: :#{kind},
        policy_class: "Adminit::#{class_name.singularize}Policy",
        component_class: "Adminit::Dashboard::#{class_name.pluralize}::#{kind.camelize}WidgetComponent"
      )

          RUBY
          inject_into_file REGISTRY_FILE, registry_entry, before: REGISTRY_MARKER
        end
      end

      def append_i18n_keys
        inject_into_file "config/locales/en/adminit.yml", after: "    dashboard_widgets:\n" do
          i18n_entry
        end

        inject_into_file "config/locales/es/adminit.yml", after: "    dashboard_widgets:\n" do
          i18n_entry
        end
      end

      def create_specs
        kinds.each do |kind|
          @kind = kind
          template "widget_component_spec.rb.tt",
            "spec/components/adminit/dashboard/#{file_name.pluralize}/#{kind}_widget_component_spec.rb"
        end
      end

      private

      # template() evaluates .tt files against this instance's own binding, not the caller's block-local scope.
      attr_reader :kind

      def i18n_entry
        stubs = kinds.map { |kind| "        #{kind}: {}" }.join("\n")

        "      #{file_name.pluralize}:\n#{stubs}\n"
      end
    end
  end
end
