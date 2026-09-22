# Declares the condition vocabulary. Lives in the autoload path (not an
# initializer) so edits are picked up by code reloading in development: the
# `to_prepare` hook in config/initializers/audience_conditions.rb calls
# `install` again with the reloaded class.
module AudienceConditions
  module Vocabulary
    UNITS = %w[days weeks months years].freeze

    module_function

    def install
      Registry.reset!

      Registry.register(
        key: :adminit_users,
        type: :boolean,
        accepts: [true, false],
        predicate: ->(account, value) { account.adminit_access? == value },
        scope: ->(relation, value) { raise NotImplementedError }
      )

      Registry.register(
        key: :roles,
        type: :id_list,
        accepts: "Role",
        predicate: ->(account, value) { Array(value).map(&:to_i).include?(account.role_id) },
        scope: ->(relation, value) { raise NotImplementedError }
      )

      Registry.register(
        key: :verified_users,
        type: :affirmative,
        accepts: [true],
        predicate: ->(account, value) { value == true && account.verified? },
        scope: ->(relation, value) { raise NotImplementedError }
      )

      Registry.register(
        key: :registration_age,
        type: :duration,
        accepts: UNITS,
        predicate: ->(account, value) { account.created_at.present? && account.created_at <= duration_from(value).ago },
        scope: ->(relation, value) { raise NotImplementedError }
      )
    end

    # Rebuilds a calendar duration from a stored {amount:, unit:} value.
    # Months and years are calendar quantities that a fixed second count
    # computes wrongly across month lengths and leap years.
    def duration_from(value)
      amount = (value["amount"] || value[:amount]).to_i
      unit = (value["unit"] || value[:unit]).to_s
      amount.public_send(unit)
    end
  end
end
