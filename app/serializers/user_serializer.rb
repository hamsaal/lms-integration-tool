class UserSerializer
  def self.render(user)
    {
      id: user.id,
      organization_id: user.organization_id,
      name: user.name,
      role: user.role,
      external_ref: user.external_ref
    }
  end
end
