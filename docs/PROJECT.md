# Pro-Rails

A Rails 8 application template for teams building production apps fast. Ships with authentication, role-based access control, a support ticket system, notifications, and real-time updates — so you start building features on day one, not infrastructure.

## Vision

Pro-Rails is a **foundation**, not a framework. It provides the infrastructure every production app needs (auth, admin, notifications, real-time) so teams skip the first 2-3 months of boilerplate and start building their actual product.

**What it IS**: A production-ready starting point with opinions on architecture, patterns, and tooling. Each feature is complete enough to use as-is but designed to be extended or replaced.

**What it is NOT**: A SaaS boilerplate (no billing, no multi-tenancy, no onboarding flows). Not a learning project — it assumes the team knows Rails. Not a framework — you own the code, there's nothing to "upgrade."

**Where it's going**: More built-in features that every production app needs (audit logging, advanced search, file management, API layer). Better developer tooling (generators, CLI skills). Always Rails-native — no bolt-on ecosystems.

## Target Audience

Development teams (2-10 engineers) building business applications that need: user management, admin panels, real-time features, and multi-language support.

---

## Existing Features

### Authentication

Multi-method login system with full account lifecycle:

- **Email + password login** — multi-phase flow (enter email first, then password)
- **Magic link login** — passwordless authentication via email link
- **Remember me** — persistent login across sessions
- **Account verification** — email confirmation after registration
- **Password reset** — email-based recovery flow
- **Change email** — with re-verification
- **Change password** — from account settings
- **Close account** — password confirmation required, permanent

### Admin Panel (Adminit)

A built-in admin area — no admin gem, no DSL, just plain Rails controllers and views. Fully manageable roles and permissions at runtime.

**Accounts management**:
- List all accounts with pagination
- View account details (email, role, status, profile info, session expiry)
- View account activity (tickets created, tickets assigned)
- Delete accounts

**Roles management**:
- List roles with their members and permissions
- Add/remove members (search by email)
- Manage role-permission associations
- Superadmin designation

**Permissions management**:
- View all permissions with assigned roles
- Update role-permission mappings per resource

**Three-layer access control**: account must have a role → role must have adminit access → role must have permission for the specific resource.

### Support Tickets

Full ticket support system with real-time conversations between users and admins.

**What users can do**:
- Create tickets with title, description, and category (Account Access, Technical Issue, Billing, Feature Request, Other)
- Attach files to tickets (configurable limits on count, size, and content types)
- Send messages in the conversation thread (when ticket is in progress or reopened)
- Request to reopen a finished ticket with a reason
- View full conversation history

**What admins can do**:
- Take/leave assignment of tickets
- Set priority (1–5 scale)
- Mark tickets as finished
- Accept or reject reopen requests (with reason)
- Add internal notes (visible only to admins)
- Delete tickets

**Ticket lifecycle**:
```
open → in_progress → finished → closed
                  ↘ reopen_requested → reopened → (back to in_progress)
                                     → closed (if rejected)
```

All conversation updates appear in real-time — no page reload needed.

#### AI assistant

An optional assistant answers the start of each conversation, then hands the ticket to a person. It is **off by default**: a global kill switch (`SupportAiConfig.enabled`, env `SUPPORT_AI_ENABLED`) plus an `OPENROUTER_API_KEY` turn it on. With the switch off, tickets behave exactly as before.

**What users see**:
- An assistant banner on the ticket while the AI is engaged, with a typing indicator while it works
- AI replies in the conversation thread, labelled as the assistant, with suggested help-center article cards
- **This solved it** — resolves the ticket without a person; **Talk to a person** — asks for a human at any time
- A handoff message when a person is needed (the assistant escalates, the turn limit is reached, or the AI is unavailable). Users are never left waiting: if the AI fails after retries the ticket is handed off with a generic message

**What admins see** (ticket permission, plus `support_ai` for playbooks):
- An **AI state** badge on tickets (list and detail), and AI-authored internal notes (investigation findings, handoff summary)
- An **AI activity** panel per ticket (every step: model, tokens, latency, tool calls, errors)
- **Take over from AI** — assigning a ticket (or the Take action) makes the AI step back for good on that ticket
- A **Needs human** filter and a dashboard tile counting tickets waiting on a person
- Handed-off tickets surface only through the **Needs human** tile and filter; no notification or email is sent

