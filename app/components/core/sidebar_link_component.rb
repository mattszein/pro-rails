class Core::SidebarLinkComponent < ViewComponent::Base
  attr_reader :label, :path, :icon, :active_paths, :options

  def initialize(label:, path:, icon:, active_paths: [], options: {})
    @label = label
    @path = path.is_a?(Symbol) ? send(path) : path
    @icon = icon
    @active_paths = active_paths
    @options = options
  end

  def link_classes
    base_classes = "inline-flex p-3 hover:cursor-pointer hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg w-full transition duration-200 group"
    active_classes = active? ? "bg-blue-100 dark:bg-blue-900" : ""
    
    class_names(base_classes, active_classes)
  end

  def icon_classes
    base_classes = "h-8 text-gray-500 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-blue-500 transition duration-200"
    active_classes = active? ? "text-blue-600 dark:text-blue-400" : ""
    
    class_names(base_classes, active_classes)
  end

  def link_options
    default_options = {
      class: link_classes,
      custom_style: { style: :no_style }
    }
    
    default_options.deep_merge(options)
  end

  private

  def active?
    return false if active_paths.empty?
    
    current_path = request.path
    active_paths.any? { |active_path| current_path == active_path }
  end

  def icon_svg
    icons = {
      home: '<svg class="<%= icon_classes %>" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 20 20">
               <path d="m19.707 9.293-2-2-7-7a1 1 0 0 0-1.414 0l-7 7-2 2a1 1 0 0 0 1.414 1.414L2 10.414V18a2 2 0 0 0 2 2h3a1 1 0 0 0 1-1v-4a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v4a1 1 0 0 0 1 1h3a2 2 0 0 0 2-2v-7.586l.293.293a1 1 0 0 0 1.414-1.414Z"/>
             </svg>',
      
      plus: '<svg class="<%= icon_classes %>" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg" aria-hidden="true">
               <path clip-rule="evenodd" fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z"></path>
             </svg>',
      
      settings: '<svg class="<%= icon_classes %>" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 20 20">
                   <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7.75 4H19M7.75 4a2.25 2.25 0 0 1-4.5 0m4.5 0a2.25 2.25 0 0 0-4.5 0M1 4h2.25m13.5 6H19m-2.25 0a2.25 2.25 0 0 1-4.5 0m4.5 0a2.25 2.25 0 0 0-4.5 0M1 10h11.25m-4.5 6H19M7.75 16a2.25 2.25 0 0 1-4.5 0m4.5 0a2.25 2.25 0 0 0-4.5 0M1 16h2.25"/>
                 </svg>',
      
      logout: '<svg class="<%= icon_classes %>" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 16 16">
                 <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8h11m0 0-4-4m4 4-4 4m-5 3H3a2 2 0 0 1-2-2V3a2 2 0 0 1 2-2h3"/>
               </svg>'
    }
    
    icons[icon]&.html_safe
  end

  def render_icon
    if icon_svg
      # Use ERB to interpolate the icon_classes
      icon_svg
    end
  end
end
