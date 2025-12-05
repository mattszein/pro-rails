class Settings::ThemeItemComponent < ViewComponent::Base
  def initialize(theme:, selected: false)
    @theme = theme
    @selected = selected
  end

  def theme_id
    @theme.id
  end

  def theme_name
    @theme.name
  end

  def selected?
    @selected
  end
end
