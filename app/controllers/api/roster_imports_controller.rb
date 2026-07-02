module Api
  class RosterImportsController < ApplicationController
    rescue_from RosterImportProcessor::ValidationError, with: :invalid_roster

    def preview
      require_role!(:admin)
      result = RosterImportProcessor.call(organization: current_organization, payload: roster_payload.to_h, dry_run: true)
      render json: { data: result }
    end

    def create
      require_role!(:admin)
      preview = RosterImportProcessor.call(organization: current_organization, payload: roster_payload.to_h, dry_run: true)
      job_run = current_organization.integration_job_runs.create!(
        job_type: :roster_import,
        status: :queued,
        metadata: preview.merge(requested_by_user_id: current_user.id)
      )

      RosterImportJob.perform_later(job_run.id, roster_payload.to_h)
      render json: { data: JobRunSerializer.render(job_run) }, status: :accepted
    end

    private

    def roster_payload
      params.require(:roster).to_unsafe_h
    end

    def invalid_roster(error)
      render_error("invalid_roster", error.message, :unprocessable_content)
    end
  end
end
