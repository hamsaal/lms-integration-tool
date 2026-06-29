class CourseSerializer
  def self.render(course, detailed: false)
    payload = {
      id: course.id,
      title: course.title,
      course_code: course.course_code,
      external_ref: course.external_ref,
      status: course.status
    }

    if detailed
      payload[:assignments] = course.assignments.map { |assignment| AssignmentSerializer.render(assignment) }
      payload[:enrollments] = course.enrollments.map { |enrollment| EnrollmentSerializer.render(enrollment) }
    end

    payload
  end
end
