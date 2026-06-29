module Api
  class RosterImportsController < ApplicationController
    def create
      require_role!(:admin)
      job_run = current_organization.integration_job_runs.create!(
        job_type: :roster_import,
        status: :queued,
        metadata: { requested_by_user_id: current_user.id }
      )

      RosterImportJob.perform_later(job_run.id, roster_payload.to_h)
      render json: { data: JobRunSerializer.render(job_run) }, status: :accepted
    end

    private

    def roster_payload
      params.require(:roster).to_unsafe_h
    end
  end
end
