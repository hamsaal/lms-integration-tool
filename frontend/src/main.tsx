import React from "react";
import ReactDOM from "react-dom/client";
import { BookOpen, CheckCircle2, ClipboardList, GraduationCap, RefreshCcw, ShieldCheck } from "lucide-react";
import "./styles.css";
import { apiRequest } from "./support/api";
import { createDemoLaunchToken } from "./support/ltiToken";

type LaunchContext = {
  id: number;
  user_id: number;
  course_id: number;
  launch_context: {
    assignment_id: number;
    resource_link_id: string;
    role: string;
  };
};

type Assignment = {
  id: number;
  title: string;
  points_possible: number;
};

type Submission = {
  id: number;
  assignment_id: number;
  workflow_state: string;
  score: number | null;
  grade?: {
    passback_status: string;
  };
};

type RosterPreview = {
  users_count: number;
  courses_count: number;
  classes_count: number;
  enrollments_count: number;
  created_count: number;
  updated_count: number;
};

type JobRun = {
  id: number;
  job_type: string;
  status: string;
  started_at: string | null;
  finished_at: string | null;
  error_message: string | null;
  metadata: Record<string, unknown>;
};

type AuditLog = {
  id: number;
  actor_user_id: number | null;
  action: string;
  target_type: string;
  target_id: number | null;
  metadata: Record<string, unknown>;
  created_at: string;
};

const sampleRoster = {
  users_csv: "sourcedId,name,email,role\nstudent-admin-2,Sam Learner,sam@example.edu,student",
  classes_csv: "sourcedId,title,classCode,status\nclass-admin-2,Algebra,ALG-1,active",
  enrollments_csv: "userSourcedId,classSourcedId,role,status\nstudent-admin-2,class-admin-2,student,active"
};

