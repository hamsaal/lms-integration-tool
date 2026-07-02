require "rails_helper"

RSpec.describe "Audit logs API", type: :request do
  it "lists sanitized audit logs for admins" do
    organization = create(:organization)
    admin = create(:user, :admin, organization:)
    user = create(:user, organization:)
    AuditLogger.record!(
      organization:,
      actor: admin,
      action: "user.reviewed",
      target: user,
      metadata: { email: "learner@example.edu", safe_note: "kept" }
    )

    get "/api/audit_logs", headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    data = response.parsed_body.fetch("data")
    expect(data.size).to eq(1)
    expect(data.first).to include(
      "actor_user_id" => admin.id,
      "action" => "user.reviewed",
      "target_type" => "User",
      "target_id" => user.id
    )
    expect(data.first.fetch("metadata")).to include("email" => "[FILTERED]", "safe_note" => "kept")
    expect(data.first).not_to have_key("organization_id")
  end

  it "keeps audit logs scoped to the current organization" do
    admin = create(:user, :admin)
    other_admin = create(:user, :admin)
    AuditLogger.record!(organization: admin.organization, actor: admin, action: "local.action", target: admin)
    AuditLogger.record!(organization: other_admin.organization, actor: other_admin, action: "other.action", target: other_admin)

    get "/api/audit_logs", headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").pluck("action")).to eq(["local.action"])
  end

  it "filters by event and target type" do
    organization = create(:organization)
    admin = create(:user, :admin, organization:)
    AuditLogger.record!(organization:, actor: admin, action: "course.created", target: create(:course, organization:))
    AuditLogger.record!(organization:, actor: admin, action: "user.reviewed", target: create(:user, organization:))

    get "/api/audit_logs",
        params: { event: "course.created", target_type: "Course" },
        headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").pluck("action")).to eq(["course.created"])
  end

  it "blocks non-admin users from reading audit logs" do
    teacher = create(:user, :teacher)

    get "/api/audit_logs", headers: auth_headers(teacher)

    expect(response).to have_http_status(:forbidden)
  end
end
