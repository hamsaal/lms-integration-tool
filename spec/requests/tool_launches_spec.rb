require "rails_helper"

RSpec.describe "Tool launches API", type: :request do
  it "accepts a valid launch token and returns an API token" do
    id_token = JWT.encode(
      {
        iss: "https://canvas.example.edu",
        aud: "learning-integrations-rails-api",
        sub: "student-001",
        nonce: "nonce-123",
        name: "Alex Student",
        email: "student@example.edu",
        roles: ["Learner"],
        course_id: "course-001",
        assignment_id: "assignment-001",
        resource_link_id: "resource-001"
      },
      Auth::Token.secret,
      Auth::Token::ALGORITHM
    )

    post "/api/tool_launches", params: { id_token: }, as: :json

    expect(response).to have_http_status(:created)
    expect(response.parsed_body.fetch("token")).to be_present
    expect(ToolLaunch.count).to eq(1)
  end

  it "rejects an invalid launch token" do
    post "/api/tool_launches", params: { id_token: "bad-token" }, as: :json

    expect(response).to have_http_status(:unauthorized)
  end
end
