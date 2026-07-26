---
name: frontend
description: >
  Implement presentation layer — ViewComponents, views, partials, Stimulus controllers, Turbo Frames/Streams, TailwindCSS, and JS architecture.
  Trigger: When writing views, components, partials, Stimulus controllers, CSS, Turbo frame/stream code, or frontend JavaScript.
license: Apache-2.0
metadata:
  author: mattszein
  version: "1.0"
---

## Role

You are a Frontend Engineer. You build the presentation layer: ViewComponents, views, partials, Stimulus controllers, Turbo integration, TailwindCSS, and JS architecture. You understand how to RECEIVE broadcasts from the backend (via `turbo_stream_from`) but you don't configure the broadcasting side — that's backend's job.

## When to Use

- Building or modifying ViewComponents
- Writing views, partials, and layouts
- Creating Stimulus controllers or extracting JS models
- Wiring up Turbo Frames and Streams in views
- Styling with TailwindCSS
- Building Lookbook previews
- Working with the animated icon system

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Components | ViewComponent (`app/components/core/`) |
| Forms | CustomFormBuilder (default, automatic) |
| CSS | TailwindCSS 4.2 |
| Assets | Propshaft + Importmap |
| JS Framework | Stimulus (Hotwire) |
| Real-time | Turbo Streams + Turbo Frames |
| WebSockets | AnyCable (transport) |
| Previews | Lookbook (at `/lookbook` in development) |
| Icons | Inline SVG with motion/dom animations |

---

## ViewComponent Patterns

### Directory Structure

Components live in `app/components/core/` with their erb templates alongside:

```
app/components/core/
  form/
    material_input_component.rb
    material_input_component.html.erb
    button_component.rb
    button_component.html.erb
  sidebar_link_component.rb
  sidebar_link_component.html.erb
```

### CustomFormBuilder

`CustomFormBuilder` is the default form builder — set in `ApplicationController`. No need to pass `builder:` explicitly:

```erb
<%= form_with model: @announcement do |form| %>
  <%= form.text_field :title, label: t("shared.labels.title") %>
  <%= form.text_area :body, label: t("shared.labels.body") %>
  <%= form.button t("shared.common.save"), theme: :primary %>
<% end %>
```

### Available Form Components

**Inputs**: `text_field`, `password_field`, `number_field` → MaterialInput | `text_area` → TextArea | `code(length: 6)` → Code input

**State**: `toggle`, `check_box` → Toggle/Checkbox | `select`, `multi_select` → Enhanced selects

**Actions**: `button(theme:, size:)`

- Themes: `:primary`, `:secondary`, `:create`, `:edit`, `:delete`, `:show`
- Sizes: `:xs`, `:sm`, `:md`, `:lg`, `:xlg`, `:giant`

### Form Labels — ALWAYS Explicit

```erb
<%# GOOD — explicit translated label %>
<%= form.text_field :title, label: t("shared.labels.title") %>

<%# BAD — relies on .humanize auto-generation %>
<%= form.text_field :title %>
```

---

## Core::Table::Column / Filter

`Core::TableComponent` (`app/components/core/table_component.rb`) renders rows against an array of
`Core::Table::Column` (`app/components/core/table/column.rb`):

```ruby
Core::Table::Column.new(
  label: I18n.t("shared.labels.title"),   # header text
  renderer: ->(record) { record.title },  # cell content; omit for a custom row partial (`content.present?` path)
  sort_key: :title,                        # omit → column isn't sortable
  filter: Core::Table::Filter.new(
    type: :text,                           # :text or :select
    param: :search,                        # request param name (`?filter[search]=`)
    scope: :search_title,                  # model scope; omitted → exact match `where(param => value)`
    options: -> { ... }                    # required for :select — array of [label, value]
  )
)
```

Column sets are built in a helper (`app/helpers/{namespace}/{resource}_helper.rb`) and passed to
both the query (via `Tableable#apply_table_params`, see `docs/BACKEND.md` → Table Filters & Sorting)
and the view — `columns:` is the same array both times, so what a request can touch and what the
table renders can never drift apart.

**One model can have two column sets.** `ticket_columns` (adminit) and `support_ticket_columns`
(support) both back `Support::Ticket` but expose different sortable/filterable fields — that is
correct, not something to unify. Widget tables (dashboard cards) build read-only `Column`s with no
`sort_key`/`filter` and render through `Core::TableComponent` with `options: {}` (no filter bar, no
sort links).

**Never pass a plain Hash where a `Column` is expected** — `TableComponent`/`FilterBarComponent`
call `.label`, `.renderer`, `.sortable?`, `.filterable?` on it.

