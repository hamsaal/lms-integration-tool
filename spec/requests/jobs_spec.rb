require "rails_helper"

RSpec.describe "Background job APIs", type: :request do
  it "queues roster imports for admins" do
    admin = create(:user, :admin)

    post "/api/roster_imports",
         params: { roster: { users: [] } },
         headers: auth_headers(admin),
         as: :json

    expect(response).to have_http_status(:accepted)
    expect(enqueued_jobs.last[:job]).to eq(RosterImportJob)
  end

  it "queues grade syncs for teachers" do
    organization = create(:organization)
    teacher = create(:user, :teacher, organization:)
    course = create(:course, organization:)
    create(:enrollment, user: teacher, course:, role: :teacher)

    post "/api/grade_syncs",
         params: { grade_sync: { course_id: course.id } },
         headers: auth_headers(teacher),
         as: :json

    expect(response).to have_http_status(:accepted)
    expect(enqueued_jobs.last[:job]).to eq(GradeSyncJob)
  end

  it "returns job run status" do
    admin = create(:user, :admin)
    job_run = create(:integration_job_run, organization: admin.organization)

    get "/api/job_runs/#{job_run.id}", headers: auth_headers(admin)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "status")).to eq("queued")
  end
end
