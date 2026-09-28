# Per-type value validator, called from AudienceCondition#validate. Checks
# only shape and membership in the declared admissible set — never queries
# the database.
module AudienceConditions
  module VocabularyValidator
    module_function

    def valid?(condition, value)
      case condition.type
      when :boolean then valid_boolean?(condition, value)
      when :affirmative then valid_affirmative?(condition, value)
      when :id_list then valid_id_list?(value)
      when :duration then valid_duration?(condition, value)
      else false
      end
    end

    def valid_boolean?(condition, value)
      condition.accepts.include?(value)
    end

    def valid_affirmative?(condition, value)
      value == true && condition.accepts == [true]
    end

    def valid_id_list?(value)
      value.is_a?(Array) && value.present? && value.all? { |id| id.to_s.match?(/\A\d+\z/) }
    end

    def valid_duration?(condition, value)
      return false unless value.is_a?(Hash)

      amount = value["amount"] || value[:amount]
      unit = value["unit"] || value[:unit]
      amount.to_s.match?(/\A[1-9]\d*\z/) && condition.accepts.include?(unit.to_s)
    end
  end
end