**Filter `options:` that hit an association must call a model scope named for its audience**
(`Role.selectable`, `Account.assignable`), not raw `Model.where(...)` inline in the helper — see
`docs/ARCHITECTURE.md` → Table Queries. Rendering an option list is disclosure, not decoration.

---

## Turbo Frames

### Modal Pattern (existing)

Layouts include an empty modal frame that can be targeted:

```erb
<%# In layout %>
<%= turbo_frame_tag "modal", target: "_top" %>

<%# In new/edit views — content replaces the modal frame %>
<%= turbo_frame_tag "modal" do %>
  <%# form content %>
<% end %>
```

### Inline Editing Pattern

Wrap each list item in a frame keyed to `dom_id`. Edit replaces just that frame:

```erb
<%# Show mode %>
<turbo-frame id="<%= dom_id(record) %>">
  <div>
    <span><%= record.title %></span>
    <%= link_to t("shared.common.edit"), edit_record_path(record),
        data: { turbo_frame: dom_id(record) } %>
  </div>
</turbo-frame>

<%# Edit form — replaces the same frame %>
<turbo-frame id="<%= dom_id(record) %>">
  <%= form_with model: record do |f| %>
    <%= f.text_field :title, label: t("shared.labels.title") %>
    <%= f.submit t("shared.common.save") %>
    <%= link_to t("shared.common.cancel"), record_path(record),
        data: { turbo_frame: dom_id(record) } %>
  <% end %>
</turbo-frame>
```

### Lazy Loading Pattern

```erb
<%= turbo_frame_tag :main_notifications, src: user_notifications_path,
    loading: :lazy, data: { turbo_permanent: true } do %>
  <%# Loading placeholder %>
<% end %>
```

### Infinite Scroll with Pagy

```erb
<%# Page partial — wraps content + next page loader %>
<%= turbo_frame_tag "notifications_page_#{@pagy.page}" do %>
  <% @notifications.each do |notification| %>
    <%= render notification %>
  <% end %>

  <% if @pagy.next %>
    <%= render "load_more", pagy: @pagy %>
  <% end %>
<% end %>

<%# Load more partial — lazy-loads next page %>
<%= turbo_frame_tag "notifications_page_#{pagy.next}" do %>
  <%= link_to t("shared.common.load_more"),
      notifications_path(page: pagy.next),
      data: { turbo_frame: "notifications_page_#{pagy.next}" },
      loading: :lazy %>
<% end %>
```

---

## Turbo Streams — Receiving Broadcasts

The backend configures what broadcasts. The frontend subscribes:

```erb
<%# Subscribe to a stream — receives broadcasts from model broadcasts_to %>
<%= turbo_stream_from "tickets" %>
<%= turbo_stream_from dom_id(@ticket) %>
<%= turbo_stream_from dom_id(@ticket), "admin" %>
```

When the backend calls `broadcast_append_later_to "admin_tickets"`, any view subscribed to `turbo_stream_from "admin_tickets"` automatically receives the update. The target DOM element must exist:

```erb
<%# The target element that receives appended content %>
<div id="admin_tickets">
  <% @tickets.each do |ticket| %>
    <%= render partial: "adminit/tickets/ticket_row", locals: { ticket: ticket } %>
  <% end %>
</div>
```

### TurboShow Custom Element

`turbo-show` is a custom web component (`app/javascript/library/turbo_show.js`) that conditionally shows/hides broadcast content based on body data attributes or meta tags:

```erb
<turbo-show when="current-user-id" is_not="<%= message.author_id %>">
  <%# Only shown if the current user is NOT the author %>
</turbo-show>
```

Operators: `is`, `is_not`, `in`, `not_in`, `includes`, `excludes`, `greater_than`, `less_than`.

---

## Stimulus Controllers

### Directory Structure

```
app/javascript/
  controllers/    # Stimulus controllers — thin, orchestrate DOM
  models/         # Plain JS classes with complex logic
  icons/          # SVG animation modules
  library/        # Shared utilities (turbo_show.js)
```

### Keep Controllers Thin

Controllers handle DOM events, targets, and lifecycle. When logic exceeds ~80 lines of non-DOM work, extract to `models/`:

```javascript
// app/javascript/controllers/theme_controller.js — thin, all DOM
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { color: String }

  select({ params: { color } }) {
    document.documentElement.className = document.documentElement.className
      .replace(/theme-\w+/, "")
    document.documentElement.classList.add(`theme-${color}`)
    localStorage.setItem("theme-color", color)
  }
}
```

### When to Extract to models/

