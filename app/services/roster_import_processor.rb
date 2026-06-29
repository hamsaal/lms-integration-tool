require "csv"

class RosterImportProcessor
  def self.call(organization:, payload:)
    new(organization:, payload:).call
  end

  def initialize(organization:, payload:)
    @organization = organization
    @payload = payload.deep_stringify_keys
    @counts = { users_count: 0, courses_count: 0, enrollments_count: 0 }
  end

  def call
    ActiveRecord::Base.transaction do
      import_users
      import_courses
      import_classes
      import_enrollments
    end

    counts
  end

  private

  attr_reader :organization, :payload, :counts

  def import_users
    rows("users").each do |row|
      user = organization.users.find_or_initialize_by(external_ref: required(row, "sourcedId"))
      user.assign_attributes(
        name: required(row, "name"),
        email: required(row, "email"),
        role: normalize_user_role(row["role"])
      )
      user.save!
      counts[:users_count] += 1
    end
  end

  def import_courses
    rows("courses").each do |row|
      course = organization.courses.find_or_initialize_by(external_ref: required(row, "sourcedId"))
      course.assign_attributes(
        title: required(row, "title"),
        course_code: required(row, "courseCode"),
        status: normalize_course_status(row["status"])
      )
      course.save!
      counts[:courses_count] += 1
    end
  end

  def import_classes
    rows("classes").each do |row|
      course = organization.courses.find_or_initialize_by(external_ref: required(row, "sourcedId"))
      course.assign_attributes(
        title: required(row, "title"),
        course_code: row["classCode"].presence || required(row, "sourcedId"),
        status: normalize_course_status(row["status"])
      )
      course.save!
      counts[:courses_count] += 1
    end
  end

  def import_enrollments
    rows("enrollments").each do |row|
      user = organization.users.find_by!(external_ref: required(row, "userSourcedId"))
      course = organization.courses.find_by!(external_ref: required(row, "classSourcedId"))
      enrollment = Enrollment.find_or_initialize_by(user:, course:)
      enrollment.assign_attributes(
        role: normalize_enrollment_role(row["role"]),
        status: normalize_enrollment_status(row["status"])
      )
      enrollment.save!
      counts[:enrollments_count] += 1
    end
  end

  def rows(key)
    return Array(payload[key]) if payload[key].present?

    csv = payload["#{key}_csv"]
    return [] if csv.blank?

    CSV.parse(csv, headers: true).map(&:to_h)
  end

  def required(row, key)
    row.fetch(key).presence || raise(ActiveRecord::RecordInvalid.new(invalid_record("#{key} is required")))
  end

  def invalid_record(message)
    Organization.new.tap { |record| record.errors.add(:base, message) }
  end

  def normalize_user_role(value)
    case value.to_s.downcase
    when "teacher", "instructor" then :teacher
    when "admin", "administrator" then :admin
    else :student
    end
  end

  def normalize_enrollment_role(value)
    value.to_s.downcase.include?("teacher") || value.to_s.downcase.include?("instructor") ? :teacher : :student
  end

  def normalize_course_status(value)
    value.to_s.downcase == "archived" ? :archived : :active
  end

  def normalize_enrollment_status(value)
    value.to_s.downcase == "dropped" ? :dropped : :active
  end
end