function App() {
  const [apiToken, setApiToken] = React.useState("");
  const [adminToken, setAdminToken] = React.useState("");
  const [launch, setLaunch] = React.useState<LaunchContext | null>(null);
  const [assignments, setAssignments] = React.useState<Assignment[]>([]);
  const [submission, setSubmission] = React.useState<Submission | null>(null);
  const [reflection, setReflection] = React.useState("Cells use membranes to control what enters and leaves.");
  const [status, setStatus] = React.useState("Ready to simulate a Canvas launch.");
  const [adminStatus, setAdminStatus] = React.useState("Admin console is ready.");
  const [rosterUsersCsv, setRosterUsersCsv] = React.useState(sampleRoster.users_csv);
  const [rosterClassesCsv, setRosterClassesCsv] = React.useState(sampleRoster.classes_csv);
  const [rosterEnrollmentsCsv, setRosterEnrollmentsCsv] = React.useState(sampleRoster.enrollments_csv);
  const [rosterPreview, setRosterPreview] = React.useState<RosterPreview | null>(null);
  const [jobRun, setJobRun] = React.useState<JobRun | null>(null);
  const [auditLogs, setAuditLogs] = React.useState<AuditLog[]>([]);
  const [auditEvent, setAuditEvent] = React.useState("");

  const assignment = assignments.find((item) => item.id === launch?.launch_context.assignment_id) ?? assignments[0];

  async function launchAsLearner() {
    setStatus("Creating launch token and validating launch context...");
    const idToken = await createDemoLaunchToken();
    const response = await apiRequest<{ data: LaunchContext; token: string }>("/api/tool_launches", {
      method: "POST",
      body: JSON.stringify({ id_token: idToken })
    });

    setApiToken(response.token);
    setLaunch(response.data);
    setStatus("Launch accepted. Loading assignment context...");

    const assignmentResponse = await apiRequest<{ data: Assignment[] }>(
      `/api/courses/${response.data.course_id}/assignments`,
      { token: response.token }
    );
    setAssignments(assignmentResponse.data);
    setStatus("Learner activity is ready.");
  }

  async function submitActivity() {
    if (!assignment) return;

    const response = await apiRequest<{ data: Submission }>(`/api/assignments/${assignment.id}/submissions`, {
      method: "POST",
      token: apiToken,
      body: JSON.stringify({ submission: { body: reflection } })
    });

    setSubmission(response.data);
    setStatus("Activity submitted. Instructor can grade it from the review panel.");
  }

  async function gradeLatestSubmission() {
    if (!submission) return;

    const teacherToken = await apiRequest<{ token: string }>("/api/auth/dev_token", {
      method: "POST",
      body: JSON.stringify({ email: "teacher@example.edu" })
    });

    const response = await apiRequest<{ data: Submission }>(`/api/submissions/${submission.id}/grade`, {
      method: "PATCH",
      token: teacherToken.token,
      body: JSON.stringify({ grade: { score: 9 } })
    });

    setSubmission(response.data);
    setStatus("Submission graded. Grade is pending passback sync.");
  }

  async function syncGrades() {
    if (!assignment) return;

    const teacherToken = await apiRequest<{ token: string }>("/api/auth/dev_token", {
      method: "POST",
      body: JSON.stringify({ email: "teacher@example.edu" })
    });

    await apiRequest("/api/grade_syncs", {
      method: "POST",
      token: teacherToken.token,
      body: JSON.stringify({ grade_sync: { assignment_id: assignment.id } })
    });

    setStatus("Grade sync job queued. Sidekiq marks pending grades as synced.");
  }

  async function getAdminToken() {
    if (adminToken) return adminToken;

    const response = await apiRequest<{ token: string }>("/api/auth/dev_token", {
      method: "POST",
      body: JSON.stringify({ email: "admin@example.edu" })
    });
    setAdminToken(response.token);
    return response.token;
  }

  function rosterPayload() {
    return {
      users_csv: rosterUsersCsv,
      classes_csv: rosterClassesCsv,
      enrollments_csv: rosterEnrollmentsCsv
    };
  }

  async function loadAdminConsole() {
    setAdminStatus("Loading admin token and audit logs...");
    const token = await getAdminToken();
    await loadAuditLogs(token);
    setAdminStatus("Admin console loaded.");
  }

  async function previewRoster() {
    setAdminStatus("Validating roster import without writing rows...");
    const token = await getAdminToken();
    const response = await apiRequest<{ data: RosterPreview }>("/api/roster_imports/preview", {
      method: "POST",
      token,
      body: JSON.stringify({ roster: rosterPayload() })
    });
    setRosterPreview(response.data);
    setAdminStatus("Roster preview completed.");
  }

  async function queueRosterImport() {
    setAdminStatus("Queueing roster import job...");
    const token = await getAdminToken();
    const response = await apiRequest<{ data: JobRun }>("/api/roster_imports", {
      method: "POST",
      token,
      body: JSON.stringify({ roster: rosterPayload() })
    });
    setJobRun(response.data);
    setAdminStatus("Roster import job queued.");
  }

  async function refreshJobRun() {
    if (!jobRun) return;

    const token = await getAdminToken();
    const response = await apiRequest<{ data: JobRun }>(`/api/job_runs/${jobRun.id}`, { token });
    setJobRun(response.data);
    setAdminStatus("Job status refreshed.");
  }

  async function loadAuditLogs(token = adminToken) {
    const authToken = token || (await getAdminToken());
    const query = auditEvent.trim() ? `?event=${encodeURIComponent(auditEvent.trim())}` : "";
    const response = await apiRequest<{ data: AuditLog[] }>(`/api/audit_logs${query}`, { token: authToken });
    setAuditLogs(response.data);
  }

  return (
    <main className="app-shell">
      <section className="toolbar">
        <div>
          <p className="eyebrow">Canvas-style external tool prototype</p>
          <h1>Learning Integration Tool</h1>
        </div>
        <button onClick={launchAsLearner} className="primary-action">
          <BookOpen size={18} />
          Launch as Learner
        </button>
      </section>

      <section className="status-row" aria-live="polite">
        <CheckCircle2 size={18} />
        <span>{status}</span>
      </section>

      <section className="workspace">
        <article className="panel launch-panel">
          <h2>Launch Context</h2>
          <dl>
            <div>
              <dt>Role</dt>
              <dd>{launch?.launch_context.role ?? "Not launched"}</dd>
            </div>
            <div>
              <dt>Course</dt>
              <dd>{launch?.course_id ?? "-"}</dd>
            </div>
            <div>
              <dt>Assignment</dt>
              <dd>{assignment?.title ?? "-"}</dd>
            </div>
            <div>
              <dt>Resource Link</dt>
              <dd>{launch?.launch_context.resource_link_id ?? "-"}</dd>
            </div>
          </dl>
        </article>

        <article className="panel activity-panel">
          <h2>Learner Activity</h2>
          <p className="prompt">In one sentence, explain how a cell membrane helps a cell survive.</p>
          <textarea value={reflection} onChange={(event) => setReflection(event.target.value)} />
          <button onClick={submitActivity} disabled={!assignment || !apiToken}>
            Submit Activity
          </button>
        </article>

        <article className="panel grade-panel">
          <h2>Instructor Review</h2>
          <div className="grade-summary">
            <GraduationCap size={24} />
            <div>
              <strong>{submission ? submission.workflow_state : "Waiting for submission"}</strong>
              <span>Score: {submission?.score ?? "-"}</span>
              <span>Passback: {submission?.grade?.passback_status ?? "-"}</span>
            </div>
          </div>
          <button onClick={gradeLatestSubmission} disabled={!submission}>
            Grade 9 / 10
          </button>
          <button onClick={syncGrades} disabled={!submission?.grade} className="secondary-action">
            <RefreshCcw size={16} />
            Queue Grade Sync
          </button>
        </article>
      </section>

      <section className="admin-header">
        <div>
          <p className="eyebrow">Operations</p>
          <h2>Admin Console</h2>
        </div>
        <button onClick={loadAdminConsole} className="secondary-action">
          <ShieldCheck size={16} />
          Load Admin Console
        </button>
      </section>

      <section className="status-row admin-status" aria-live="polite">
        <ClipboardList size={18} />
        <span>{adminStatus}</span>
      </section>

      <section className="admin-console">
        <article className="panel roster-panel">
          <h2>Roster Import</h2>
          <label>
            Users CSV
            <textarea value={rosterUsersCsv} onChange={(event) => setRosterUsersCsv(event.target.value)} />
          </label>
          <label>
            Classes CSV
            <textarea value={rosterClassesCsv} onChange={(event) => setRosterClassesCsv(event.target.value)} />
          </label>
          <label>
            Enrollments CSV
            <textarea value={rosterEnrollmentsCsv} onChange={(event) => setRosterEnrollmentsCsv(event.target.value)} />
          </label>
          <div className="button-row">
            <button onClick={previewRoster}>Preview Roster</button>
            <button onClick={queueRosterImport} className="secondary-action">
              Queue Import
            </button>
          </div>
          <div className="metric-grid">
            <Metric label="Users" value={rosterPreview?.users_count} />
            <Metric label="Classes" value={rosterPreview?.classes_count} />
            <Metric label="Enrollments" value={rosterPreview?.enrollments_count} />
            <Metric label="Created" value={rosterPreview?.created_count} />
          </div>
        </article>

        <article className="panel job-panel">
          <h2>Job Status</h2>
          <div className="job-card">
            <strong>{jobRun ? `${jobRun.job_type} #${jobRun.id}` : "No job queued"}</strong>
            <span>Status: {jobRun?.status ?? "-"}</span>
            <span>Started: {formatDate(jobRun?.started_at)}</span>
            <span>Finished: {formatDate(jobRun?.finished_at)}</span>
            <span>Error: {jobRun?.error_message ?? "-"}</span>
          </div>
          <button onClick={refreshJobRun} disabled={!jobRun}>
            <RefreshCcw size={16} />
            Refresh Job
          </button>
        </article>

        <article className="panel audit-panel">
          <h2>Audit Logs</h2>
          <div className="audit-filter">
            <input
              aria-label="Audit event filter"
              placeholder="Filter by event"
              value={auditEvent}
              onChange={(event) => setAuditEvent(event.target.value)}
            />
            <button onClick={() => loadAuditLogs()}>Load Audit Logs</button>
          </div>
          <div className="audit-list">
            {auditLogs.length === 0 ? (
              <span className="empty-state">No audit logs loaded.</span>
            ) : (
              auditLogs.map((log) => (
                <div className="audit-item" key={log.id}>
                  <strong>{log.action}</strong>
                  <span>
                    {log.target_type} #{log.target_id ?? "-"} - {formatDate(log.created_at)}
                  </span>
                  <code>{JSON.stringify(log.metadata)}</code>
                </div>
              ))
            )}
          </div>
        </article>
      </section>
    </main>
  );
}

function Metric({ label, value }: { label: string; value?: number }) {
  return (
    <div>
      <strong>{value ?? "-"}</strong>
      <span>{label}</span>
    </div>
  );
}

function formatDate(value?: string | null) {
  return value ? new Date(value).toLocaleString() : "-";
}

ReactDOM.createRoot(document.getElementById("root")!).render(<App />);
