# Adminit Dashboard Widgets

The Adminit dashboard (`adminit_root_path` → `Adminit::DashboardsController#index`) is a grid of
per-resource widgets. Each widget is a self-contained ViewComponent, declared once in a registry and
grouped by resource on the page.

## Pieces

| Piece | File | Role |
|---|---|---|
| Registry | `app/lib/dashboard/widget_registry.rb` | In-memory list of `Widget` structs — see fields below. |
| Declarations | `app/lib/dashboard/widgets.rb` | One `WidgetRegistry.register(...)` per widget inside `Widgets.install`. Autoloaded, so edits hot-reload in dev; the initializer only re-runs `install` on `to_prepare`. |
| Access | `Role#dashboard_widgets` | A role's `dashboard_widget_keys` resolve to registered widgets; the controller renders only those. |
| Container | `app/components/adminit/dashboard/tabbed_container_component.rb` | Wraps the widgets of one resource in a card: resource title, a derived "view all" link, and one tab per widget (tabs are always rendered, even for a single widget). |
| Tabs | `app/components/core/tabs_component.rb` | Reusable, self-contained tabs: renders the tablist **and** the panels, and owns the `tabs` Stimulus controller. |
| Widget bodies | `app/components/adminit/dashboard/<resource>/*_widget_component.rb` | The actual content (lists, stats, charts). |
| Chart | `app/components/adminit/dashboard/chart_component.rb` | Shared wrapper for the `chart` Stimulus controller (ApexCharts). Widgets pass an options hash built with `Dashboard::ChartOptions`. |
| Helper | `app/helpers/adminit/dashboard_helper.rb` | Shared constants + `auto_refresh_data` / `chart_data` Stimulus wiring. |

## Widget struct fields

| Field | Default | Notes |
|---|---|---|
| `key` | — | Unique symbol identifier, e.g. `:tickets_personal`. Also the route param (`widgets/:key`) and the source of `turbo_frame_id` (`"dashboard_#{key}"`, derived — not a config field). |
| `resource` | — | Resource group symbol, e.g. `:ticket`. Groups widgets into one container card. |
| `kind` | — | Slot within a resource: `:general`, `:personal`, `:analytics`, `:overview`. Drives tab label and card height. |
| `span` | `:full` | Grid column span for the container. `:full` → `col-span-2` (full row), `:half` → `col-span-1`. Set per resource — all widgets in a resource share the same value. |
| `policy_class` | — | Governs visibility check. |
| `component_class` | — | ViewComponent class name (string, constantized at render time). |
| `refresh_interval` | `nil` | Seconds between auto-reloads (min 15). `nil` = no auto-refresh. |
| `lazy` | `true` | Deferred turbo frame load. Set `false` when the component needs to initialize Stimulus in the normal page lifecycle (e.g. TomSelect). |
| `view_all_params` | `nil` | Optional query params merged into the container's "view all" link (e.g. `{assignee: "me"}`). |

## Rendering flow

1. `DashboardsController#index` loads `current_account.role.dashboard_widgets`.
2. `index.html.erb` groups them `by(&:resource)` and renders one `TabbedContainerComponent` per group inside a `grid grid-cols-1 md:grid-cols-2` grid.
3. The container reads `widgets.first.span` to set its grid column class (`col-span-2` or `col-span-1`).
4. The container renders the resource title (`adminit.navigation.<resource>s`) with a **"view all"** link next to it. The link defaults to the resource's adminit index route (`adminit_#{resource.to_s.pluralize}_path`); the first widget carrying `view_all_params` adds its query params.
5. Each widget is rendered through `widget_frame`:
   - **Lazy** (default): a `turbo_frame_tag` with `src` → `Adminit::DashboardsController#widget`, `loading: :lazy`, showing a `SkeletonWidgetComponent` until loaded.
   - **Eager** (`lazy: false`): rendered inline in the page.

