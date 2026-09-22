class Role < ApplicationRecord
  validates :name, presence: true
  has_many :accounts
  has_and_belongs_to_many :permissions # rubocop:disable Rails/HasAndBelongsToMany
  has_many :permission_roles
  SUPERADMIN = "superadmin"

  # No application-level destroy path exists today (only a console or future
  # in-app `role.destroy` reaches this) — wired anyway per TECH-PLAN §8
  # unknown #10: it catches what it can, and the :roles condition predicate
  # matching by id (app/lib/audience_conditions/vocabulary.rb) is the guard
  # for what it can't (a raw SQL DELETE bypasses every callback).
  after_destroy :prune_from_audiences

  # Roles list for the adminit dashboard widget: alphabetical, permissions
  # eager-loaded, with an accounts_count sub-select (no extra query per row).
  scope :with_accounts_count, -> {
    order(:name)
      .includes(:permissions)
      .select("roles.*, (SELECT COUNT(*) FROM accounts WHERE accounts.role_id = roles.id) AS accounts_count")
  }
  scope :selectable, -> { order(:name) }

  def self.superadmin
    Role.find_by(name: SUPERADMIN)
  end

  def superadmin?
    name == SUPERADMIN
  end

  def breadcrumb_title = name

  def permitted_resources
    @permitted_resources ||= permissions.pluck(:resource).to_set
  end

  def permitted?(resource_key)
    permitted_resources.include?(resource_key.to_s)
  end

  def dashboard_widgets
    keys = permission_roles.pluck(:dashboard_widget_keys).flatten
    Dashboard::WidgetRegistry.for_keys(keys)
  end

  private

  def prune_from_audiences
    Audience.prune_role(id)
  end
end
