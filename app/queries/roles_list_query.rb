class RolesListQuery
  def self.call
    Role.order(:name)
  end
end
