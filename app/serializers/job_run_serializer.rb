class JobRunSerializer
  def self.render(job_run)
    {
      id: job_run.id,
      organization_id: job_run.organization_id,
      job_type: job_run.job_type,
      status: job_run.status,
      started_at: job_run.started_at,
      finished_at: job_run.finished_at,
      error_message: job_run.error_message,
      metadata: job_run.metadata
    }
  end
end
