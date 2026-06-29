require "rails_helper"

RSpec.describe GradeSyncJob, type: :job do
  it "marks pending grades as synced" do
    organization = create(:organization)
    student = create(:user, organization:)
    course = create(:course, organization:)
    create(:enrollment, user: student, course:)
    assignment = create(:assignment, course:)
    submission = create(:submission, assignment:, user: student, score: 8, workflow_state: :graded)
    grade = Grade.create!(submission:, assignment:, user: student, score: 8, passback_status: "pending")
    job_run = create(:integration_job_run, organization:, job_type: :grade_sync, metadata: { assignment_id: assignment.id })

    described_class.perform_now(job_run.id)

    expect(grade.reload.passback_status).to eq("synced")
    expect(job_run.reload).to be_completed
  end
end
