module Core
  module SubmenuStyles
    BASE_STYLES = "px-6 py-3 transition-all duration-200 relative whitespace-nowrap hover:cursor-pointer hover:text-primary-600 hover:dark:text-primary-400".freeze
    ACTIVE_CLASSES = "text-primary-600 dark:text-primary-400 font-bold".freeze
    INACTIVE_CLASSES = "font-semibold text-primary-500 dark:text-primary-200".freeze

    UNDERLINE_BASE = "absolute bottom-[-1px] left-0 w-full h-[1px] bg-secondary-300 " \
                     "shadow-secondary-400 shadow-[0_0_4px_var(--tw-shadow-color)]".freeze

    module_function

    def section_classes(active)
      [BASE_STYLES, active ? ACTIVE_CLASSES : INACTIVE_CLASSES].join(" ")
    end
  end
end
