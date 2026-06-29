import React from "react";
import ReactDOM from "react-dom/client";
import { BookOpen, CheckCircle2, GraduationCap, RefreshCcw } from "lucide-react";
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

function App() {
  const [apiToken, setApiToken] = React.useState("");
  const [launch, setLaunch] = React.useState<LaunchContext | null>(null);
  const [assignments, setAssignments] = React.useState<Assignment[]>([]);
  const [submission, setSubmission] = React.useState<Submission | null>(null);
  const [reflection, setReflection] = React.useState("Cells use membranes to control what enters and leaves.");
  const [status, setStatus] = React.useState("Ready to simulate a Canvas launch.");

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
    </main>
  );
}

ReactDOM.createRoot(document.getElementById("root")!).render(<App />);