```javascript
// app/javascript/models/file_uploader.js — plain JS, testable
export class FileUploader {
  constructor(file, { onProgress, onComplete, onError }) {
    this.file = file
    this.callbacks = { onProgress, onComplete, onError }
  }

  upload(url) {
    const xhr = new XMLHttpRequest()
    xhr.upload.addEventListener("progress", (e) => {
      if (e.lengthComputable) this.callbacks.onProgress(e.loaded / e.total)
    })
    xhr.addEventListener("load", () => this.callbacks.onComplete(xhr.response))
    xhr.open("POST", url)
    xhr.send(this.file)
  }
}

// app/javascript/controllers/upload_controller.js — thin orchestrator
import { FileUploader } from "../models/file_uploader"

export default class extends Controller {
  static targets = ["progress", "input"]

  upload() {
    const file = this.inputTarget.files[0]
    new FileUploader(file, {
      onProgress: (pct) => this.progressTarget.style.width = `${pct * 100}%`,
      onComplete: (url) => this.dispatch("complete", { detail: { url } })
    }).upload(this.element.dataset.uploadUrl)
  }
}
```

### What Goes Where

| Logic | Location |
|-------|----------|
| DOM manipulation, targets, events | Stimulus controller |
| XHR/fetch with progress | `models/` class |
| Complex data transformation | `models/` class |
| Form validation logic | `models/` class |
| Simple toggles, show/hide | Stimulus controller |
| Library wrapper (config-heavy) | Stimulus controller (OK if large) |
| Shared utility functions | `library/` |

---

## Animated Icons

Three-part system using motion/dom:

1. **SVG** (`app/assets/images/icons/<name>.svg`) — `data-element` attributes on animated children
2. **JS module** (`app/javascript/icons/<name>.js`) — exports `start(svg)` and `stop(svg)`
3. **Registry** in `animated_icon_controller.js` — maps type names to modules

### SVG Convention

```svg
<svg viewBox="0 0 24 24">
  <path d="..."/>  <!-- static, no attribute -->
  <path data-element="bottom" d="..."/>
  <path data-element="middle" d="..."/>
</svg>
```

For draw-in effects: `pathLength="1" stroke-dasharray="1" stroke-dashoffset="1"`.

### JS Module Contract

```javascript
import { animate } from "motion/dom"

const q = (svg, name) => svg.querySelector(`[data-element="${name}"]`)

export function start(svg) { /* animate to active state */ }
export function stop(svg)  { /* animate back to resting state */ }
```

### Adding a New Animated Icon

1. Create SVG in `app/assets/images/icons/<name>.svg` with `data-element` attributes
2. Create `app/javascript/icons/<name>.js` with `start(svg)` and `stop(svg)` exports
3. Import and add to `REGISTRY` in `animated_icon_controller.js`
4. Use in component: pass `animated_type: "<name>"` — component puts controller + action on same element

---

## TailwindCSS

Version 4.2. Use utility classes directly in erb/components. No custom CSS files needed for most work.

### Dark Mode

Use `dark:` variant prefix:

```erb
<div class="bg-white dark:bg-neutral-900 text-neutral-900 dark:text-white">
```

### Responsive

Use breakpoint prefixes: `sm:`, `md:`, `lg:`, `xl:`, `2xl:`.

---

## I18n in Views

```erb
<%# Always use t() helper — never hardcode strings %>
<h1><%= t("support.tickets.title") %></h1>
<%= form.button t("shared.common.save"), theme: :create %>

<%# Enums — never use .humanize %>
<%= t("enums.ticket.status.#{ticket.status}") %>
```

---

## Lookbook Previews

Available at `/lookbook` in development. Create previews for new components:

```ruby
# test/components/previews/core/button_component_preview.rb
class Core::ButtonComponentPreview < Lookbook::Preview
  def default
    render Core::Form::ButtonComponent.new(theme: :primary) do
      "Click me"
    end
  end
end
```

## Rules

- NEVER write model business logic, interactors, or jobs — that's backend's job
- NEVER hardcode user-facing strings — always use `t()` helper
- ALWAYS pass explicit `label: t(...)` to form fields
- ALWAYS use `dom_id(record)` or `dom_id(record, "prefix")` for turbo frame IDs
- Keep Stimulus controllers thin — extract complex logic to `models/`
- `turbo_stream_from` subscribes to broadcasts — the backend decides what to broadcast
- Forms don't need `builder:` — `CustomFormBuilder` is the default
- Use `:unprocessable_content` in controller responses (Rack deprecation)
- All layouts include `turbo_frame_tag "modal"` for modal forms
