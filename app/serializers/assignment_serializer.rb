class AssignmentSerializer
  def self.render(assignment)
    {
      id: assignment.id,
      course_id: assignment.course_id,
      title: assignment.title,
      external_ref: assignment.external_ref,
      due_at: assignment.due_at,
      points_possible: assignment.points_possible.to_f,
      status: assignment.status
    }
  end
end
