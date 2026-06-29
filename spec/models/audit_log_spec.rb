require "rails_helper"

RSpec.describe AuditLogger do
  it "filters sensitive metadata from audit logs" do
    organization = create(:organization)
    user = create(:user, organization:)

    log = described_class.record!(
      organization:,
      actor: user,
      action: "test.action",
      target: user,
      metadata: { email: "person@example.edu", safe: "kept" }
    )

    expect(log.metadata).to include("email" => "[FILTERED]", "safe" => "kept")
  end
end
