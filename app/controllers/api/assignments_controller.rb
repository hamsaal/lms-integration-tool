module Api
  class AssignmentsController < ApplicationController
    def index
      course = current_organization.courses.find(params[:course_id])
      require_course_access!(course)
      assignments = course.assignments.due_soon

      render json: { data: assignments.map { |assignment| AssignmentSerializer.render(assignment) } }
    end

    def create
      course = current_organization.courses.find(params[:course_id])
      require_course_access!(course, roles: %w[teacher])
      assignment = course.assignments.create!(assignment_params)
      AuditLogger.record!(organization: current_organization, actor: current_user, action: "assignment.created", target: assignment)

      render json: { data: AssignmentSerializer.render(assignment) }, status: :created
    end

    private

    def assignment_params
      params.require(:assignment).permit(:title, :due_at, :points_possible, :status)
    end
  end
end