## Tabs (client-side switching)

`Core::TabsComponent` takes tab slots — each `with_tab(name:) { ...panel body... }` carries its label and its panel. It renders the `<button role="tab">` list, the `<div role="tabpanel">` panels (with `aria-controls`/`aria-labelledby` relationships), and the `data-controller="tabs"` wrapper itself. The `tabs` Stimulus controller (`app/javascript/controllers/tabs_controller.js`) toggles `hidden` on panels and swaps active/inactive CSS classes on click. Active/inactive/underline styling is shared with `Core::SubmenuComponent` via `Core::SubmenuStyles`. The two are siblings: submenu renders links that navigate to other pages, tabs render buttons that switch panels in place.

## Auto-refresh

A widget with `refresh_interval` gets `data-controller="auto-refresh"` on its turbo frame via `DashboardHelper#auto_refresh_data`.

## Charts

Analytics widgets build an options hash with `Dashboard::ChartOptions` (`donut`, `bar`, `column`) and render `Adminit::Dashboard::ChartComponent` with it — never hand-roll a `tag.div` with chart data attributes. `_semanticColors` maps status names to the theme palette (`CHART_STATUS_COLORS`).

## Widget data — the query rule

**ViewComponents never write ActiveRecord queries.** Widget data comes from model scopes or class
methods (`Announcement.upcoming_scheduled`, `Support::Ticket.recent_open`, `Account.dashboard_stats`).
`app/queries/` is not used — a standalone query object is only justified when a query is genuinely
reusable across domains. Coverage for these scopes lives in the model specs.

## Current widgets

| Key | Resource | Kind | Span | Notes |
|---|---|---|---|---|
| `accounts_general` | account | general | full | Eager (`lazy: false`): TomSelect search by email; the selected account's summary loads server-side into the `account_summary` turbo frame (`GET adminit/dashboard/accounts/:id/summary`). |
| `accounts_analytics` | account | analytics | full | Area chart — accounts over time. Data: `Account.dashboard_stats`. Refreshes every 120 s. |
| `roles_general` | role | general | half | Roles table: name (link), account count, comma-separated permissions. Data: `Role.with_accounts_count`. |
| `announcements_general` | announcement | general | full | Split widget: left half is a list of the next 5 upcoming scheduled announcements (title link + scheduled date), right half is the same status radial chart. Data: `Announcement.upcoming_scheduled` / `Announcement.dashboard_stats`. |
| `tickets_personal` | ticket | personal | full | Open tickets assigned to current account (`Support::Ticket.assigned_open_for`). Refreshes every 30 s. The card's "view all" link points to `assignee=me` via `view_all_params`. |
| `tickets_general` | ticket | general | full | All open tickets (`Support::Ticket.recent_open`). Refreshes every 30 s. |
| `tickets_analytics` | ticket | analytics | full | Column chart — tickets by status (`Support::Ticket.dashboard_stats`). Refreshes every 60 s. |

## Adding a widget

1. Create `app/components/adminit/dashboard/<resource>/<kind>_widget_component.{rb,html.erb}`.
2. `WidgetRegistry.register(...)` it in `app/lib/dashboard/widgets.rb` (or run the `pro_rails:dashboard_widget` generator, which does both). Set `span:` once for the resource (all widgets in the same resource should use the same value; omit for `:full` default). Add `refresh_interval:`, `lazy: false`, and/or `view_all_params:` if needed.
3. Read data through model scopes/class methods — never query in the component.
4. Grant it by adding its `key` to a role's `dashboard_widget_keys` (Adminit → Permissions).

## Removing a widget

Delete the component files, its registration in `app/lib/dashboard/widgets.rb`, its i18n keys, and its specs. Stale keys left in `permissions_roles.dashboard_widget_keys` are harmless — every read path filters through the registry — but prune them with a one-off data migration or console pass (`keys & WidgetRegistry.all_keys`) to keep the data honest.
