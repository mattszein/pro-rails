module Adminit
  module ArticlesHelper
    ARTICLE_STATUS_THEME = {draft: :yellow, published: :green}.freeze

    def article_status_theme(status)
      ARTICLE_STATUS_THEME[status.to_sym]
    end

    def article_category_label(article)
      I18n.t("enums.article.category.#{article.category}")
    end

    def article_locale_label(locale)
      I18n.t("adminit.articles.locales.#{locale}")
    end

    def article_category_options
      Support::Article.categories.keys.map { |c| [I18n.t("enums.article.category.#{c}"), c] }
    end

    def article_locale_options
      I18n.available_locales.map { |l| [article_locale_label(l), l.to_s] }
    end

    # One column set drives both the query whitelist (Tableable) and the rendered table.
    def article_columns
      [
        Core::Table::Column.new(
          label: I18n.t("shared.labels.title"),
          renderer: ->(article) { article.title },
          sort_key: :title,
          filter: Core::Table::Filter.new(type: :text, param: :search, scope: :search_title)
        ),
        Core::Table::Column.new(
          label: I18n.t("shared.labels.category"),
          renderer: ->(article) { article_category_label(article) },
          sort_key: :category,
          filter: Core::Table::Filter.new(type: :select, param: :category, options: -> { article_category_options })
        ),
        Core::Table::Column.new(
          label: I18n.t("adminit.articles.locale"),
          renderer: ->(article) { article_locale_label(article.locale) },
          sort_key: :locale,
          filter: Core::Table::Filter.new(type: :select, param: :locale, options: -> { article_locale_options })
        ),
        Core::Table::Column.new(
          label: I18n.t("shared.labels.status"),
          renderer: ->(article) {
            render(Core::BadgeComponent.new(label: I18n.t("enums.article.status.#{article.status}"),
              theme: article_status_theme(article.status)))
          },
          sort_key: :status,
          filter: Core::Table::Filter.new(
            type: :select,
            param: :status,
            options: -> { Support::Article.statuses.keys.map { |s| [I18n.t("enums.article.status.#{s}"), s] } }
          )
        ),
        Core::Table::Column.new(
          label: I18n.t("shared.labels.author"),
          renderer: ->(article) { article.author&.email || "-" }
        ),
        Core::Table::Column.new(
          label: I18n.t("shared.labels.created_on"),
          renderer: ->(article) { l(article.created_at, format: :short) },
          sort_key: :created_at
        ),
        Core::Table::Column.new(
          label: I18n.t("shared.common.actions"),
          renderer: ->(article) {
            render(Core::LinkComponent.new(name: I18n.t("shared.common.show"), url: adminit_article_path(article),
              style: :as_button, theme: :show, size: :xs, html_options: {data: {turbo_prefetch: false, turbo_frame: "_top"}}))
          }
        )
      ]
    end
  end
end
