
class Settings::AvatarWizard::CheckboxOptionComponent < ApplicationViewComponent
  option :dna_field
  option :value
  option :label
  option :selected
  option :align, default: -> { :center }

  def label_class
    "flex items-#{align} gap-3 p-3 rounded-xl border-2 border-gray-200 dark:border-gray-700 cursor-pointer hover:border-primary-400 transition-all has-[:checked]:border-primary-500 has-[:checked]:bg-primary-50 dark:has-[:checked]:bg-primary-900/20"
  end

  def checkbox_class
    classes = "rounded text-primary-500"
    (align == :start) ? "mt-0.5 flex-shrink-0 #{classes}" : classes
  end
end
