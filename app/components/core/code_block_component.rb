# Scrollable monospace block for raw text (JSON, logs, transcripts). The text is escaped by the template.
class Core::CodeBlockComponent < ApplicationViewComponent
  option :text
  option :max_height, default: -> { :md }
  option :classes, default: -> { "" }
  option :html_options, default: -> { {} }

  MAX_HEIGHT_STYLES = {
    sm: "max-h-40",
    md: "max-h-72",
    lg: "max-h-[32rem]"
  }.freeze

  def html_classes
    class_names(
      "overflow-auto whitespace-pre-wrap break-words rounded bg-slate-100 p-2 text-xs text-gray-900 dark:bg-slate-800 dark:text-gray-100",
      MAX_HEIGHT_STYLES.fetch(max_height),
      classes
    )
  end
end
