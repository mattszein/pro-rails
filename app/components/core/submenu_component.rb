class Core::SubmenuComponent < ViewComponent::Base
  Section = Data.define(:key, :name, :path)
  attr_accessor :sections, :current_section

  def initialize(sections: [], current_section: :none)
    @sections = sections.map { |s| s.is_a?(Section) ? s : Section.new(**s) }
    @current_section = current_section.to_sym
  end

  def link_classes(section)
    base = "flex items-center bg-highlight border-b-3 hover:bg-default hover:text-primary-600 hover:border-secondary-500 dark:hover:text-primary-400 dark:hover:border-secondary-200 focus:border-b-black focus-border-b-2 px-3 py-2 focus:outline-none"
    active = "text-primary-600 border-b-secondary-500 dark:text-primary-400 dark:border-b-secondary-200 font-bold"
    "#{base} #{(section.key == @current_section) ? active : "font-semi-bold text-primary-500 border-secondary-300 dark:text-primary-300 dark:border-secondary-500"}"
  end
end
