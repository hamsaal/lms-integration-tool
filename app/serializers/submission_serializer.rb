class SubmissionSerializer
  def self.render(submission)
    {
      id: submission.id,
      assignment_id: submission.assignment_id,
      user_id: submission.user_id,
      submitted_at: submission.submitted_at,
      score: submission.score&.to_f,
      workflow_state: submission.workflow_state,
      body: submission.body,
      grade: submission.grade && GradeSerializer.render(submission.grade)
    }
  end
end
