class ToolLaunch < ApplicationRecord
  belongs_to :organization
  belongs_to :user
  belongs_to :course

  validates :launch_context, :nonce, :launched_at, presence: true
  validates :nonce, uniqueness: true
end
