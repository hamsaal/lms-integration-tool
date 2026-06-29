module Api
  class JobRunsController < ApplicationController
    def show
      job_run = current_organization.integration_job_runs.find(params[:id])
      render json: { data: JobRunSerializer.render(job_run) }
    end
  end
end
