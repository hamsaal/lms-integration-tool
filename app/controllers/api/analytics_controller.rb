module Api
  class AnalyticsController < ApplicationController
    def course_summary
      course = current_organization.courses.includes(assignments: :submissions).find(params.require(:course_id))
      require_course_access!(course, roles: %w[teacher])

      render json: {
        data: {
          course: CourseSerializer.render(course),
          enrollments: course.enrollments.active.count,
          assignments: course.assignments.count,
          submissions: Submission.joins(:assignment).where(assignments: { course_id: course.id }).count,
          graded_submissions: Submission.joins(:assignment).where(assignments: { course_id: course.id }).graded.count
        }
      }
    end
  end
end
