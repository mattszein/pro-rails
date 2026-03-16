class Core::DarkLightComponent < ViewComponent::Base
  erb_template <<~ERB
    <button class="p-2 mr-2 text-gray-600 rounded-lg cursor-pointer hover:text-gray-900 hover:bg-gray-100 focus:bg-gray-100 dark:focus:bg-gray-700 focus:ring-2 focus:ring-gray-100 dark:focus:ring-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white" data-controller="dark-mode" data-dark-mode-target="themeToggle" data-action="click->dark-mode#toggleTheme">
      <%= helpers.icon("mode", classes: "w-6 h-6") %>
      <span class="sr-only">Theme</span>
    </button>
  ERB
end
