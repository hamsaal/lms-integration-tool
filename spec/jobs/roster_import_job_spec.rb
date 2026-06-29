require "rails_helper"

RSpec.describe RosterImportJob, type: :job do
  it "imports users, courses, and enrollments" do
    organization = create(:organization)
    job_run = create(:integration_job_run, organization:)
    payload = {
      users: [{ sourcedId: "student-1", name: "Learner One", email: "learner@example.edu", role: "student" }],
      courses: [{ sourcedId: "course-1", title: "Science", courseCode: "SCI-1", status: "active" }],
      enrollments: [{ userSourcedId: "student-1", classSourcedId: "course-1", role: "student", status: "active" }]
    }

    described_class.perform_now(job_run.id, payload)

    expect(job_run.reload).to be_completed
    expect(organization.users.find_by(external_ref: "student-1")).to be_present
    expect(Enrollment.count).to eq(1)
  end

  it "rolls back all rows when an enrollment references a missing user" do
    organization = create(:organization)
    job_run = create(:integration_job_run, organization:)
    payload = {
      courses: [{ sourcedId: "course-1", title: "Science", courseCode: "SCI-1", status: "active" }],
      enrollments: [{ userSourcedId: "missing", classSourcedId: "course-1", role: "student", status: "active" }]
    }

    expect { described_class.perform_now(job_run.id, payload) }.to raise_error(ActiveRecord::RecordNotFound)
    expect(organization.courses).to be_empty
    expect(job_run.reload).to be_failed
  end
end
