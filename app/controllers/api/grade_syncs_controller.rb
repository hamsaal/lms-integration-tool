module Api
  class GradeSyncsController < ApplicationController
    def create
      require_role!(:admin, :teacher)
      job_run = current_organization.integration_job_runs.create!(
        job_type: :grade_sync,
        status: :queued,
        metadata: grade_sync_params.to_h.merge(requested_by_user_id: current_user.id)
      )

      GradeSyncJob.perform_later(job_run.id)
      render json: { data: JobRunSerializer.render(job_run) }, status: :accepted
    end

    private

    def grade_sync_params
      params.require(:grade_sync).permit(:course_id, :assignment_id)
    end
  end
end
