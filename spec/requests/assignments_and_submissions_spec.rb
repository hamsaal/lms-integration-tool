require "rails_helper"

RSpec.describe "Assignments and submissions API", type: :request do
  let(:organization) { create(:organization) }
  let(:teacher) { create(:user, :teacher, organization:) }
  let(:student) { create(:user, organization:) }
  let(:course) { create(:course, organization:) }
  let!(:teacher_enrollment) { create(:enrollment, user: teacher, course:, role: :teacher) }
  let!(:student_enrollment) { create(:enrollment, user: student, course:, role: :student) }

  it "allows teachers to create assignments" do
    post "/api/courses/#{course.id}/assignments",
         params: { assignment: { title: "Quiz", points_possible: 10, status: "published" } },
         headers: auth_headers(teacher),
         as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("data", "title")).to eq("Quiz")
  end

  it "blocks students from creating assignments" do
    post "/api/courses/#{course.id}/assignments",
         params: { assignment: { title: "Quiz", points_possible: 10 } },
         headers: auth_headers(student),
         as: :json

    expect(response).to have_http_status(:forbidden)
  end

  it "allows students to submit published activities" do
    assignment = create(:assignment, course:)

    post "/api/assignments/#{assignment.id}/submissions",
         params: { submission: { body: "My work" } },
         headers: auth_headers(student),
         as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.dig("data", "workflow_state")).to eq("submitted")
  end

  it "grades submissions transactionally and creates a pending grade" do
    assignment = create(:assignment, course:, points_possible: 10)
    submission = create(:submission, assignment:, user: student)

    patch "/api/submissions/#{submission.id}/grade",
          params: { grade: { score: 8 } },
          headers: auth_headers(teacher),
          as: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("data", "grade", "passback_status")).to eq("pending")
  end

  it "rejects scores over points possible" do
    assignment = create(:assignment, course:, points_possible: 10)
    submission = create(:submission, assignment:, user: student)

    patch "/api/submissions/#{submission.id}/grade",
          params: { grade: { score: 12 } },
          headers: auth_headers(teacher),
          as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(submission.reload.score).to be_nil
  end
end
