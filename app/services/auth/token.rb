module Auth
  class Token
    ALGORITHM = "HS256".freeze

    def self.encode(user, expires_at: 12.hours.from_now)
      payload = {
        sub: user.id,
        organization_id: user.organization_id,
        role: user.role,
        exp: expires_at.to_i
      }
      JWT.encode(payload, secret, ALGORITHM)
    end

    def self.decode(token)
      JWT.decode(token, secret, true, { algorithm: ALGORITHM }).first
    end

    def self.secret
      ENV.fetch("JWT_SECRET", "development-only-secret")
    end
  end
end
