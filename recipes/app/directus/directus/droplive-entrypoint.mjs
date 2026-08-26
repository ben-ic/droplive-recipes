import { spawn } from "node:child_process";
import { existsSync, writeFileSync } from "node:fs";

const base = "http://127.0.0.1:8055";
const marker = "/directus/database/.droplive-northstar-seed-v1";

function fail(message) {
  throw new Error(message);
}

async function request(path, options = {}) {
  const response = await fetch(`${base}${path}`, options);
  const body = await response.text();
  let json = null;
  if (body) {
    try {
      json = JSON.parse(body);
    } catch {
      // The health endpoint can return a non-JSON proxy error while Directus starts.
    }
  }
  if (!response.ok) {
    fail(`${options.method || "GET"} ${path} returned ${response.status}: ${body.slice(0, 240)}`);
  }
  return json;
}

async function waitForDirectus() {
  for (let attempt = 0; attempt < 90; attempt += 1) {
    try {
      await request("/server/health");
      return;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }
  }
  fail("Directus did not become ready within 90 seconds");
}

function headers(token) {
  return {
    authorization: `Bearer ${token}`,
    "content-type": "application/json",
  };
}

function field(field, type, required = false) {
  return {
    field,
    type,
    meta: { interface: type === "text" ? "input-multiline" : "input", width: "full", required },
    schema: { is_nullable: !required },
  };
}

function primaryKey() {
  return {
    field: "id",
    type: "integer",
    meta: { hidden: true, readonly: true, interface: "input", width: "full" },
    schema: { has_auto_increment: true, is_primary_key: true, is_nullable: false },
  };
}

async function ensureCollection(token, collection, icon, note, fields) {
  try {
    await request("/collections", {
      method: "POST",
      headers: headers(token),
      body: JSON.stringify({ collection, meta: { icon, note }, schema: { name: collection }, fields }),
    });
  } catch {
    // A partially completed seed can already have the collection. Its fields
    // and rows remain individually idempotent below.
  }
}

async function grantOwnerAccess(token, collections) {
  const policies = await request("/policies", { headers: headers(token) });
  const policy = policies?.data?.find((item) => item.admin_access === true)?.id;
  if (!policy) fail("Directus administrator policy was not created during bootstrap");
  for (const collection of collections) {
    for (const action of ["create", "read", "update", "delete"]) {
      try {
        await request("/permissions", {
          method: "POST",
          headers: headers(token),
          body: JSON.stringify({ policy, collection, action, permissions: {}, validation: {}, fields: ["*"] }),
        });
      } catch {
        // The policy entry can already exist after an interrupted seed.
      }
    }
  }
}

async function ensureItem(token, collection, item) {
  const current = await request(
    `/items/${collection}?filter[external_ref][_eq]=${encodeURIComponent(item.external_ref)}&limit=1`,
    { headers: headers(token) },
  );
  if (current?.data?.length) return;
  await request(`/items/${collection}`, {
    method: "POST",
    headers: headers(token),
    body: JSON.stringify(item),
  });
}

