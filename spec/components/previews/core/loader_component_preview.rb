class Core::LoaderComponentPreview < ViewComponent::Preview
  # @label Default
  def default
    render Core::LoaderComponent.new
  end

  # @label Dispatch Loaded
  def dispatch
    render Core::LoaderComponent.new do
      "<button data-action='click->core--loader-component#loaded'> Dispatch Loaded Action</button>".html_safe
    end
  end
end
