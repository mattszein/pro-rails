class PermissionStatsQuery
  def self.call
    {
      total_roles: Role.count,
      total_accounts: Account.count,
      roles_with_permissions: PermissionRole.distinct.count(:role_id),
      permissions_by_role: Role.includes(:permissions).to_h { |r| [r.name, r.permissions.count] }
    }
  end
end
