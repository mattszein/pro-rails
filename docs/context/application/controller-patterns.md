---
kind: context
id: controller_patterns
version: 1
source_id: pro_rails_docs
source_ref: context/application/controller-patterns.md
domain: application
audience: [backend_engineer]
topics: [controllers, routing, error-handling, requests]
references: [authorization_actionpolicy, interactor_rules]
stability: stable
---

# Controller Patterns (Pro-Rails)

## Hierarchy

```
ApplicationController
  └─ error handling (rescue_from chain)
  └─ default_form_builder CustomFormBuilder
  └─ locale detection
      │
      ├─ SharedBaseController
      │    └─ Pagy::Backend include
      │    └─ ActionPolicyHandler (authorize!, verify_authorized)
      │    └─ RecordNotFoundHandler
      │    └─ current_account helper
      │         │
      │         ├─ DashboardController       ← user-facing pages (sidebar)
      │         ├─ Adminit::ApplicationController
      │         │    └─ before_action :authorize_adminit_access
      │         └─ Settings::BaseController  ← settings submenu
```

## When to inherit from which

| Feature type | Base class |
|---|---|
| Standard user-facing page | `DashboardController` |
| Admin panel page | `Adminit::ApplicationController` |
| Settings page | `Settings::BaseController` |
| Public page (no auth required) | `ApplicationController` (add no `require_account`) |

## `verify_authorized` is opt-in

Controllers declare `verify_authorized` at the class level. A controller that inherits from `SharedBaseController` but forgets to declare it will silently skip authorization for ALL actions.

Always pair with `before_action :require_account` for any user-facing controller. Forgetting `require_account` means `current_account` is `nil` — Rodauth's rack middleware does NOT halt the chain.

```ruby
class TicketsController < DashboardController
  before_action :require_account
  verify_authorized
end
```

## `default_form_builder CustomFormBuilder`

Set on `ApplicationController`. Every `form_with` call in the app uses `CustomFormBuilder` automatically — component-backed inputs, consistent error rendering. No `builder:` kwarg needed.

## `ensure_frame_response`

Turbo frame guard. When a controller action is designed to respond only inside a Turbo frame, call `before_action :ensure_frame_response`. It redirects non-frame requests to the full page, preventing partial-page HTML from rendering as a full document.

## Multi-format response helpers

`SharedBaseController` provides three response helpers that handle Turbo Stream + HTML + JSON in one call:

```ruby
respond_success(notice: t("..."), redirect: tickets_path)
respond_error(alert: t("..."), redirect: ticket_path(@ticket))
respond_form_error(@ticket)  # re-renders form with validation errors via Turbo Stream
```

Controllers don't manually branch on `format` — use these helpers for consistency.

## Routing conventions

```ruby
scope "(:locale)", locale: /en|es/ do
  # All user-facing routes — locale is optional, defaults to :en
end

draw :adminit  # delegates to config/routes/adminit.rb
```

**Member POST actions for state transitions:**
```ruby
resources :tickets do
  member do
    post :take
    post :leave
    post :finish
    post :reopen
  end
end
```

**GET/POST pairs for forms that need a preview step:**
```ruby
member do
  get  :reject_reopen, action: :new_reject_reopen
  post :reject_reopen
end
```

**Nested controllers with a different module:**
```ruby
resources :tickets do
  resources :notes, controller: "tickets/notes"
end
```

## Error handling

**Global `rescue_from` chain** (ApplicationController → SharedBaseController):
- `RecordNotFoundHandler` — catches `ActiveRecord::RecordNotFound`, renders 404
- `ActionPolicyHandler` — catches `ActionPolicy::Unauthorized`, renders 403
- `ErrorResponseActions` — renders standardized error pages

**Interactor error pattern:**
```ruby
result = Tickets::Assign.call(ticket: @ticket, assignee: account)
if result.success?
  respond_success(...)
else
  respond_error(alert: result.error, ...)
end
```

Interactors rescue `InvalidTransition` and `RecordInvalid` and call `context.fail!`. Controllers only check `result.success?`.

**Flash namespacing:** Admin actions use `adminit.*` flash keys (`flash[:adminit_notice]`) to avoid colliding with user-facing flash messages rendered in the dashboard layout.

## Strong params

Colocated as private methods named `<resource>_params`:

```ruby
private

def ticket_params
  params.require(:ticket).permit(:title, :description, :category, attachments: [])
end
```

## `app/misc/`

Non-standard directory. Contains Rodauth configuration: `rodauth_main.rb` (feature flags, account table config) and `rodauth_app.rb` (rack middleware chain). Not a typical Rails location — don't move these files.
