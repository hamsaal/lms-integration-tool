FactoryBot.define do
  factory :integration_job_run do
    organization
    job_type { :roster_import }
    status { :queued }
    metadata { {} }
  end
end
