class AuditLogger
  SENSITIVE_KEYS = %w[email name token id_token authorization password].freeze

  def self.record!(organization:, actor:, action:, target:, metadata: {})
    organization.audit_logs.create!(
      actor_user: actor,
      action:,
      target_type: target.class.name,
      target_id: target.id,
      metadata: sanitize(metadata),
      created_at: Time.current
    )
  end

  def self.sanitize(value)
    case value
    when Hash
      value.each_with_object({}) do |(key, item), result|
        result[key] = SENSITIVE_KEYS.include?(key.to_s) ? "[FILTERED]" : sanitize(item)
      end
    when Array
      value.map { |item| sanitize(item) }
    else
      value
    end
  end
end
