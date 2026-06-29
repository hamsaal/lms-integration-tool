const encoder = new TextEncoder();

export async function createDemoLaunchToken() {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: "https://canvas.example.edu",
    aud: "learning-integrations-rails-api",
    sub: "student-001",
    nonce: `nonce-${crypto.randomUUID()}`,
    exp: now + 300,
    name: "Alex Student",
    email: "student@example.edu",
    roles: ["Learner"],
    organization_name: "Canvas Demo School",
    course_id: "canvas-course-101",
    course_title: "Biology 101",
    course_code: "BIO-101",
    assignment_id: "canvas-assignment-quiz-1",
    assignment_title: "Cell Structure Check",
    resource_link_id: "resource-link-cell-check",
    points_possible: 10
  };

  return signHs256(payload, import.meta.env.VITE_DEMO_JWT_SECRET ?? "development-only-secret");
}

async function signHs256(payload: Record<string, unknown>, secret: string) {
  const header = { alg: "HS256", typ: "JWT" };
  const body = `${base64Url(JSON.stringify(header))}.${base64Url(JSON.stringify(payload))}`;
  const key = await crypto.subtle.importKey("raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"]);
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(body));
  return `${body}.${base64Url(signature)}`;
}

function base64Url(input: string | ArrayBuffer) {
  const bytes = typeof input === "string" ? encoder.encode(input) : new Uint8Array(input);
  let binary = "";
  bytes.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });

  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
