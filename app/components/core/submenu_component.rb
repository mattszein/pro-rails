class Core::SubmenuComponent < ApplicationViewComponent
  Section = Data.define(:key, :name, :path)

  option :sections, default: -> { [] }
  option :current_section, default: -> { :none }

  BASE_STYLES = "flex items-center bg-highlight border-b-3 hover:bg-default hover:text-primary-600 hover:border-secondary-500 dark:hover:text-primary-400 dark:hover:border-secondary-200 focus:border-b-black focus-border-b-2 px-3 py-2 focus:outline-none".freeze

  ACTIVE_STYLES = {
    true => "text-primary-600 border-b-secondary-500 dark:text-primary-400 dark:border-b-secondary-200 font-bold",
    false => "font-semi-bold text-primary-500 border-secondary-300 dark:text-primary-300 dark:border-secondary-500"
  }.freeze

  def before_render
    @sections = sections.map { |s| s.is_a?(Section) ? s : Section.new(**s) }
    @current_section = current_section.to_sym
  end

  def link_classes(section)
    class_names(BASE_STYLES, ACTIVE_STYLES[section.key == @current_section])
  end
end