async function seed() {
  if (existsSync(marker)) return;
  const password = process.env.ADMIN_PASSWORD;
  if (!password) fail("ADMIN_PASSWORD is required for the Directus fixture seed");

  const login = await request("/auth/login", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email: "maya@northstar-relay.example.com", password }),
  });
  let token = login?.data?.access_token;
  if (!token) fail("Directus owner sign-in returned no access token");

  await ensureCollection(token, "customer_accounts", "groups", "The customer accounts that Northstar Relay supports.", [
    primaryKey(), field("external_ref", "string", true), field("name", "string", true), field("status", "string", true),
    field("summary", "text"), field("plan", "string"), field("renewal_date", "date"),
  ]);
  await ensureCollection(token, "renewal_briefs", "description", "Current renewal work and the next customer action.", [
    primaryKey(), field("external_ref", "string", true), field("name", "string", true), field("status", "string", true),
    field("summary", "text"), field("owner", "string"), field("next_action", "string"),
  ]);
  await ensureCollection(token, "support_cases", "support_agent", "Customer cases that the release team tracks through to a safe outcome.", [
    primaryKey(), field("external_ref", "string", true), field("name", "string", true), field("status", "string", true),
    field("summary", "text"), field("owner", "string"), field("next_action", "string"), field("priority", "string"),
  ]);
  await ensureCollection(token, "release_work", "rocket_launch", "The release work that connects product changes to customer commitments.", [
    primaryKey(), field("external_ref", "string", true), field("name", "string", true), field("status", "string", true),
    field("summary", "text"), field("owner", "string"), field("next_action", "string"), field("priority", "string"),
  ]);
  await grantOwnerAccess(token, ["customer_accounts", "renewal_briefs", "support_cases", "release_work"]);
  // Directus reads policy grants into the access token. Sign in again so the
  // following item requests see the policy records just created.
  const refreshed = await request("/auth/login", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ email: "maya@northstar-relay.example.com", password }),
  });
  token = refreshed?.data?.access_token;
  if (!token) fail("Directus owner re-sign-in returned no access token");

  for (const item of [
    { external_ref: "acct-lumen", name: "Lumen Labs", status: "Renewal in progress", plan: "Northstar Scale", renewal_date: "2026-08-30", summary: "Usage is up 38% since February. Invoice 4471 is open and not overdue." },
    { external_ref: "acct-ember", name: "Ember Commerce", status: "Healthy", plan: "Northstar Growth", renewal_date: "2026-10-15", summary: "The data export team is reviewing a CSV header issue before the Q4 planning cycle." },
    { external_ref: "acct-harbor", name: "Harbor Mobility", status: "At risk", plan: "Northstar Scale", renewal_date: "2026-09-12", summary: "A 75k-row scheduled export needs the new worker timeout before the renewal review." },
    { external_ref: "acct-fieldnote", name: "Fieldnote Studio", status: "Healthy", plan: "Northstar Growth", renewal_date: "2026-11-03", summary: "The attachments export is stable. The customer asked for a short audit-history walkthrough." },
    { external_ref: "acct-copper", name: "Copper Lake Foods", status: "Attention needed", plan: "Northstar Growth", renewal_date: "2026-09-28", summary: "The finance owner needs a corrected monthly export before the close review." },
    { external_ref: "acct-cedar", name: "Cedar Health", status: "Healthy", plan: "Northstar Scale", renewal_date: "2026-12-18", summary: "The compliance workspace was added in June and adoption is on plan." },
  ]) await ensureItem(token, "customer_accounts", item);
  for (const item of [
    { external_ref: "brief-lumen-aug", name: "Lumen Labs renewal", status: "Waiting for engineering", owner: "Maya Chen", next_action: "Send the tested export workaround before 15:00 UTC.", summary: "Keep invoice 4471 separate from the export incident. The customer needs a clear status and a safe manual retry path." },
    { external_ref: "brief-harbor-sep", name: "Harbor Mobility renewal", status: "Risk review", owner: "Jon Bell", next_action: "Run the cancellation fixture at 75k rows and publish the result.", summary: "The interactive retry works. The scheduled route still uses the legacy worker timeout." },
    { external_ref: "brief-copper-sep", name: "Copper Lake close review", status: "Waiting for finance", owner: "Noor Alvarez", next_action: "Send the corrected August export and confirm the reconciliation fields.", summary: "The customer needs a complete month-end file before the finance review on Friday." },
    { external_ref: "brief-fieldnote-nov", name: "Fieldnote growth review", status: "Prepared", owner: "Maya Chen", next_action: "Share the audit-history walkthrough and confirm the attachment retention needs.", summary: "Usage is steady and the customer asked for a concise operational review." },
  ]) await ensureItem(token, "renewal_briefs", item);
  for (const item of [
    { external_ref: "case-lumen-export", name: "Scheduled export stops at two minutes", status: "Workaround sent", priority: "High", owner: "Samira Okafor", next_action: "Update Priya after the scheduled cancellation run.", summary: "Lumen reproduces the issue at 52,184 rows. Interactive retries succeed; the scheduled route uses the legacy worker timeout." },
    { external_ref: "case-ember-csv", name: "CSV header changed in August export", status: "Waiting for confirmation", priority: "Normal", owner: "David Banerjee", next_action: "Confirm the header fix with Ember Commerce before Friday.", summary: "The customer’s downstream import expects the old header order. The proposed compatibility option is ready." },
    { external_ref: "case-copper-close", name: "Finance export has an unmapped ledger field", status: "Investigating", priority: "High", owner: "Noor Alvarez", next_action: "Compare the July and August mappings and attach the corrected file.", summary: "Copper Lake can close the month only after the operating-cash reconciliation fields are present." },
    { external_ref: "case-fieldnote-audit", name: "Audit-history walkthrough request", status: "Scheduled", priority: "Normal", owner: "Maya Chen", next_action: "Run the 30-minute walkthrough on Thursday and capture follow-up questions.", summary: "Fieldnote Studio wants to confirm who can view export activity and retention events." },
    { external_ref: "case-harbor-timeout", name: "75k export renewal risk", status: "Engineering review", priority: "High", owner: "Jon Bell", next_action: "Attach the cancellation fixture evidence to the renewal brief.", summary: "Harbor’s renewal depends on a tested scheduled-export path for its largest data set." },
  ]) await ensureItem(token, "support_cases", item);
  for (const item of [
    { external_ref: "rel-28-owner", name: "Confirm Release 2.8 owner and scope", status: "Complete", priority: "High", owner: "Maya Chen", next_action: "Keep the approval record with the release notes.", summary: "The release scope includes audit history and the export cancellation fix. The owner and customer communication path are confirmed." },
    { external_ref: "rel-28-cancel", name: "Run 50k and 75k cancellation fixtures", status: "Ready for review", priority: "High", owner: "Jon Bell", next_action: "Publish results and ask Elena for release approval.", summary: "The fixture verifies worker-lease cleanup and removal of partial objects on a cancelled scheduled export." },
    { external_ref: "rel-28-notes", name: "Approve audit-history release notes", status: "In review", priority: "Normal", owner: "Elena Petrov", next_action: "Apply the product-language edits and mark the release notes approved.", summary: "The notes explain time display and export activity entries without exposing implementation details." },
    { external_ref: "rel-28-lumen", name: "Send Lumen workaround after release decision", status: "Blocked by approval", priority: "High", owner: "Samira Okafor", next_action: "Send Priya the safe retry path after approval.", summary: "The customer communication must not promise a release date before the cancellation evidence is accepted." },
    { external_ref: "rel-28-observe", name: "Observe first scheduled export after rollout", status: "Planned", priority: "Normal", owner: "David Banerjee", next_action: "Review latency and worker lease events at 09:00 UTC.", summary: "The release team will monitor the first production-like scheduled export and attach the observation to the support case." },
  ]) await ensureItem(token, "release_work", item);

  writeFileSync(marker, "seeded\n", { mode: 0o600 });
  console.error("[droplive] seeded Directus with 6 accounts, 4 renewal briefs, 5 support cases, and 5 release-work items");
}

const child = spawn("docker-entrypoint.sh", process.argv.slice(2), { stdio: "inherit" });
let stopping = false;
function stop(signal) {
  stopping = true;
  child.kill(signal);
}
for (const signal of ["SIGTERM", "SIGINT", "SIGHUP"]) process.on(signal, () => stop(signal));
child.on("exit", (code, signal) => process.exit(signal ? 1 : (code ?? 1)));

console.error("[droplive] waiting for Directus before the Northstar fixture seed");
waitForDirectus()
  .then(seed)
  .catch((error) => console.error(`[droplive] Directus fixture seed failed: ${error.message}`));
