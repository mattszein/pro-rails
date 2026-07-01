class Core::TabsComponent < ApplicationViewComponent
  include Core::SubmenuStyles

  # Each tab carries its trigger label (`name`) and its panel body (the block
  # content). The component renders both the tablist and the tabpanels, and owns
  # the `tabs` Stimulus controller that toggles them client-side.
  renders_many :tabs, "TabComponent"

  option :active_classes, default: -> { Core::SubmenuStyles::ACTIVE_CLASSES }
  option :inactive_classes, default: -> { Core::SubmenuStyles::INACTIVE_CLASSES }

  def tab_classes(active)
    section_classes(active)
  end

  class TabComponent < ApplicationViewComponent
    option :name

    def call = content
  end
end
