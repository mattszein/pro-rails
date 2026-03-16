class Core::LocaleSwitcherComponent < ApplicationViewComponent
  def locales
    I18n.available_locales
  end

  def current_locale
    I18n.locale
  end
end
