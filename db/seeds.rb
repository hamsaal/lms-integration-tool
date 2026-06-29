organization = Organization.find_or_create_by!(external_ref: "https://canvas.example.edu") do |org|
  org.name = "Canvas Demo School"
end

admin = organization.users.find_or_create_by!(external_ref: "admin-001") do |user|
  user.name = "Taylor Admin"
  user.email = "admin@example.edu"
  user.role = :admin
end

teacher = organization.users.find_or_create_by!(external_ref: "teacher-001") do |user|
  user.name = "Jordan Teacher"
  user.email = "teacher@example.edu"
  user.role = :teacher
end

student = organization.users.find_or_create_by!(external_ref: "student-001") do |user|
  user.name = "Alex Student"
  user.email = "student@example.edu"
  user.role = :student
end

course = organization.courses.find_or_create_by!(external_ref: "canvas-course-101") do |record|
  record.title = "Biology 101"
  record.course_code = "BIO-101"
  record.status = :active
end

Enrollment.find_or_create_by!(user: teacher, course:) do |enrollment|
  enrollment.role = :teacher
  enrollment.status = :active
end

Enrollment.find_or_create_by!(user: student, course:) do |enrollment|
  enrollment.role = :student
  enrollment.status = :active
end

course.assignments.find_or_create_by!(external_ref: "canvas-assignment-quiz-1") do |assignment|
  assignment.title = "Cell Structure Check"
  assignment.points_possible = 10
  assignment.status = :published
  assignment.due_at = 7.days.from_now
end

puts "Seeded demo users:"
puts "  admin@example.edu"
puts "  teacher@example.edu"
puts "  student@example.edu"
puts "Admin user id: #{admin.id}"
