# Learning Integration Tool

Rails API and React prototype for a Canvas-style external learning tool launch, learner activity submission, roster import, and grade passback workflow.

This project is intentionally scoped as a prototype. It simulates Canvas launch context, LTI 1.3-style OIDC/JWT validation concepts, OneRoster-style roster imports, AGS-style grade passback, and privacy-aware audit logging. It does not claim Canvas certification, LTI certification, OneRoster certification, FERPA compliance, GDPR compliance, or production deployment readiness.

## Feature Plan

| Branch | Scope |
| --- | --- |
| `feature/project-foundation` | Rails API, React frontend, Docker Compose, environment config, CI base |
| `feature/domain-models` | ActiveRecord models, migrations, indexes, validations, seed data |
| `feature/lti-launch-flow` | JWT launch validation, launch context storage, role-aware session token |
| `feature/rest-api` | Courses, assignments, enrollments, submissions, grading, analytics |
| `feature/roster-import` | OneRoster-style CSV/JSON import service and Sidekiq job |
| `feature/grade-passback` | AGS-style grade passback simulation and retry-ready job run tracking |
| `feature/react-launch-ui` | Launch simulator, learner activity page, instructor review panel |
| `chore/ci-test-coverage` | RSpec request/model/job specs, Playwright flow, GitHub Actions |

## Architecture

- **Backend:** Rails 7 API-only app with PostgreSQL, ActiveRecord, JWT bearer auth, and Sidekiq.
- **Frontend:** React + Vite single-page app for the launch and activity flow.
- **Data model:** Organizations own users, courses, launches, audit logs, and background job runs. Courses contain enrollments and assignments. Learners create submissions. Instructors grade submissions, creating passback-ready grade records.
- **Background jobs:** Roster import and grade sync use Sidekiq with Redis.
- **Privacy-aware handling:** Audit logs avoid raw tokens and filter common PII keys. Normal API serializers avoid exposing email unless explicitly needed by a development-only auth endpoint.

## Local Setup

Copy environment values:

```bash
cp .env.example .env
```

Start the full stack:

```bash
docker compose up --build
```

Seed demo data:

```bash
docker compose exec api bundle exec rails db:seed
```

Open the frontend:

```text
http://localhost:5173
```

API health check:

```bash
curl http://localhost:3000/up
```

## Demo Credentials

The development token endpoint accepts seeded demo emails:

```text
admin@example.edu
teacher@example.edu
student@example.edu
```

Example:

```bash
curl -X POST http://localhost:3000/api/auth/dev_token \
  -H "Content-Type: application/json" \
  -d '{"email":"teacher@example.edu"}'
```

## API Examples

List courses:

```bash
curl http://localhost:3000/api/courses \
  -H "Authorization: Bearer <token>"
```

Create a learner submission:

```bash
curl -X POST http://localhost:3000/api/assignments/1/submissions \
  -H "Authorization: Bearer <student-token>" \
  -H "Content-Type: application/json" \
  -d '{"submission":{"body":"A cell membrane controls transport."}}'
```

Grade a submission:

```bash
curl -X PATCH http://localhost:3000/api/submissions/1/grade \
  -H "Authorization: Bearer <teacher-token>" \
  -H "Content-Type: application/json" \
  -d '{"grade":{"score":9}}'
```

Preview a roster import without persisting rows:

```bash
curl -X POST http://localhost:3000/api/roster_imports/preview \
  -H "Authorization: Bearer <admin-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "roster": {
      "users_csv": "sourcedId,name,email,role\nstudent-2,Sam Learner,sam@example.edu,student",
      "classes_csv": "sourcedId,title,classCode,status\nclass-2,Algebra,ALG-1,active",
      "enrollments_csv": "userSourcedId,classSourcedId,role,status\nstudent-2,class-2,student,active"
    }
  }'
```

Queue a roster import:

```bash
curl -X POST http://localhost:3000/api/roster_imports \
  -H "Authorization: Bearer <admin-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "roster": {
      "users_csv": "sourcedId,name,email,role\nstudent-2,Sam Learner,sam@example.edu,student",
      "courses_csv": "sourcedId,title,courseCode,status\ncourse-2,Algebra,ALG-1,active",
      "enrollments_csv": "userSourcedId,classSourcedId,role,status\nstudent-2,course-2,student,active"
    }
  }'
```

## Query Optimization Notes

- Users, courses, and assignments use organization/course-scoped unique indexes for external references.
- Enrollments use a unique `user_id, course_id` index because access checks and roster imports depend on that pair.
- Submissions use a unique `assignment_id, user_id` index to prevent duplicate learner submissions for the same activity.
- Grades use unique submission and assignment/user indexes so grade updates stay one-to-one with submissions.
- Launches and audit logs are indexed by organization and time for common security review queries.
- Controllers use `includes` for course detail, submission review, and analytics paths to avoid avoidable N+1 queries.
- Roster import and grade updates are wrapped in transactions so partial updates do not leave inconsistent course, enrollment, submission, or grade state.

## Tests

Run the same core checks locally before pushing:

```bash
bin/ci
```

Backend:

```bash
docker compose run --rm \
  -e RAILS_ENV=test \
  -e DATABASE_URL=postgres://postgres:postgres@postgres:5432/learning_integrations_test \
  -e TEST_DATABASE_URL=postgres://postgres:postgres@postgres:5432/learning_integrations_test \
  api bash -lc "bundle exec rails db:prepare && bundle exec rails db:seed && bundle exec rspec"
```

Frontend:

```bash
cd frontend
npm ci
npm audit --audit-level=moderate
npm run build
```

End-to-end:

```bash
bin/e2e
```

## CI

GitHub Actions runs:

- Rails specs with PostgreSQL and Redis service containers after loading demo seed data.
- React dependency install, npm audit, and TypeScript production build.
- Docker-backed Playwright flow covering launch, learner submission, and instructor grading.

## Resume Bullet

"Built a Rails 7 API-only LMS integration prototype with ActiveRecord/PostgreSQL data models, migrations, composite indexes, JWT-protected REST APIs, Sidekiq background jobs for roster import and grade sync, audit logging, Dockerized services, GitHub Actions CI, and RSpec request/model/job coverage."
