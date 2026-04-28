---
kind: context
id: feature_catalog
version: 1
source_id: pro_rails_docs
source_ref: context/product/feature-catalog.md
domain: product
audience: [product_manager]
topics: [feature-catalog, features, product]
references: [product_overview, user_personas]
stability: stable
---

# Feature Catalog (Pro-Rails)

## Authentication

Users log in with email and password via a two-step flow (enter email first, then password). Magic link login is also available — receive a link by email and click to authenticate with no password required. Accounts are verified by email after registration. Users can reset their password, change their email (with re-verification), and close their account permanently. A "remember me" option keeps sessions alive across browser closes.

## Admin Panel

The admin area gives designated team members control over the platform. Admins can view, search, and manage all accounts. Roles are named groups of permissions — admins can add or remove members from roles and control which resources each role can manage. Permissions are organized by resource area; the mapping between roles and permissions is editable at any time without a product update. Access to the admin area requires an assigned role.

## Support Tickets

Users submit support requests with a title, description, category, and optional file attachments. Admins can take ownership of a ticket, exchange messages with the user in real time, set a priority level, add private internal notes, and mark the ticket as finished. Users can request to reopen a finished ticket with a written reason; admins can accept or reject the request. All conversation activity appears live without a page reload.

## Announcements

Admins write announcements with a rich text editor. Announcements can be saved as drafts, scheduled for a future date and time, or published immediately. Once scheduled, the publish date cannot be changed without first reverting to draft. Published announcements are permanent — they cannot be edited or deleted. Publishing triggers a notification to all verified users.

## Notifications

Users receive in-app and email notifications for relevant events. A bell icon in the navigation header shows the unread count and a dropdown with recent notifications. A dedicated notifications page shows the full history with infinite scroll, individual mark-as-read, and a mark-all-as-read action.

## Profiles

Each account has a profile with an avatar, username, and bio. Avatars are uploaded images; the system generates thumbnail and medium-size variants automatically. Usernames are unique across the platform and follow a simple format.

## Theming

Users can personalize the app's visual appearance from their settings. There are 40 named color themes organized into five collections (Tech Edge, Serene, Cosmic, Vivid, Night Owl) and eight font family options ranging from modern to editorial to cyberpunk. Each user's preference is stored per account and applied on every page load. A dark mode toggle is also available.

## Internationalization

The entire user interface is available in English and Spanish. Users switch languages via a control in the navigation. The chosen language is reflected in the URL (`/es/` for Spanish, no prefix for English). All labels, buttons, messages, error text, and email content are translated. Adding support for additional languages in the future requires only translation files, not code changes.

## Real-Time Updates

Changes appear live throughout the product without requiring a page reload. Ticket conversation messages appear instantly for both the user and the admin. Ticket status changes reflect in real time on both sides. The admin ticket list updates when new tickets are submitted. Notification counts update in the header as events occur. None of this requires the user to take any action — the live updates are always on.

## Component Library

Over 37 reusable interface components ship with the product, available through a visual
preview tool in the development environment. Form inputs, layout containers, data display
elements, and navigation components are all included. Forms across the product are
consistent because all inputs are drawn from the same component set — the same button,
the same text field, everywhere. New screens built on the product automatically inherit
the existing visual language.

## Support for Future Growth

Pro-Rails is designed as a foundation, not a ceiling. The existing feature set is a
starting point. The architecture was chosen specifically to make adding new features
straightforward: new admin resources follow an established pattern, new notification
channels add a single class, new themes add a single file. Teams extend the product
rather than work around it.
