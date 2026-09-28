module AudienceConditions
  # A declared condition in the audience vocabulary. `type` selects both the
  # value's storage shape and its admin form partial. `accepts` names the
  # admissible values (or, for :id_list, the referenced model's class name).
  # `predicate` is `->(account, value) { Boolean }` — reads only the account
  # object it is handed, never queries.
  Condition = Data.define(:key, :type, :accepts, :predicate)
end
