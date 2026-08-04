class Core::LoaderComponent < ApplicationViewComponent
  # id: marks the wrapper data-turbo-permanent so Turbo's morph refresh can't
  # reset is-loading on non-idempotent JS content (e.g. TomSelect) without
  # Stimulus re-firing connect() to clear it again.
  option :id, default: -> {}
end
