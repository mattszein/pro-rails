# Pro Rails

> ⚠️ Pre-1.0 — actively evolving. Expect breaking changes until the first stable release.

A production-ready Rails 8 starter template built for real-world web products. This is the foundation I use to launch applications that need authentication, role-based access control, real-time features, background jobs, and clean architecture from day one.

The goal: skip the weeks of boilerplate setup on every new project and start building what actually matters. Every pattern and feature in this template is a deliberate choice, showing how authentication, authorization, real-time, background jobs, and UI components fit together in a clean, maintainable way. Designed for products with global users in mind, with the architecture decisions already made and working as a reference for how a well-structured Rails app fits together.

## What's included

### Authentication — [Rodauth](https://rodauth.jeremyevans.net/)

Full auth flow out of the box: multi-phase login, email verification, password reset, magic links, and remember me. Rodauth runs as Rack middleware, entirely separate from Rails, no monkey-patching, no engine magic.

### Authorization — [ActionPolicy](https://actionpolicy.evilmartians.io/)

Policy-based authorization and a custom RBAC system for the admin area ("Adminit"), with roles and permissions stored in the database and fully manageable at runtime.

### Admin Panel — Adminit

A built-in admin area with role and permission management, announcement broadcasting, ticket management, and account administration. No admin gem, no DSL to learn, no fighting a framework to get the UI you need... it's just Rails! Every feature is plain controllers, views, and policies that you can read, change, and extend like any other part of the app. Add the resources your product actually needs without working around opinionated constraints.

### Real-time — [AnyCable](https://anycable.io/) + Hotwire

AnyCable replaces Action Cable with a standalone WebSocket server written in Go, backed by Redis pub/sub. It handles far more concurrent connections at far lower memory usage than the Rails-native alternative. JWT authentication is configured for secure stream verification without round-tripping Rails. Turbo Streams and Stimulus handle the frontend reactivity without a JS framework.

### Background Jobs — [Solid Queue](https://github.com/rails/solid-queue)

Database-backed job queue powered by PostgreSQL. No Redis needed for jobs. Jobs are visible, inspectable, and transactional. Mission Control provides a web UI to monitor, retry, and manage jobs.

### Workflow Logic — [Interactor](https://github.com/collectiveidea/interactor)

Workflow orchestration lives in interactors, not controllers or models. Each interactor does one thing: coordinates a sequence of steps, triggers side effects (jobs, notifications, external APIs), and returns a success/failure context. Models stay clean, controllers stay thin.

### UI Components — [ViewComponent](https://viewcomponent.org/)

A fully custom component library built in-house — no third-party component gem. Core UI components cover the common building blocks: cards, badges, avatars, alerts, modals, and more. A separate set of core form components (inputs, textareas, selects, multi-selects, toggles, checkboxes, code inputs, buttons) is exposed through a custom `FormBuilder` set as the application default, so you get consistent, component-backed forms everywhere without passing any extra options. All components are previewed in development via Lookbook at `/lookbook`.

### Notifications — [Noticed](https://github.com/excid3/noticed)

Multi-channel notification delivery (email + real-time Turbo Stream, and more).

### Frontend — Hotwire + TailwindCSS 4 + Propshaft

No webpack, no Node build step for the asset pipeline. Propshaft keeps assets simple. TailwindCSS 4 with a clean component-driven structure. Turbo handles page transitions and frame/stream updates. Stimulus for the small JS behaviors that remain.

### Internationalization

I18n support wired up from the start, with locale files organized by domain.
Coming soon.

### Configuration — [Anyway Config](https://github.com/palkan/anyway_config)

Typed configuration classes instead of scattered `ENV[]` calls. Loads from environment variables, Rails credentials, or YAML.

### Testing — RSpec + FactoryBot + Capybara/Cuprite

Full test suite with model specs (Shoulda-Matchers), request specs, policy specs, interactor specs, and system tests running against a real Chromium browser via Cuprite.

### Support Tickets

A full ticket support system built into the app: users can open tickets, and admins handle them from the admin side. Each ticket has a real-time conversation thread powered by AnyCable and Turbo Streams, so both sides see messages appear instantly without a page reload. Designed as a reference implementation of real-time chat you can adapt or extend.

### Appearance & Theming

Users can personalize the look of the application to their preference. The app ships with 40 themes and 8 font choices, each with predefined primary and secondary color palettes. The goal is comfort and accessibility giving users meaningful control over their visual experience.

### Code Quality — [RuboCop](https://rubocop.org/) + [Standard](https://github.com/standardrb/standard)

RuboCop with Standard extended. Brakeman scans for security vulnerabilities. ERB templates are kept clean via a `./erb_linter.sh` script that runs both `htmlbeautifier` (to normalize formatting) and `erb_lint` (to catch issues) in one pass. Freezolite auto-adds `frozen_string_literal: true` across the codebase.

---

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed patterns, conventions, and decision frameworks.

---

## Roadmap to 1.0

### Setup & documentation

- [x] README
- [ ] Credentials: define defaults and document how to use Rails credentials across environments
- [x] Remove view components form gem
- [ ] Add basic setup instructions to start the app locally (database setup, credentials, etc), create script for db setup and seeding.

### Internationalization

- [ ] Add a second locale (non-English) to validate the i18n setup end-to-end
- [ ] Replace hardcoded strings across views and mailers with i18n keys

### Announcements

- [ ] Email template for announcement notifications
- [x] Rich text support via ActionText. Test Lexxy. Add reference.

### Support tickets

- [ ] Expand ticket states beyond `open / in_progress / closed` — add `initial`, `reopened`, and others as needed.
- [ ] User that opened a ticket only can send messages in the conversation when is in_progress.
- [ ] Add notes (only admins can create them, visualize and delete them, normal users cant see them) to a ticket.
- [ ] Add tickets references. You can link ticket to others that has the same root problem and solution!

### Architecture & refactoring

- [x] Upgrade all gems to latest versions
- [ ] Base controller shared between Adminit and Dashboard to reduce duplication
- [ ] Adminit menu: replace `allowed_to?` iteration in the view with a helper that resolves permitted items for the current user
- [ ] Permissions: replace string-based controller references with integer enums
- [ ] Generator: scaffold a new Adminit resource (controller, views, policy, and specs) in one command
- [ ] Adminit dashboard: analytics, stats, and quick actions, with role-specific views per role
- [x] Refactoring view components to use same patterns
- [ ] Table component should support sorting, filtering, and pagination (client vs server ?)
- [ ] Fix old adminit components (Roles views, account views)
- [ ] Components should be refactored to use primary / secondary colors? messages in conversation, box component, notifications
- [ ] Lookbook: update previews to cover all core components and recently added features

### Accounts

- [ ] Add profile with avatar upload
- [ ] Add AI(rubyllm) to make an example for an image generation for the account avatar

## Roadmap to 2.0

### Payments & subscriptions

- [ ] Plans model and subscription management
- [ ] Stripe and others payments integration (charges, webhooks, billing portal)

### Ticket support

- [ ] Conversation chat is managed by AI at beginning. Admnins can take over the
conversation at any time, and the AI will step back until the next ticket is
opened.

--

## Contributing

1. Follow the existing code patterns and architecture (see [ARCHITECTURE.md](ARCHITECTURE.md))
2. Write tests for new features
3. Run the linter and fix any issues before committing (`bin/rubocop -a`)
4. Ensure all tests pass (`bundle exec rspec`)
5. Update documentation for significant changes

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
