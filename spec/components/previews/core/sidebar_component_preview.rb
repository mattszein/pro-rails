class Core::SidebarComponentPreview < ViewComponent::Preview
  # @label Playground
  # @param open toggle
  def playground(open: true)
    custom_nav = [
      {
        label: "Dashboard",
        path: "#",
        icon: :home
      },
      {
        label: "Users",
        path: "#",
        icon: :plus
      }
    ]
    render(Core::SidebarComponent.new(open: true, navigation_items: custom_nav))
  end
end
