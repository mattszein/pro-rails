module AudienceConditions
  # A declared condition in the audience vocabulary.
  #
  # `type` selects both the value's storage shape and its admin form partial:
  # :boolean (true/false, three operator-visible states: off/true/false),
  # :affirmative (true only, two states: off/true), :id_list (array of ids of
  # the model named by `accepts`), :duration (a {amount:, unit:} pair).
  #
  # `accepts` names the admissible-value descriptor: [true, false] for
  # :boolean, [true] for :affirmative, the referenced model's class name
  # (a String, so the registry never queries) for :id_list, the admissible
  # unit names for :duration.
  #
  # `predicate` is `->(account, value) { Boolean }` — reads only the account
  # object it is handed, never queries.
  #
  # `scope` is `->(relation, value) { relation }`, declared now and left
  # unimplemented (raises NotImplementedError) until a caller needs a member
  # list.
  Condition = Data.define(:key, :type, :accepts, :predicate, :scope)
end
