module Api
  class EnrollmentsController < ApplicationController
    def index
      course = current_organization.courses.find(params[:course_id])
      require_course_access!(course, roles: %w[teacher])
      enrollments = course.enrollments.includes(:user).order(:role, :created_at)

      render json: { data: enrollments.map { |enrollment| EnrollmentSerializer.render(enrollment) } }
    end

    def create
      require_role!(:admin, :teacher)
      course = current_organization.courses.find(params[:course_id])
      user = current_organization.users.find(enrollment_params.fetch(:user_id))
      enrollment = course.enrollments.create!(enrollment_params.merge(user:))
      AuditLogger.record!(organization: current_organization, actor: current_user, action: "enrollment.created", target: enrollment)

      render json: { data: EnrollmentSerializer.render(enrollment) }, status: :created
    end

    private

    def enrollment_params
      params.require(:enrollment).permit(:user_id, :role, :status)
    end
  end
end
