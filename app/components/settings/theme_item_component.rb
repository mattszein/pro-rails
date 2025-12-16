class Settings::ThemeItemComponent < ApplicationViewComponent
  option :theme
  option :selected, default: false

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
