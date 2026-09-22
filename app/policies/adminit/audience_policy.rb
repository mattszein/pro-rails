module Adminit
  class AudiencePolicy < ApplicationPolicy
    POLICY_RESOURCE = :audience
    self.identifier = :"Adminit::AudiencePolicy"

    # No custom rules: index?/create? are aliased to manage? by
    # ApplicationPolicy, and every other rule this policy is asked about
    # (show?, update?, archive?, unarchive?) has no method and no alias of
    # its own, so ActionPolicy's `default_rule :manage?` resolves it the
    # same way. No destroy? rule — no admin path destroys an audience
    # (TECH-PLAN §3.5); archiving replaces deletion.
  end
end
