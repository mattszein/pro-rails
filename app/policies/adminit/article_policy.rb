module Adminit
  class ArticlePolicy < ApplicationPolicy
    POLICY_RESOURCE = :article
    self.identifier = :"Adminit::ArticlePolicy"
  end
end
