class RosterImportJob < ApplicationJob
  queue_as :default

  def perform(job_run_id, payload)
    job_run = IntegrationJobRun.find(job_run_id)
    job_run.update!(status: :running, started_at: Time.current)

    result = RosterImportProcessor.call(organization: job_run.organization, payload:)
    job_run.update!(status: :completed, finished_at: Time.current, metadata: job_run.metadata.merge(result))

    AuditLogger.record!(
      organization: job_run.organization,
      actor: nil,
      action: "roster_import.completed",
      target: job_run,
      metadata: result
    )
  rescue StandardError => error
    job_run&.update!(status: :failed, finished_at: Time.current, error_message: error.message.to_s.truncate(250))
    raise
  end
end
