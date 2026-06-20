---
kind: context
id: testing_patterns
version: 1
source_id: pro_rails_docs
source_ref: context/testing/testing-patterns.md
domain: testing
audience: [tester]
topics: [testing-patterns, test-conventions, spec-structure]
references: []
stability: stable
---

# Testing Patterns (Pro-Rails)

## Directory layout

```
spec/
  models/           controllers/      interactors/
  policies/         jobs/             requests/
  system/           factories/        support/
    login_helper.rb
    rodauth_request_helpers.rb
```

Controller specs are in `spec/controllers/`, NOT `spec/requests/`. Request specs are
separate and cover full integration flows (auth, redirect chains).

## Docker test command — non-negotiable

```bash
docker compose exec -e RAILS_ENV=test rails bundle exec rspec
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb
docker compose exec -e RAILS_ENV=test rails bundle exec rspec spec/models/account_spec.rb:10
```

`-e RAILS_ENV=test` is MANDATORY. Omitting it runs against the development DB — different
data, possibly different schema. Tests pass or fail for the wrong reasons.

## Spec type by target

| Target | Spec type | What to cover |
|---|---|---|
| Model | `spec/models/` | Validations, transitions, query methods, scopes |
| Controller | `spec/controllers/` | Auth redirect, authorization, response format |
| Interactor | `spec/interactors/` | Success path, failure path, side-effect calls |
| Job | `spec/jobs/` | Idempotency guards (both guards), delegation to Interactor |
| Policy | `spec/policies/` | `manage?` and any overridden predicates |
| Request (integration) | `spec/requests/` | Auth + redirect flows end-to-end |
| System (UI) | `spec/system/` | Full user flows via Capybara + Cuprite |

For interactor specs: test BOTH the success path AND the explicit failure path (e.g., the
`InvalidTransition` rescue branch, the record-not-found guard exit).

For job specs: test BOTH idempotency guards — the existence guard (`find_by` returns nil)
AND the expected-state guard (timestamp mismatch). Both should exit without calling the
Interactor.

## Factory conventions

- One factory per model.
- Traits for common states: `:verified` (Account), `:with_role`, `:scheduled` (Announcement).
- No nested fixtures — traits compose: `create(:account, :verified, :with_role)`.
- Minimal defaults: factories produce a valid record without extra setup.

## Codebase-specific gotchas

**Rodauth is Rack middleware — it does NOT run in controller specs.** Use the `login_user`
helper (via `LoginHelpers::Controller`), which calls `rodauth.account_from_login` +
`rodauth.login_session` directly without an HTTP round-trip.

**ActionPolicy matchers need a kind argument for records built during the action.** Use
`be_authorized_to(:create?, a_kind_of(Support::Ticket))` when the record doesn't exist
before the action fires.

**Turbo frame responses** require the request header:
`@request.headers["Turbo-Frame"] = "frame_id"`. Without it, `ensure_frame_response`
redirects instead of rendering the frame content.

**Jobs: use `find_by` not `find` in specs.** If you test the deleted-record guard, the
job must use `find_by` — `find` raises `RecordNotFound` before the guard logic runs,
which is the wrong code path to test.

**`CustomFormBuilder` is the default.** Form-level specs see component output, not plain
HTML inputs. Match against component-rendered markup.

**Rodauth middleware does NOT run in request specs by default.** Use the request spec
login helper which does a real POST to `/login` and follows redirects.

## Matchers in use

- **Shoulda-Matchers** — `validate_presence_of`, `belong_to`, `have_many`, enum matchers.
  Refer to gem docs for syntax; do not duplicate it here.
- **ActionPolicy matchers** — `be_authorized_to`, `have_permissions`. Refer to gem docs.

Both matchers are included via `rails_helper.rb`. No additional setup needed per spec.
