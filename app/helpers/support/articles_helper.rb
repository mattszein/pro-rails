module Support
  module ArticlesHelper
    def help_article_category_label(article)
      I18n.t("enums.article.category.#{article.category}")
    end

    # [label, param value] pairs for the category filter chips; nil value = all.
    def help_category_filters
      [[I18n.t("support.articles.all"), nil]] +
        Support::Article.categories.keys.map { |c| [I18n.t("enums.article.category.#{c}"), c] }
    end
  end
end
