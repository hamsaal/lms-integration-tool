Rails.application.routes.draw do
  namespace :api do
    post "auth/dev_token", to: "auth#dev_token"

    resources :courses, only: %i[index create show] do
      resources :assignments, only: %i[index create]
      resources :enrollments, only: %i[index create]
    end

    resources :assignments, only: [] do
      resources :submissions, only: %i[index create]
    end

    patch "submissions/:id/grade", to: "submissions#grade"
    post "tool_launches", to: "tool_launches#create"
    post "roster_imports/preview", to: "roster_imports#preview"
    post "roster_imports", to: "roster_imports#create"
    post "grade_syncs", to: "grade_syncs#create"
    get "job_runs/:id", to: "job_runs#show"
    get "analytics/course_summary", to: "analytics#course_summary"
  end

  get "up", to: proc { [200, { "Content-Type" => "application/json" }, [{ status: "ok" }.to_json]] }
end
