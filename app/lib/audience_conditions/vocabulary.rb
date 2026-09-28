# Declares the condition vocabulary. Autoloaded (not an initializer) so
# edits hot-reload in development via config/initializers/audience_conditions.rb.
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
        predicate: ->(account, value) { account.adminit_access? == value }
      )

      Registry.register(
        key: :roles,
        type: :id_list,
        accepts: "Role",
        predicate: ->(account, value) { Array(value).map(&:to_i).include?(account.role_id) }
      )

      Registry.register(
        key: :verified_users,
        type: :affirmative,
        accepts: [true],
        predicate: ->(account, value) { value == true && account.verified? }
      )

      Registry.register(
        key: :registration_age,
        type: :duration,
        accepts: UNITS,
        predicate: ->(account, value) { account.created_at.present? && account.created_at <= duration_from(value).ago }
      )
    end

    # Rebuilds a calendar duration from a stored {amount:, unit:} value —
    # months/years are calendar quantities a fixed second count gets wrong
    # across month lengths and leap years.
    def duration_from(value)
      amount = (value["amount"] || value[:amount]).to_i
      unit = (value["unit"] || value[:unit]).to_s
      amount.public_send(unit)
    end
  end
end
