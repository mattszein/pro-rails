class MakeSupportArticleCategoryGeneralByDefault < ActiveRecord::Migration[8.1]
  # 100 = Support::Article::GENERAL_CATEGORY, kept clear of Support::Ticket::CATEGORIES (0-4).
  GENERAL = 100

  def up
    execute "UPDATE support_articles SET category = #{GENERAL} WHERE category IS NULL"
    change_column_default :support_articles, :category, from: nil, to: GENERAL
    change_column_null :support_articles, :category, false
  end

  def down
    change_column_null :support_articles, :category, true
    change_column_default :support_articles, :category, from: GENERAL, to: nil
    execute "UPDATE support_articles SET category = NULL WHERE category = #{GENERAL}"
  end
end
