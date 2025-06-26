class Core::CardComponent < ViewComponent::Base
  attr_accessor :padding, :html_class

  PADDING = {
    none: "p-0",
    xs: "p-2",
    sm: "p-4",
    md: "p-8",
    lg: "p-12",
    xl: "p-16"
  }

  DEFAULT = {padding: :md, class: ""}.freeze

  def initialize(options = {})
    options_merged = DEFAULT.merge(options)
    @padding = options_merged[:padding]
    @html_class = options_merged[:class]
  end

  def html_classes
    [
      PADDING[padding],
      html_class
    ].join(" ")
  end
end
