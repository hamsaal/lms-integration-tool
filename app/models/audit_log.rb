class AuditLog < ApplicationRecord
  belongs_to :organization
  belongs_to :actor_user, class_name: "User", optional: true

  validates :action, :target_type, presence: true
end