**AI playbooks** (Adminit, `support_ai` permission, Super Admin by default) decide what the assistant does for which tickets:
- **Conditions**: ticket categories, priority range, and optionally an audience (see Feature Flags). The first enabled playbook that matches wins, in the order shown (reorderable); otherwise the **default playbook**, which always exists, cannot be deleted or moved, and is evaluated last
- **Mode**: `triage_only` (analyze, set priority, write notes, then hand off without replying to the user) or `assist` (also answers the user, up to a maximum number of AI turns)
- **Capabilities**: switchable tools and actions per playbook (account facts, past tickets, similar tickets, article search, investigation note, auto-set priority, auto-correct category, suggest articles, propose resolution, request human, vision on attachments)
- Custom instructions, idle reminder and idle handoff timers, enable/disable per playbook

**AI state vs. status** — the AI state is a second axis next to the ticket status; the status lifecycle above is unchanged:

| AI state | Meaning | Who owns the conversation |
|----------|---------|---------------------------|
| `off` | No AI on this ticket (switch off, no playbook, or ticket predates the feature) | Person |
| `analyzing` | Triage / reply in progress | AI |
| `awaiting_user` | AI replied and waits for the user | AI |
| `handoff_requested` | AI asked for a person; shown in Needs human | Person (when taken) |
| `stepped_back` | An admin took over | Person |
| `resolved` | User clicked "This solved it" (status becomes finished) | Nobody |

A user message while `awaiting_user` returns the ticket to `analyzing`; any admin assignment moves it to `stepped_back`.

#### Knowledge base / help center

Self-service articles that deflect tickets before they are created.

**What users can do**:
- Browse and search published articles at `/help` (filter by category; results follow the current language)
- See suggested articles while filling in the new-ticket form, based on the title and category

**What admins can do** (`article` permission, Super Admin by default):
- Manage articles in Adminit (create, edit, delete) with a rich-text body
- Keep articles as **draft** or **published** (only published articles are visible in the help center)
- Set each article's locale (en/es) and category (same categories as tickets, or none for general articles)

### Notifications

Two-level notification system: quick access from the header and a full dedicated page.

**Header bell icon**:
- Shows unread count badge
- Dropdown with up to 10 most recent unread notifications
- Link to full notifications page

**Full notifications page**:
- Paginated feed of all notifications (infinite scroll)
- Mark individual notifications as read
- Mark all as read at once
- Shows unread count at top

### Announcements

Admin-to-all-users communication with scheduled publishing and rich text.

**Lifecycle**: Draft → Scheduled → Published

**Capabilities**:
- Rich text editor for content (WYSIWYG)
- Schedule for future publish date/time
- Unschedule back to draft
- Publish triggers notification to all verified accounts
- Only drafts can be deleted
- Published announcements cannot be edited

Each announcement has a reference identifier, title, and rich text body.

### Feature Flags

Operator-controlled release gates for user-facing capabilities, administered in Adminit. See
`docs/BACKEND.md` for how to declare, gate, and retire a flag and register a new audience condition,
and `docs/ARCHITECTURE.md` for the evaluation rules.

**Flag** — a switch in front of a capability that already exists in the product. Declared in code
(never created in Adminit); its access list (audiences and/or per-account allow/block entries) is
managed by admins. One demo flag (`test_feature_flag`) ships as a working example; remove it when adopting the feature, and add a flag only when a real capability needs one.

**Audience** — a named, reusable group of accounts defined by a fixed vocabulary of conditions
(Adminit access, role, email verification, account age). Outlives any one flag; archived rather than
deleted.

**Account entry** — a one-off allow or block for a single account on a single flag, independent of
any audience.

**Decision rule**: a block always wins; an explicit allow beats any audience; any matching attached
audience grants; otherwise the capability is absent — including for a flag that was never declared, a
closed account, or an evaluation that cannot complete.

### Profiles

Account profiles with editable display information:

- **Avatar upload** — supports JPEG, PNG, GIF, WebP (max 10MB), auto-generates thumbnail (100×100) and medium (300×300) variants
- **Username** — alphanumeric + underscore, unique
- **Bio** — up to 500 characters

### Appearance & Theming

Users personalize the app's look from their settings:

**40 color themes** across 5 collections:
- Tech Edge (8): Hyper, Aurora, Eclipse, Galaxy, Synth, Thunder, Matrix, Cyber
- Serene (8): Botanic, Reef, Oceanic, Forest, Dune, Mauve, Glacier, Lavender
- Cosmic (8): Nebula, Starlight, Void, Pulsar, Vapor, Prism, Comet, Royal
- Vivid (8): Sunset, Berry, Flamingo, Solar, Coral, Neon, Phoenix, Bloom
- Night Owl (8): Amber, Candle, Ember, Hearth, Vintage, Sepia, Autumn, Twilight

**8 font families**: Inter (Modern), Lora (Editorial), Space Grotesk (Cosmic), Outfit (Vivid), Jost (Elegant), Google Code (Code), Orbitron (Cyberpunk), Chakra Petch (Anime)

Each theme defines primary and secondary color palettes. Dark mode toggle available.

