require "csv"

class RosterImportProcessor
  class ValidationError < StandardError; end

  def self.call(organization:, payload:, dry_run: false)
    new(organization:, payload:, dry_run:).call
  end

  def initialize(organization:, payload:, dry_run: false)
    @organization = organization
    @payload = payload.deep_stringify_keys
    @dry_run = dry_run
    @counts = {
      users_count: 0,
      courses_count: 0,
      classes_count: 0,
      enrollments_count: 0,
      created_count: 0,
      updated_count: 0
    }
  end

  def call
    ActiveRecord::Base.transaction do
      import_users
      import_courses
      import_classes
      import_enrollments
      raise ActiveRecord::Rollback if dry_run
    end

    counts
  end

  private

  attr_reader :organization, :payload, :counts, :dry_run

  def import_users
    rows("users").each.with_index(2) do |row, line_number|
      user = organization.users.find_or_initialize_by(external_ref: required(row, "sourcedId"))
      track_change(user)
      user.assign_attributes(
        name: required(row, "name"),
        email: required(row, "email"),
        role: normalize_user_role(row["role"])
      )
      save_record!(user, "users", line_number)
      counts[:users_count] += 1
    end
  end

  def import_courses
    rows("courses").each.with_index(2) do |row, line_number|
      course = organization.courses.find_or_initialize_by(external_ref: required(row, "sourcedId"))
      track_change(course)
      course.assign_attributes(
        title: required(row, "title"),
        course_code: required(row, "courseCode"),
        status: normalize_course_status(row["status"])
      )
      save_record!(course, "courses", line_number)
      counts[:courses_count] += 1
    end
  end

  def import_classes
    rows("classes").each.with_index(2) do |row, line_number|
      course = organization.courses.find_or_initialize_by(external_ref: required(row, "sourcedId"))
      track_change(course)
      course.assign_attributes(
        title: required(row, "title"),
        course_code: row["classCode"].presence || required(row, "sourcedId"),
        status: normalize_course_status(row["status"])
      )
      save_record!(course, "classes", line_number)
      counts[:classes_count] += 1
    end
  end

  def import_enrollments
    rows("enrollments").each.with_index(2) do |row, line_number|
      user = find_required_user!(row, line_number)
      course = find_required_course!(row, line_number)
      enrollment = Enrollment.find_or_initialize_by(user:, course:)
      track_change(enrollment)
      enrollment.assign_attributes(
        role: normalize_enrollment_role(row["role"]),
        status: normalize_enrollment_status(row["status"])
      )
      save_record!(enrollment, "enrollments", line_number)
      counts[:enrollments_count] += 1
    end
  end

  def rows(key)
    return Array(payload[key]) if payload[key].present?

    csv = payload["#{key}_csv"]
    return [] if csv.blank?

    CSV.parse(csv, headers: true).map(&:to_h)
  end

  def find_required_user!(row, line_number)
    organization.users.find_by!(external_ref: required(row, "userSourcedId"))
  rescue ActiveRecord::RecordNotFound
    raise ValidationError, "enrollments row #{line_number}: userSourcedId does not match an imported user"
  end

  def find_required_course!(row, line_number)
    organization.courses.find_by!(external_ref: required(row, "classSourcedId"))
  rescue ActiveRecord::RecordNotFound
    raise ValidationError, "enrollments row #{line_number}: classSourcedId does not match an imported course or class"
  end

  def required(row, key)
    row.fetch(key).presence || raise(ValidationError, "#{key} is required")
  rescue KeyError
    raise ValidationError, "#{key} is required"
  end

  def save_record!(record, section, line_number)
    record.save!
  rescue ActiveRecord::RecordInvalid => error
    raise ValidationError, "#{section} row #{line_number}: #{error.record.errors.full_messages.to_sentence}"
  end

  def track_change(record)
    if record.new_record?
      counts[:created_count] += 1
    else
      counts[:updated_count] += 1
    end
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
