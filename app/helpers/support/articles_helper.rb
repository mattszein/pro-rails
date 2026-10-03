module Support
  module ArticlesHelper
    # nil category means a general article.
    def help_article_category_label(article)
      return I18n.t("support.articles.general") if article.category.blank?

      I18n.t("enums.article.category.#{article.category}")
    end

    # [label, param value] pairs for the category filter chips; nil value = all.
    def help_category_filters
      [[I18n.t("support.articles.all"), nil]] +
        Support::Article.categories.keys.map { |c| [I18n.t("enums.article.category.#{c}"), c] } +
        [[I18n.t("support.articles.general"), "general"]]
    end
  end
end
