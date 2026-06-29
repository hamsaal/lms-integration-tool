class GradeSyncJob < ApplicationJob
  queue_as :default

  def perform(job_run_id)
    job_run = IntegrationJobRun.find(job_run_id)
    job_run.update!(status: :running, started_at: Time.current)

    scope = Grade.pending.includes(:assignment, :submission, :user)
    scope = scope.where(assignment_id: job_run.metadata["assignment_id"]) if job_run.metadata["assignment_id"].present?
    if job_run.metadata["course_id"].present?
      scope = scope.joins(:assignment).where(assignments: { course_id: job_run.metadata["course_id"] })
    end

    synced_count = 0
    Grade.transaction do
      scope.find_each do |grade|
        grade.update!(passback_status: "synced", synced_at: Time.current)
        synced_count += 1
      end
    end

    result = { synced_count: }
    job_run.update!(status: :completed, finished_at: Time.current, metadata: job_run.metadata.merge(result))
    AuditLogger.record!(organization: job_run.organization, actor: nil, action: "grade_sync.completed", target: job_run, metadata: result)
  rescue StandardError => error
    job_run&.update!(status: :failed, finished_at: Time.current, error_message: error.message.to_s.truncate(250))
    raise
  end
end
