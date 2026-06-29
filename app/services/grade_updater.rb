class GradeUpdater
  def self.call(submission:, score:, actor:)
    new(submission:, score:, actor:).call
  end

  def initialize(submission:, score:, actor:)
    @submission = submission
    @score = BigDecimal(score.to_s)
    @actor = actor
  end

  def call
    Submission.transaction do
      validate_score!

      submission.update!(score:, workflow_state: :graded)
      submission.grade&.destroy!
      submission.create_grade!(
        assignment: submission.assignment,
        user: submission.user,
        score:,
        passback_status: "pending"
      )

      AuditLogger.record!(
        organization: submission.assignment.course.organization,
        actor:,
        action: "submission.graded",
        target: submission,
        metadata: { assignment_id: submission.assignment_id, score: }
      )

      submission
    end
  end

  private

  attr_reader :submission, :score, :actor

  def validate_score!
    max_score = submission.assignment.points_possible
    return if score.between?(0, max_score)

    submission.errors.add(:score, "must be between 0 and #{max_score.to_f}")
    raise ActiveRecord::RecordInvalid, submission
  end
end
