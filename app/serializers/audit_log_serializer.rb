class AuditLogSerializer
  def self.render(audit_log)
    {
      id: audit_log.id,
      actor_user_id: audit_log.actor_user_id,
      action: audit_log.action,
      target_type: audit_log.target_type,
      target_id: audit_log.target_id,
      metadata: audit_log.metadata,
      created_at: audit_log.created_at
    }
  end
end
