class Core::SubmenuComponent < ApplicationViewComponent
  include Core::SubmenuStyles

  Section = Data.define(:key, :name, :path)

  option :sections, default: -> { [] }
  option :current_section, default: -> { :none }

  def before_render
    @sections = sections.map { |s| s.is_a?(Section) ? s : Section.new(**s) }
    @current_section = current_section.to_sym
  end

  def active?(section)
    section.key == @current_section
  end

  def link_classes(section)
    section_classes(active?(section))
  end
end