### Real-Time Updates

Live updates across the app without page reloads:

- Ticket conversation messages appear instantly for both user and admin
- Ticket status changes reflect in real-time
- Admin tables update when new tickets arrive
- Notifications push to the bell icon live

### Internationalization

Full bilingual support from day one:

- **English** (default) and **Spanish**
- Locale switcher in the navigation
- URL-based locale switching (`/es/dashboard` for Spanish, `/dashboard` for English)
- All user-facing content translated: labels, buttons, messages, error messages, enums
- Email communications respect the user's locale

### Component Library

37+ reusable UI components with a development preview tool (Lookbook):

**Form**: Text field, password field, text area, number field, select, checkbox, toggle, counter, date/time picker, file field, rich text area, material input, code field, button

**Layout**: Modal, drawer, sidebar, submenu, sidebar link

**Data display**: Table (with rows/cells), card, box, alert, toast, badge, avatar, definition list

**Navigation**: Link, loader, dark/light mode toggle, locale switcher

All form components are exposed through a custom FormBuilder — consistent component-backed forms everywhere without extra configuration.

---

## Domain Model

```
Account
  ├── Profile (avatar, username, bio)
  ├── Role ←→ Permissions (per-resource access)
  ├── Notifications
  ├── Support::Tickets (as creator)
  └── Support::Tickets (as assignee)

Support::Ticket (status lifecycle + ai_state)
  ├── Support::Conversation
  │   └── Support::Messages (sender: human | ai; AI messages have no account)
  ├── Support::Notes (internal, admin-only; kind: internal | system | ai)
  ├── Support::AiRun (one row per AI step: model, tokens, latency, tool calls, error)
  ├── belongs_to Support::AiPlaybook (the playbook that handled it)
  └── File Attachments

Support::AiPlaybook (conditions, mode, capabilities, limits; optional Audience)
  └── has_many Support::AiRuns, Support::Tickets

Announcement
  └── belongs_to Author (Account)

Support::Article (help center)
  └── belongs_to Author (Account)

Role ←→ Permissions
```

### Key Relationships

- An Account can be both a ticket **creator** and a ticket **assignee** (two foreign keys)
- Roles and Permissions are many-to-many
- Support models are namespaced under `Support::` with simple table names
- Permission resources are integer-backed — values must never be reused
- AI-authored messages and notes have no author account (`account_id` is NULL); a DB check constraint ties `sender` to `account_id` on messages

---

## User Personas

| Persona | Access | Can Do |
|---------|--------|--------|
| **Regular User** | Dashboard | Login (password or magic link), browse the help center, create tickets, send messages, attach files, request reopens, get first answers from the AI assistant (when enabled), view notifications, manage profile (avatar, username, bio), customize appearance (40 themes, 8 fonts, dark mode), switch language |
| **Admin** | Dashboard + Adminit | All user actions + take/finish/reopen tickets, set priority, add internal notes, take over from the AI and handle "Needs human" tickets, manage announcements (create, schedule, publish), view accounts (help center articles and AI playbooks are Super Admin by default) |
| **Super Admin** | Dashboard + Adminit (all) | All admin actions + manage roles (add/remove members), manage permissions (role-resource mappings) |

---

## Tech Stack Decisions

| Decision | Choice | One-Line Rationale |
|----------|--------|-------------------|
| Database | PostgreSQL | Relational integrity, JSON support, horizontal scaling |
| Auth | Rodauth | Feature-complete (verification, MFA-ready, magic links) without reinventing |
| Authorization | ActionPolicy | Policy objects with scoping, integrates with Rails conventions |
| Workflows | Interactor gem | Explicit, testable, reusable orchestration units for multi-step operations |
| Background Jobs | Solid Queue | Database-backed (PostgreSQL), no Redis dependency for jobs, Rails 8 default |
| WebSockets | AnyCable | 10x throughput over Action Cable, required for horizontal scaling |
| Cache | Redis | Fast key-value store for caching and sessions |
| CSS | TailwindCSS 4.2 | Utility-first, fast to build, consistent design tokens |
| Assets | Propshaft + Importmap | No Node.js build step, Rails-native asset pipeline |
| Components | ViewComponent | Testable, encapsulated UI units with Lookbook previews |
| Config | Anyway Config | Typed configuration classes with IDE support |
| Notifications | Noticed gem | Multi-channel delivery (in-app, email) with background processing |
| Testing | RSpec + FactoryBot | Expressive DSL for complex test scenarios |
| Linting | Standard Ruby | Zero-config Ruby style, consistent across team |
| Security | Brakeman | Static analysis for security vulnerabilities |
| Frozen Strings | Freezolite | Auto-adds frozen_string_literal without manual annotations |
