require "rails_helper"

RSpec.describe "Background job APIs", type: :request do
  it "previews roster imports without persisting rows" do
    admin = create(:user, :admin)
    payload = {
      users_csv: "sourcedId,name,email,role\nstudent-2,Sam Learner,sam@example.edu,student",
      classes_csv: "sourcedId,title,classCode,status\nclass-2,Algebra,ALG-1,active",
      enrollments_csv: "userSourcedId,classSourcedId,role,status\nstudent-2,class-2,student,active"
    }

    post "/api/roster_imports/preview",
         params: { roster: payload },
         headers: auth_headers(admin),
         as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data")).to include(
      "users_count" => 1,
      "classes_count" => 1,
      "enrollments_count" => 1,
      "created_count" => 3
    )
    expect(admin.organization.users.find_by(external_ref: "student-2")).to be_nil
    expect(admin.organization.courses.find_by(external_ref: "class-2")).to be_nil
  end

  it "queues roster imports for admins with preview metadata" do
    admin = create(:user, :admin)
    payload = {
      users: [{ sourcedId: "student-2", name: "Sam Learner", email: "sam@example.edu", role: "student" }]
    }

    post "/api/roster_imports",
         params: { roster: payload },
         headers: auth_headers(admin),
         as: :json

    expect(response).to have_http_status(:accepted)
    expect(enqueued_jobs.last[:job]).to eq(RosterImportJob)
    expect(IntegrationJobRun.last.metadata).to include("users_count" => 1, "created_count" => 1)
  end

  it "rejects invalid roster imports before queueing" do
    admin = create(:user, :admin)
    payload = {
      courses: [{ sourcedId: "course-1", title: "Science", courseCode: "SCI-1", status: "active" }],
      enrollments: [{ userSourcedId: "missing", classSourcedId: "course-1", role: "student", status: "active" }]
    }

    post "/api/roster_imports",
         params: { roster: payload },
         headers: auth_headers(admin),
         as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.dig("error", "code")).to eq("invalid_roster")
    expect(enqueued_jobs).to be_empty
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
