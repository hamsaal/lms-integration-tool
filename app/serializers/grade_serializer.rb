class GradeSerializer
  def self.render(grade)
    {
      id: grade.id,
      submission_id: grade.submission_id,
      assignment_id: grade.assignment_id,
      user_id: grade.user_id,
      score: grade.score.to_f,
      passback_status: grade.passback_status,
      synced_at: grade.synced_at
    }
  end
end
