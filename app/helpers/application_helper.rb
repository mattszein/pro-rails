module ApplicationHelper
  def sidebar_links
    [
      {
        label: "Home",
        path: :dashboard_path,
        icon: :home,
      },
      {
        label: "Settings",
        path: :dashboard_path, # Replace with actual path  
        icon: :settings,
      },
      {
        label: "Log out",
        path: rodauth.logout_path,
        icon: :logout,
        options: { data: { turbo_prefetch: "false" } }
      }
    ]
  end
end
