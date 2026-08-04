class Core::TabsComponent < ApplicationViewComponent
  include Core::SubmenuStyles

  # Each tab carries its trigger label (`name`) and its panel body (the block
  # content). The component renders both the tablist and the tabpanels, and owns
  # the `tabs` Stimulus controller that toggles them client-side.
  renders_many :tabs, "TabComponent"

  option :active_classes, default: -> { Core::SubmenuStyles::ACTIVE_CLASSES }
  option :inactive_classes, default: -> { Core::SubmenuStyles::INACTIVE_CLASSES }
  # Caller-supplied prefix so ARIA ids stay stable across Turbo morph
  # refreshes (morph matches nodes by `id`; a per-render value like
  # `object_id` would get a new id every refresh and reset the active tab).
  option :id_prefix, default: -> { "tabs" }

  def tab_classes(active)
    section_classes(active)
  end

  def tab_id(index) = "#{id_prefix}-tab-#{index}"

  def panel_id(index) = "#{id_prefix}-panel-#{index}"

  class TabComponent < ApplicationViewComponent
    option :name

    def call = content
  end
end
