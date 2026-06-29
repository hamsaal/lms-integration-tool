module Api
  class CoursesController < ApplicationController
    def index
      courses = current_organization.courses
                                    .includes(:assignments)
                                    .yield_self { |scope| params[:status].present? ? scope.where(status: params[:status]) : scope }
                                    .ordered
                                    .limit(limit)
                                    .offset(offset)

      render json: { data: courses.map { |course| CourseSerializer.render(course) }, meta: pagination_meta(courses) }
    end

    def show
      course = current_organization.courses.includes(:assignments, enrollments: :user).find(params[:id])
      require_course_access!(course)
      render json: { data: CourseSerializer.render(course, detailed: true) }
    end

    def create
      require_role!(:admin, :teacher)
      course = current_organization.courses.create!(course_params)
      AuditLogger.record!(organization: current_organization, actor: current_user, action: "course.created", target: course)
      render json: { data: CourseSerializer.render(course) }, status: :created
    end

    private

    def course_params
      params.require(:course).permit(:title, :course_code, :external_ref, :status)
    end

    def limit
      [[params.fetch(:limit, 25).to_i, 100].min, 1].max
    end

    def offset
      [params.fetch(:offset, 0).to_i, 0].max
    end

    def pagination_meta(scope)
      { limit:, offset:, returned: scope.size }
    end
  end
end
