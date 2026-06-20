---
kind: context
id: product_overview
version: 1
source_id: pro_rails_docs
source_ref: context/product/product-overview.md
domain: product
audience: [product_manager, architect]
topics: [product-overview, product, vision, features]
references: []
stability: stable
---

# Product Overview (Pro-Rails)

## What Pro-Rails is

A production-ready foundation for teams building business applications. Ships with the infrastructure every business app needs — authentication, admin panel, support system, notifications, real-time updates — so teams start building their actual product on day one, not infrastructure.

It is a **starting point with opinions**, not a framework. The team owns the code. There is nothing to upgrade.

## What Pro-Rails is NOT

- Not a SaaS boilerplate. No billing, no subscription management, no onboarding funnels.
- Not multi-tenant. One database, one app, one account space.
- Not a learning toy. It assumes the team is experienced and building something real.
- Not a framework you depend on. You clone it and own it.

## Who it's for

Small product teams of 2–10 people building business applications that need user management, role-based administration, customer support, and real-time features. The typical user has built apps before and wants to skip the first two to three months of plumbing.

## What ships out of the box

- **Authentication** — multi-method login with email verification, magic links, and account recovery. Users manage their own credentials and session settings.
- **Admin panel** — role and permission management, account oversight. Admins see what users can't. Permissions are configurable at runtime without a product update.
- **Support tickets** — full lifecycle from open to closed, with real-time conversation threads, file attachments, and a reopen flow for finished tickets.
- **Announcements** — admins draft, schedule, and publish messages to all users. Scheduling with rich text content and automatic notification delivery.
- **Notifications** — in-app and email, delivered when relevant events happen. Header bell with unread count and a paginated history page.
- **Profiles** — per-user avatar, username, and bio. Visible to others in the product.
- **Theming** — 40 color themes, 8 font families, and a dark mode toggle. Each user sets their own preference.
- **Internationalization** — English and Spanish from day one. URL-based locale switching so links are shareable in the right language.
- **Real-time** — live updates across tickets, messages, admin tables, and notifications without page reloads.

## What comes next

Pro-Rails is designed to grow. The foundation is in place for audit logging, advanced
search, file management, and an API layer. Developer tooling (generators, CLI) is also
on the roadmap. The pattern is always Rails-native — no bolt-on ecosystems.

## Design philosophy

Every feature that ships is complete enough to use in production but designed to be
extended or replaced. Nothing is bolted on with a gem that wraps your own code and
makes it hard to customize. The admin panel is regular Rails controllers. The
authentication is Rack middleware. The component library is ViewComponents you can
inspect and modify directly.

This means a team of two engineers can understand the entire codebase in a day, extend
any feature without fighting a framework, and replace parts they disagree with without
ripping out a dependency tree.

The trade-off: there is no upgrade path. You fork Pro-Rails, take ownership, and evolve
it with your product. That is a deliberate choice, not a limitation.
