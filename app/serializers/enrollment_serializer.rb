class EnrollmentSerializer
  def self.render(enrollment)
    {
      id: enrollment.id,
      course_id: enrollment.course_id,
      user: UserSerializer.render(enrollment.user),
      role: enrollment.role,
      status: enrollment.status
    }
  end
end
