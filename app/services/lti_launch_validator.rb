class LtiLaunchValidator
  LaunchResult = Struct.new(:tool_launch, :user, keyword_init: true)
  class LaunchError < StandardError; end

  REQUIRED_CLAIMS = %w[iss aud sub nonce].freeze

  def self.call(id_token:)
    new(id_token:).call
  end

  def initialize(id_token:)
    @id_token = id_token
  end

  def call
    payload = decode_and_validate!

    organization = Organization.find_or_create_by!(external_ref: payload.fetch("iss")) do |org|
      org.name = payload.fetch("organization_name", "Canvas Demo School")
    end

    user = organization.users.find_or_initialize_by(external_ref: payload.fetch("sub"))
    user.assign_attributes(
      name: payload.fetch("name", "Launch User"),
      email: payload.fetch("email", "#{payload.fetch("sub")}@example.edu"),
      role: normalized_role(payload)
    )
    user.save!

    course = organization.courses.find_or_create_by!(external_ref: payload.fetch("course_id")) do |record|
      record.title = payload.fetch("course_title", "Canvas Launch Course")
      record.course_code = payload.fetch("course_code", payload.fetch("course_id"))
      record.status = :active
    end

    ensure_enrollment!(user, course, payload)
    assignment = ensure_assignment!(course, payload)
    tool_launch = create_launch!(organization, user, course, assignment, payload)

    LaunchResult.new(tool_launch:, user:)
  rescue JWT::DecodeError, KeyError, ActiveRecord::RecordInvalid => error
    raise LaunchError, error.message
  end

  private

  attr_reader :id_token

  def decode_and_validate!
    payload = JWT.decode(id_token, Auth::Token.secret, true, { algorithm: Auth::Token::ALGORITHM }).first
    missing_claim = REQUIRED_CLAIMS.find { |claim| payload[claim].blank? }
    raise LaunchError, "Missing required launch claim: #{missing_claim}" if missing_claim
    raise LaunchError, "Invalid issuer" unless payload["iss"] == ENV.fetch("LTI_ISSUER", "https://canvas.example.edu")

    audience = Array(payload["aud"])
    expected_audience = ENV.fetch("LTI_AUDIENCE", "learning-integrations-rails-api")
    raise LaunchError, "Invalid audience" unless audience.include?(expected_audience)

    payload
  end

  def normalized_role(payload)
    roles = Array(payload["roles"]).map(&:to_s).join(" ").downcase
    return :teacher if roles.include?("instructor") || roles.include?("teacher")
    return :admin if roles.include?("administrator")

    :student
  end

  def ensure_enrollment!(user, course, payload)
    enrollment_role = normalized_role(payload) == :teacher ? :teacher : :student
    Enrollment.find_or_create_by!(user:, course:) do |enrollment|
      enrollment.role = enrollment_role
      enrollment.status = :active
    end
  end

  def ensure_assignment!(course, payload)
    assignment_id = payload.fetch("assignment_id", "launch-assignment")
    course.assignments.find_or_create_by!(external_ref: assignment_id) do |assignment|
      assignment.title = payload.fetch("assignment_title", "Launch Activity")
      assignment.points_possible = payload.fetch("points_possible", 10)
      assignment.status = :published
    end
  end

  def create_launch!(organization, user, course, assignment, payload)
    launch_context = {
      role: user.role,
      course_id: course.id,
      assignment_id: assignment.id,
      resource_link_id: payload.fetch("resource_link_id", "resource-link-demo")
    }

    ToolLaunch.create!(
      organization:,
      user:,
      course:,
      nonce: payload.fetch("nonce"),
      launched_at: Time.current,
      launch_context:
    ).tap do |launch|
      AuditLogger.record!(organization:, actor: user, action: "tool_launch.created", target: launch, metadata: launch_context)
    end
  end
end
