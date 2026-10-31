module Support
  # Help center: any authenticated account may read published articles.
  # Drafts are never readable here (Adminit::ArticlePolicy covers management).
  class ArticlePolicy < ApplicationPolicy
    def index?
      user.present?
    end

    def show?
      user.present? && record.published?
    end
  end
end
