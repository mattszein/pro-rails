# Generic, type-driven value and account fixtures for
# spec/support/shared_examples/audience_condition.rb. Driven only by
# `condition.type` and `condition.accepts` — never by a condition's key — so
# it runs unmodified against a newly registered condition.
module AudienceConditions
  module TestFixtures
    module_function

    def valid_value_for(condition)
      case condition.type
      when :boolean, :affirmative then condition.accepts.first
      when :id_list then [1]
      when :duration then {"amount" => 1, "unit" => condition.accepts.first}
      end
    end

    def invalid_value_for(condition)
      case condition.type
      when :boolean then "not_a_boolean"
      when :affirmative then false
      when :id_list then []
      when :duration then {"amount" => 0, "unit" => "fortnights"}
      end
    end

    def sample_accounts
      [
        FactoryBot.create(:account, :verified, :with_role),
        FactoryBot.create(:account)
      ]
    end
  end
end
