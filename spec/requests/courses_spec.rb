require "rails_helper"

RSpec.describe "Courses API", type: :request do
  it "requires authentication" do
    get "/api/courses"

    expect(response).to have_http_status(:unauthorized)
  end

  it "lists courses for the current organization" do
    organization = create(:organization)
    user = create(:user, :admin, organization:)
    create(:course, organization:)
    create(:course)

    get "/api/courses", headers: auth_headers(user)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.fetch("data").size).to eq(1)
  end

  it "creates courses for teachers" do
    organization = create(:organization)
    teacher = create(:user, :teacher, organization:)

    post "/api/courses",
         params: { course: { title: "History", course_code: "HIS-1", external_ref: "his-1" } },
         headers: auth_headers(teacher),
         as: :json

    expect(response).to have_http_status(:created)
    expect(AuditLog.where(action: "course.created")).to exist
  end
end
