class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
  rescue_from ActionController::ParameterMissing, with: :bad_request
  rescue_from AuthorizationError, with: :forbidden

  before_action :authenticate_request!

  attr_reader :current_user

  private

  def authenticate_request!
    token = request.authorization.to_s.split.last
    payload = Auth::Token.decode(token)
    @current_user = User.includes(:organization).find(payload.fetch("sub"))
  rescue JWT::DecodeError, KeyError, ActiveRecord::RecordNotFound
    render_error("unauthorized", "A valid bearer token is required.", :unauthorized)
  end

  def require_role!(*roles)
    return if roles.map(&:to_s).include?(current_user.role)

    raise AuthorizationError, "Insufficient role for this action."
  end

  def require_course_access!(course, roles: %w[student teacher])
    return if current_user.admin?

    has_access = Enrollment.active.where(course:, user: current_user, role: roles).exists?
    raise AuthorizationError, "User is not enrolled with the required role." unless has_access
  end

  def current_organization
    current_user.organization
  end

  def render_error(code, message, status)
    render json: { error: { code:, message: } }, status:
  end

  def not_found
    render_error("not_found", "The requested resource was not found.", :not_found)
  end

  def unprocessable_entity(error)
    render json: { error: { code: "validation_error", message: error.record.errors.full_messages } },
           status: :unprocessable_entity
  end

  def bad_request(error)
    render_error("bad_request", error.message, :bad_request)
  end

  def forbidden(error)
    render_error("forbidden", error.message, :forbidden)
  end
end

class AuthorizationError < StandardError; end
