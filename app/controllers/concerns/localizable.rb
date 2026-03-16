module Localizable
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private

  def switch_locale(&action)
    locale = extract_locale || I18n.default_locale
    I18n.with_locale(locale, &action)
  end

  def extract_locale
    parsed = params[:locale]
    parsed if parsed.present? && I18n.available_locales.map(&:to_s).include?(parsed)
  end

  def default_url_options
    locale = I18n.locale
    if locale == I18n.default_locale
      {locale: nil}.merge(super)
    else
      {locale: locale}.merge(super)
    end
  end
end
