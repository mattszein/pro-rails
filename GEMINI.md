# Gemini CLI Project Guide: Pro-Rails

This document provides project-specific instructions and context for Gemini CLI. It takes precedence over general defaults.

**References:** See [ARCHITECTURE.md](ARCHITECTURE.md) for deep architectural patterns and [CLAUDE.md](CLAUDE.md) for general developer guidance.

## Project Essence
A modern Rails 8.0 application using Hotwire, ViewComponent, and a strict layered architecture (Model/Controller/Interactor).

## Technical Stack
- **Framework**: Rails 8.0.2 (PostgreSQL)
- **Frontend**: Hotwire (Turbo/Stimulus), TailwindCSS 4.2, ViewComponent
- **Logic**: Interactor gem for workflow orchestration
- **Auth**: Rodauth (Authentication), ActionPolicy (Authorization)
- **Jobs/Messaging**: Solid Queue (PostgreSQL-backed), AnyCable (WebSockets)
- **Quality**: Standard Ruby (RuboCop), Brakeman, RSpec, Freezolite (auto frozen_string_literal)

## Architectural Mandates

### 1. The Three Layers
| Layer | Responsibility | Allowed Side Effects |
|-------|----------------|----------------------|
| **Model** | Data integrity, state transitions (`publish!`) | None (no jobs, no emails) |
| **Controller** | HTTP, Authz, simple CRUD | Redirects, renders |
| **Interactor** | Workflow, multi-step operations | Jobs, notifications, broadcasts |

### 2. Model Patterns
- **Transition Methods**: Define as `transition!`. They MUST NOT trigger side effects.
- **Query Methods**: Define `editable?`, `destroyable?` for UI/guard logic.
- **Validations**: Use `status_was` to validate state transitions.
- **Destroy Protection**: Use `before_destroy` callbacks to prevent invalid deletions.
- **Namespace**: Use `Support::` for domain-specific models (Ticket, Conversation).

### 3. Interactor Patterns
- Use for any action with side effects (sending mail, enqueuing jobs).
- Handle `ActiveRecord::RecordInvalid` and `Model::InvalidTransition` by calling `context.fail!`.
- **Transaction Caution**: Solid Queue uses a separate DB. Transactions on the primary DB will NOT rollback job enqueues.

### 4. View & Component Patterns
- **ViewComponents**: Primary UI building block. Located in `app/components/core/`.
- **Forms**: Always use `CustomFormBuilder` (default). It renders Material components automatically.
- **Broadcasting**: Use `broadcasts_to` in models ONLY for simple CRUD sync. Use Interactors for complex or conditional broadcasts.

## Development & Validation Workflow

### Essential Commands
- **Setup**: `bin/setup`
- **Run**: `bin/dev`
- **Test**: `bundle exec rspec`
- **Lint**: `bin/rubocop -a` (Standard Ruby)
- **Security**: `bin/brakeman`
- **ERB Lint**: `./erb_linter.sh`

### Testing Requirements
- **Reproduction**: Always write a failing spec before fixing a bug.
- **Coverage**: Every new feature needs Model (validations/logic), Interactor (workflow), and Request/System (integration) specs.
- **Auth in Tests**: Rodauth doesn't run in controller specs; use `login_as(account)` and ensure `before_action :require_account` is in the controller.

## Critical Gotchas
- **Frozen Strings**: `Freezolite` adds `frozen_string_literal: true` automatically.
- **Unprocessable**: Use `status: :unprocessable_content` (not `:unprocessable_entity`).
- **DOM ID**: `dom_id` is NOT available in models. Use `ActionView::RecordIdentifier.dom_id(record)`.
- **Permissions**: Adminit permissions use policy identifiers as symbols (e.g., `:"Adminit::AccountPolicy"`). Policies must define `self.identifier`.
- **STI Policy**: Use `a_kind_of(Class)` in ActionPolicy matchers for STI models.
