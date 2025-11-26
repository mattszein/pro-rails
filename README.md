# Pro-Rails

A modern Rails 8.0 application showcasing best practices with Hotwire, ViewComponent architecture, and a comprehensive role-based access control (RBAC) admin system.

## Table of Contents

- [Tech Stack](#tech-stack)
- [Development Workflow](#development-workflow)
- [Architecture Patterns](#architecture-patterns)
- [Getting Started](#getting-started)
- [Testing](#testing)
- [Code Quality](#code-quality)
- [Deployment](#deployment)

## Tech Stack

### Core Framework

**Rails 8.0.2** with PostgreSQL 17 - Ruby 3.4.4

### Frontend Stack

**Hotwire (Turbo + Stimulus)**

- Server-rendered HTML with Turbo Drive, Frames, and Streams
- Stimulus controllers for interactive components
- No heavy JavaScript framework needed

**TailwindCSS 4.2**

- Utility-first CSS framework
- Custom configuration for component styling

**ViewComponent Architecture**

- Component-based UI development
- Custom form builder with specialized components
- Lookbook for component previews (available at `/lookbook` in development)
- Components organized in `app/components/core/`

**Propshaft**

- Modern asset pipeline replacement for Sprockets
- Faster and simpler asset handling

### Authentication

**Rodauth**

- Flexible authentication framework configured in `app/misc/rodauth_main.rb` and `app/misc/rodauth_app.rb`
- Email-based authentication with multi-phase login
- Features: account creation, verification, login/logout, remember me, password reset, password change, login change, account closure, email auth
- Account statuses: unverified (1), verified (2), closed (3)
- Current user available as `rodauth.rails_account` or `current_account`

### Authorization

**ActionPolicy**

- Policy-based authorization with granular permission control
- Custom RBAC (Role-Based Access Control) system
- Resource-based permissions via `Permission` model
- Adminit admin area with specialized policies in `app/policies/adminit/`
- Permission checks: `user.role.permissions.exists?(resource: key)`
- "superadmin" role with elevated privileges

### Configuration Management

**Anyway Config**

- Type-safe configuration classes
- Environment-based settings
- Configuration files in `config/configs/`

### WebSockets

**AnyCable**

- High-performance Action Cable replacement
- Redis-backed for horizontal scaling
- Separate WebSocket server for better performance
- Turbo Streams support enabled

### Testing

**RSpec** with comprehensive tooling:

- FactoryBot for test data generation
- Shoulda-Matchers for model validation tests
- Capybara + Cuprite (Chrome headless) for system tests
- TestProf for test performance analysis
- ActionPolicy RSpec matchers
- Custom login helpers for authentication testing

### Code Quality

**Standard Ruby**

- Ruby linter based on RuboCop
- Consistent code style enforcement

**Brakeman**

- Security vulnerability scanner
- Integrated into CI pipeline

## Development Workflow

### Docker-Based Development

This project uses Docker as the primary development workflow, providing a consistent environment across all development machines.

**Architecture:**

- `rails` service: Main Rails application server (port 3000)
- `db` service: PostgreSQL 17.5 database with health checks
- `redis` service: Redis 8.2.0 for caching and job queues
- `ws` service: AnyCable-Go WebSocket server (ports 8080, 8090)
- `maildev` service: Development mail server with web UI (ports 1025, 8025)
- `chrome` service: Browserless Chrome for system tests
- `test_system` service: Dedicated service for running system tests

**Key Features:**

- Persistent volumes for database, gems, cache, and command history
- Health checks ensuring services start in correct order
- Hot reloading with volume mounts for live code updates
- Shared command history across container restarts (bash, irb, psql)
- Isolated test environment with separate AnyCable instance

**Volume Persistence:**

- Database data persists across container restarts
- Bundler gems cached for faster rebuilds
- Asset builds and cache preserved
- Shell history maintained for better developer experience

### Quick Start with Docker

```bash
# Build and start all services
docker-compose up

# Run commands in the Rails container
docker-compose exec rails bash
docker-compose exec rails bundle exec rails c
docker-compose exec rails bundle exec rspec

# View logs
docker-compose logs -f rails
docker-compose logs -f ws

# Stop all services
docker-compose down

# Reset everything (including volumes)
docker-compose down -v
```

## Architecture Patterns

### ViewComponent with Custom Form Builder

Pro-Rails uses a component-based architecture for all UI elements. The `CustomFormBuilder` extends `ViewComponent::Form::Builder` to provide a consistent, reusable component library.

**Available Form Components:**

- `form.text_field`, `form.password_field`, `form.number_field` → MaterialInput component
- `form.text_area` → TextArea component
- `form.button` → Button component (supports theme, size, fullw options)
- `form.toggle`, `form.check_box` → Toggle/CheckBox components
- `form.labeled` → Labeled wrapper component
- `form.code` → Code input component
- `form.counter` → Counter component

**Example:**

```erb
<%= form_with model: @user, builder: CustomFormBuilder do |form| %>
  <%= form.text_field :email, label: "Email Address" %>
  <%= form.password_field :password, label: "Password" %>
  <%= form.button "Sign In", theme: :primary %>
<% end %>
```

Components are organized in `app/components/core/` with corresponding CSS and JavaScript in component directories. All components are autoloaded and can be previewed in Lookbook during development.

### RBAC Admin System (Adminit)

Adminit is a custom admin area with fine-grained role-based access control.

**Structure:**

- Routes: `/adminit` (see `config/routes/adminit.rb`)
- Base controller: `Adminit::ApplicationController` with authorization checks
- Manages: accounts, tickets, roles, permissions

**Authorization Flow:**

1. Account must have a role assigned to access Adminit (`Account#adminit_access?`)
2. Role has many permissions via `permissions_roles` join table
3. Permission resources identified by policy class (e.g., `:"Adminit::ApplicationPolicy"`)
4. Controllers use `authorize!` to check permissions
5. Views use `allowed_to?` for conditional rendering

**Models:**

- `Account`: User model with Rodauth integration, belongs_to role
- `Role`: has_many accounts, has_and_belongs_to_many permissions
- `Permission`: has_and_belongs_to_many roles, resource-based authorization

### Hotwire Integration

**Stimulus Controllers:** Progressive JavaScript enhancement

- Controllers in `app/javascript/controllers/`
- Automatically connected via Stimulus
- Used for interactive components

### AnyCable WebSockets

AnyCable replaces default Action Cable for better performance and scalability.

**Key Benefits:**

- Language-agnostic WebSocket server (written in Go)
- Better performance under high concurrent connections
- Horizontal scaling with Redis backend
- Compatible with Action Cable API

**Configuration:**

- Rails integration: `config/cable.yml`
- Redis channel: `__anycable__`
- Turbo Streams enabled by default

### Configuration with Anyway Config

Type-safe configuration management using the Anyway Config pattern.

**Example:**

```ruby
class ApplicationConfig < Anyway::Config
  attr_config :feature_flag, :max_uploads

  required :feature_flag
end

# Usage
ApplicationConfig.new.feature_flag
```

Configuration classes in `config/configs/` provide environment-based settings with validation and defaults.

## Getting Started

### Prerequisites

**With Docker (Recommended):**

- Docker Desktop or Docker Engine + Docker Compose
- No Ruby, PostgreSQL, or Redis installation needed

**Without Docker:**

- Ruby 3.4.4
- PostgreSQL 17+
- Redis 8.2+

### Installation

**Docker Setup:**

```bash
# Clone the repository
git clone <repository-url>
cd pro-rails

# Build and start services
docker-compose up -d

# Setup database
docker-compose exec rails bin/rails db:prepare
docker-compose exec rails bin/rails db:seed

# Application available at http://localhost:3000
# Maildev UI at http://localhost:8025
```

**Local Setup:**

```bash
# Clone the repository
git clone <repository-url>
cd pro-rails

# Install dependencies and setup database
bin/setup

# Start development server
bin/dev

# Application available at http://localhost:3000
```

### Environment Variables

Required environment variables (automatically set in Docker):

- `DB_USERNAME`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`
- `REDIS_URL`
- `ANYCABLE_SECRET`, `ANYCABLE_WEBSOCKET_URL`
- `MAILER_ADDRESS`, `MAILER_PORT` (for email in development)

## Testing

### Running Tests

**In Docker:**

```bash
# All tests
docker-compose exec rails bundle exec rspec

# Specific file
docker-compose exec rails bundle exec rspec spec/models/account_spec.rb

# Specific test
docker-compose exec rails bundle exec rspec spec/models/account_spec.rb:10

# Exclude system tests
docker-compose exec rails bundle exec rspec --tag ~type:system

# System tests (uses dedicated service)
docker-compose run test_system
```

**Locally:**

```bash
# All tests
bundle exec rspec

# Specific file
bundle exec rspec spec/models/account_spec.rb

# Specific test
bundle exec rspec spec/models/account_spec.rb:10

# Exclude system tests (faster, used in CI)
bundle exec rspec --tag ~type:system
```

### Test Database

**Docker:**

```bash
docker-compose exec rails bin/rails db:test:prepare
```

**Local:**

```bash
bin/rails db:test:prepare
```

### Test Helpers

**Authentication Helpers:**

```ruby
# In request specs
RSpec.describe "Conversations", type: :request do
  include LoginHelpers::Request

  let(:account) { create(:account, :verified) }

  before { rodauth_login(account) }

  it "allows access" do
    get conversations_path
    expect(response).to have_http_status(:success)
  end
end

# In controller specs
RSpec.describe ConversationsController, type: :controller do
  include LoginHelpers::Controller

  let(:account) { create(:account, :verified) }

  before { rodauth_login(account) }

  it "loads conversations" do
    get :index
    expect(response).to have_http_status(:success)
  end
end
```

## Code Quality

### Linting

**Docker:**

```bash
# Run linter
docker-compose exec rails bin/rubocop

# Auto-fix issues
docker-compose exec rails bin/rubocop -a

# Lint ERB templates
docker-compose exec rails ./erb_linter.sh
```

**Local:**

```bash
bin/rubocop
bin/rubocop -a
./erb_linter.sh
```

### Security Scanning

**Docker:**

```bash
# Brakeman security scan
docker-compose exec rails bin/brakeman

# JavaScript dependency audit
docker-compose exec rails bin/importmap audit
```

**Local:**

```bash
bin/brakeman
bin/importmap audit
```

## Deployment

### CI/CD Pipeline

GitHub Actions runs four jobs on pull requests and main branch:

1. **scan_ruby**: Brakeman security scan
2. **scan_js**: JavaScript dependency audit
3. **lint**: Ruby code linting with Standard
4. **test**: Full RSpec test suite

**CI Services:**

- PostgreSQL 17
- Redis 8.2
- AnyCable-Go for WebSocket tests

### Production Considerations

- Ensure `SECRET_KEY_BASE` is set securely
- Configure production database credentials
- Set up Redis for caching and job processing
- Deploy AnyCable-Go WebSocket server separately
- Configure SSL/TLS for secure WebSocket connections
- Set appropriate `RAILS_ENV=production`
- Precompile assets: `bin/rails assets:precompile`
- Run migrations: `bin/rails db:migrate`

### Docker Production Build

The Dockerfile uses multi-stage builds optimized for production:

- Base image: Ruby 3.4.4 on Debian Bookworm
- PostgreSQL 17 client libraries
- Jemalloc for better memory management
- libvips for image processing

## Contributing

1. Follow the existing code patterns and architecture
2. Write tests for new features
3. Run linter and fix any issues before committing
4. Ensure all tests pass
5. Update documentation for significant changes

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
