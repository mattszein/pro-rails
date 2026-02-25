class Core::SidebarComponent < ApplicationViewComponent
  option :open, default: -> { false }
  option :title, default: -> { "" }
  option :navigation_items, default: -> { [] }
end
