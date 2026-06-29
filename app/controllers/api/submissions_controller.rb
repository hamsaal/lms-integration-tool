module Api
  class SubmissionsController < ApplicationController
    def index
      assignment = Assignment.includes(:course).find(params[:assignment_id])
      require_course_access!(assignment.course, roles: %w[teacher])
      submissions = assignment.submissions.includes(:user, :grade).order(created_at: :desc)

      render json: { data: submissions.map { |submission| SubmissionSerializer.render(submission) } }
    end

    def create
      assignment = Assignment.includes(:course).find(params[:assignment_id])
      require_course_access!(assignment.course, roles: %w[student])
      submission = assignment.submissions.create!(submission_params.merge(user: current_user, submitted_at: Time.current))
      AuditLogger.record!(organization: current_organization, actor: current_user, action: "submission.created", target: submission)

      render json: { data: SubmissionSerializer.render(submission) }, status: :created
    end

    def grade
      submission = Submission.includes(assignment: :course).find(params[:id])
      require_course_access!(submission.assignment.course, roles: %w[teacher])
      result = GradeUpdater.call(submission:, score: grade_params.fetch(:score), actor: current_user)

      render json: { data: SubmissionSerializer.render(result) }
    end

    private

    def submission_params
      params.require(:submission).permit(:body)
    end

    def grade_params
      params.require(:grade).permit(:score)
    end
  end
end
