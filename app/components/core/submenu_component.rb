class Core::SubmenuComponent < ApplicationViewComponent
  Section = Data.define(:key, :name, :path)

  option :sections, default: -> { [] }
  option :current_section, default: -> { :none }

  BASE_STYLES = "px-6 py-3 text-sm transition-all duration-200 relative whitespace-nowrap".freeze

  ACTIVE_STYLES = {
    true => "text-primary-600 dark:text-primary-400 font-bold",
    false => "font-semi-bold text-primary-500 border-secondary-300 dark:text-primary-300 dark:border-secondary-500"
  }.freeze

  def before_render
    @sections = sections.map { |s| s.is_a?(Section) ? s : Section.new(**s) }
    @current_section = current_section.to_sym
  end

  def active?(section)
    section.key == @current_section
  end

  def link_classes(section)
    class_names(BASE_STYLES, ACTIVE_STYLES[section.key == @current_section])
  end
end
