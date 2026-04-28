---
kind: context
id: user_personas
version: 1
source_id: pro_rails_docs
source_ref: context/product/user-personas.md
domain: product
audience: [product_manager]
topics: [user-personas, personas, users]
references: [product_overview]
stability: stable
---

# User Personas (Pro-Rails)

## Regular User

A person with an account who uses the product's core features. They signed up, verified their email, and interact with the app day-to-day.

**What they can do:**
- Log in with email and password, or via a magic link
- Create support tickets, attach files, and track progress
- Send messages in an open conversation thread
- Request to reopen a finished ticket with a reason
- Receive notifications (in-app and email) and mark them read
- Manage their profile: avatar, username, bio
- Personalize the app's appearance: color theme, font, dark mode
- Switch the interface language

**Pain point addressed:** They need a way to reach support and stay informed about their requests without manually refreshing pages or sending emails.

## Admin

A team member with elevated access to manage the product and help users.

**What they can do:** Everything a Regular User can do, plus:
- Take and leave assignment on support tickets
- Mark tickets as finished or reject reopen requests
- Add internal notes to tickets (visible only to other admins)
- Delete tickets
- Create, schedule, and publish announcements to all users
- View all accounts: details, role assignments, activity

**Pain point addressed:** They need to manage customer requests efficiently, communicate important updates, and see what's happening across the user base — without a custom-built admin interface.

## Super Admin

A team member with full administrative authority, including the ability to manage who has admin access.

**What they can do:** Everything an Admin can do, plus:
- Create and manage roles (membership, naming)
- Assign or revoke admin permissions per resource
- View and edit all role-permission mappings

**Pain point addressed:** Someone needs to be able to configure who can do what in the admin area without a code change or a developer's help. Permissions need to be adjustable at runtime as the team grows or responsibilities shift.

---

## How personas interact

The three personas do not interact in parallel — they are the same users in different contexts. A Regular User submits a support ticket. An Admin sees it, takes ownership, and resolves it. A Super Admin determines which people have Admin access and what each resource area they can manage.

Understanding which persona is affected by a feature helps define scope: a feature that benefits only Admins does not need a user-facing entry point. A feature that changes what Regular Users can do may require admin visibility into that change. A feature that adjusts permissions affects only Super Admins — and the Admins whose access changes as a result.
