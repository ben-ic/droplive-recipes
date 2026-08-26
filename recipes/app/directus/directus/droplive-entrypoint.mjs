import { spawn } from "node:child_process";
import { existsSync, writeFileSync } from "node:fs";

const base = "http://127.0.0.1:8055";
const marker = "/directus/database/.droplive-northstar-seed-v3";

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
  for (const definition of fields.filter(({ field: name }) => name !== "id")) {
    try {
      await request(`/fields/${collection}`, {
        method: "POST",
        headers: headers(token),
        body: JSON.stringify(definition),
      });
    } catch {
      // A fresh collection already has these fields. A persisted demo can have
      // only the earlier seed, so field creation is deliberately idempotent.
    }
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

async function ensureDashboard(token, dashboard) {
  const current = await request(
    `/dashboards?filter[name][_eq]=${encodeURIComponent(dashboard.name)}&fields=id&limit=1`,
    { headers: headers(token) },
  );
  if (current?.data?.length) return current.data[0].id;
  const created = await request("/dashboards", {
    method: "POST",
    headers: headers(token),
    body: JSON.stringify(dashboard),
  });
  return created?.data?.id;
}

async function ensurePanel(token, dashboard, panel) {
  const current = await request(
    `/panels?filter[dashboard][_eq]=${encodeURIComponent(dashboard)}&filter[name][_eq]=${encodeURIComponent(panel.name)}&fields=id&limit=1`,
    { headers: headers(token) },
  );
  if (current?.data?.length) return;
  await request("/panels", {
    method: "POST",
    headers: headers(token),
    body: JSON.stringify({ dashboard, ...panel }),
  });
}

async function seedDashboard(token, dashboard, panels) {
  const dashboardId = await ensureDashboard(token, dashboard);
  if (!dashboardId) fail(`Dashboard ${dashboard.name} was not created`);
  for (const panel of panels) await ensurePanel(token, dashboardId, panel);
}

function metricPanel(name, collection, field, functionName, x, y, color, note, prefix = "", suffix = "") {
  return {
    name, icon: "analytics", color, note, type: "metric", show_header: true,
    position_x: x, position_y: y, width: 6, height: 8,
    options: { collection, field, function: functionName, prefix, suffix, abbreviate: false },
  };
}

function listPanel(name, collection, displayTemplate, x, y, width, height, note) {
  return {
    name, icon: "view_list", color: "#3B82F6", note, type: "list", show_header: true,
    position_x: x, position_y: y, width, height,
    // These are the documented v11 list-panel keys. The panel itself derives
    // the GraphQL fields from the display template, so every visible row has
    // a valid query and a concise operational summary.
    options: { collection, sortField: "id", sortDirection: "desc", limit: 6, displayTemplate, linkToItem: true },
  };
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
    field("annual_contract_value", "integer"), field("active_seats", "integer"), field("health_score", "integer"), field("last_check_in", "date"),
  ]);
  await ensureCollection(token, "renewal_briefs", "description", "Current renewal work and the next customer action.", [
    primaryKey(), field("external_ref", "string", true), field("name", "string", true), field("status", "string", true),
    field("summary", "text"), field("owner", "string"), field("next_action", "string"), field("forecast_amount", "integer"), field("decision_date", "date"),
  ]);
  await ensureCollection(token, "support_cases", "support_agent", "Customer cases that the release team tracks through to a safe outcome.", [
    primaryKey(), field("external_ref", "string", true), field("name", "string", true), field("status", "string", true),
    field("summary", "text"), field("owner", "string"), field("next_action", "string"), field("priority", "string"), field("opened_on", "date"), field("hours_to_next_update", "integer"),
  ]);
  await ensureCollection(token, "release_work", "rocket_launch", "The release work that connects product changes to customer commitments.", [
    primaryKey(), field("external_ref", "string", true), field("name", "string", true), field("status", "string", true),
    field("summary", "text"), field("owner", "string"), field("next_action", "string"), field("priority", "string"), field("due_date", "date"), field("confidence_score", "integer"),
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
    { external_ref: "acct-lumen", name: "Lumen Labs", status: "Renewal in progress", plan: "Northstar Scale", renewal_date: "2026-08-30", annual_contract_value: 186000, active_seats: 184, health_score: 62, last_check_in: "2026-08-25", summary: "Usage is up 38% since February. Invoice 4471 is open and not overdue." },
    { external_ref: "acct-ember", name: "Ember Commerce", status: "Healthy", plan: "Northstar Growth", renewal_date: "2026-10-15", annual_contract_value: 78000, active_seats: 73, health_score: 88, last_check_in: "2026-08-22", summary: "The data export team is reviewing a CSV header issue before the Q4 planning cycle." },
    { external_ref: "acct-harbor", name: "Harbor Mobility", status: "At risk", plan: "Northstar Scale", renewal_date: "2026-09-12", annual_contract_value: 142000, active_seats: 126, health_score: 48, last_check_in: "2026-08-25", summary: "A 75k-row scheduled export needs the new worker timeout before the renewal review." },
    { external_ref: "acct-fieldnote", name: "Fieldnote Studio", status: "Healthy", plan: "Northstar Growth", renewal_date: "2026-11-03", annual_contract_value: 54000, active_seats: 51, health_score: 91, last_check_in: "2026-08-19", summary: "The attachments export is stable. The customer asked for a short audit-history walkthrough." },
    { external_ref: "acct-copper", name: "Copper Lake Foods", status: "Attention needed", plan: "Northstar Growth", renewal_date: "2026-09-28", annual_contract_value: 96000, active_seats: 88, health_score: 57, last_check_in: "2026-08-24", summary: "The finance owner needs a corrected monthly export before the close review." },
    { external_ref: "acct-cedar", name: "Cedar Health", status: "Healthy", plan: "Northstar Scale", renewal_date: "2026-12-18", annual_contract_value: 164000, active_seats: 148, health_score: 86, last_check_in: "2026-08-21", summary: "The compliance workspace was added in June and adoption is on plan." },
    { external_ref: "acct-aurora", name: "Aurora Logistics", status: "Healthy", plan: "Northstar Scale", renewal_date: "2027-01-22", annual_contract_value: 128000, active_seats: 117, health_score: 84, last_check_in: "2026-08-18", summary: "The dispatch analytics rollout is complete and the regional manager asked for an adoption review." },
    { external_ref: "acct-vanta", name: "Vanta Works", status: "Attention needed", plan: "Northstar Growth", renewal_date: "2026-09-05", annual_contract_value: 69000, active_seats: 64, health_score: 59, last_check_in: "2026-08-23", summary: "The operations lead needs a role-permission review before the renewal decision." },
    { external_ref: "acct-kinetic", name: "Kinetic Energy", status: "Healthy", plan: "Northstar Scale", renewal_date: "2027-02-14", annual_contract_value: 212000, active_seats: 202, health_score: 93, last_check_in: "2026-08-20", summary: "The fleet telemetry team adopted the new scheduled reporting workflow in all regions." },
    { external_ref: "acct-nomad", name: "Nomad Freight", status: "At risk", plan: "Northstar Growth", renewal_date: "2026-09-19", annual_contract_value: 82000, active_seats: 76, health_score: 44, last_check_in: "2026-08-25", summary: "Two supervisors report delayed weekly exports after the data-retention change." },
    { external_ref: "acct-alder", name: "Alder & Finch", status: "Healthy", plan: "Northstar Growth", renewal_date: "2026-12-06", annual_contract_value: 61000, active_seats: 57, health_score: 89, last_check_in: "2026-08-16", summary: "The customer success team completed its quarterly business review with no open commitments." },
    { external_ref: "acct-solis", name: "Solis Clinics", status: "Attention needed", plan: "Northstar Scale", renewal_date: "2026-10-02", annual_contract_value: 154000, active_seats: 139, health_score: 63, last_check_in: "2026-08-24", summary: "The compliance owner asked for a data-access report before the next clinical governance meeting." },
    { external_ref: "acct-river", name: "River & Rail", status: "Healthy", plan: "Northstar Growth", renewal_date: "2027-03-11", annual_contract_value: 47000, active_seats: 43, health_score: 87, last_check_in: "2026-08-17", summary: "The small operations team expanded usage after the dispatch import improvements." },
  ]) await ensureItem(token, "customer_accounts", item);
  for (const item of [
    { external_ref: "brief-lumen-aug", name: "Lumen Labs renewal", status: "Waiting for engineering", owner: "Maya Chen", forecast_amount: 186000, decision_date: "2026-08-30", next_action: "Send the tested export workaround before 15:00 UTC.", summary: "Keep invoice 4471 separate from the export incident. The customer needs a clear status and a safe manual retry path." },
    { external_ref: "brief-harbor-sep", name: "Harbor Mobility renewal", status: "Risk review", owner: "Jon Bell", forecast_amount: 142000, decision_date: "2026-09-12", next_action: "Run the cancellation fixture at 75k rows and publish the result.", summary: "The interactive retry works. The scheduled route still uses the legacy worker timeout." },
    { external_ref: "brief-copper-sep", name: "Copper Lake close review", status: "Waiting for finance", owner: "Noor Alvarez", forecast_amount: 96000, decision_date: "2026-09-28", next_action: "Send the corrected August export and confirm the reconciliation fields.", summary: "The customer needs a complete month-end file before the finance review on Friday." },
    { external_ref: "brief-fieldnote-nov", name: "Fieldnote growth review", status: "Prepared", owner: "Maya Chen", forecast_amount: 54000, decision_date: "2026-11-03", next_action: "Share the audit-history walkthrough and confirm the attachment retention needs.", summary: "Usage is steady and the customer asked for a concise operational review." },
    { external_ref: "brief-nomad-sep", name: "Nomad Freight recovery review", status: "Executive check-in", owner: "Samira Okafor", forecast_amount: 82000, decision_date: "2026-09-19", next_action: "Agree the export-reliability recovery plan with the operations sponsor.", summary: "Two supervisors report late weekly exports. The renewal decision needs an agreed recovery milestone." },
    { external_ref: "brief-solis-oct", name: "Solis Clinics governance review", status: "Prepared", owner: "Noor Alvarez", forecast_amount: 154000, decision_date: "2026-10-02", next_action: "Review the data-access evidence with the clinical governance lead.", summary: "The renewal is healthy if the audit report answers the compliance owner’s questions." },
  ]) await ensureItem(token, "renewal_briefs", item);
  for (const item of [
    { external_ref: "case-lumen-export", name: "Scheduled export stops at two minutes", status: "Workaround sent", priority: "High", owner: "Samira Okafor", next_action: "Update Priya after the scheduled cancellation run.", summary: "Lumen reproduces the issue at 52,184 rows. Interactive retries succeed; the scheduled route uses the legacy worker timeout." },
    { external_ref: "case-ember-csv", name: "CSV header changed in August export", status: "Waiting for confirmation", priority: "Normal", owner: "David Banerjee", next_action: "Confirm the header fix with Ember Commerce before Friday.", summary: "The customer’s downstream import expects the old header order. The proposed compatibility option is ready." },
    { external_ref: "case-copper-close", name: "Finance export has an unmapped ledger field", status: "Investigating", priority: "High", owner: "Noor Alvarez", next_action: "Compare the July and August mappings and attach the corrected file.", summary: "Copper Lake can close the month only after the operating-cash reconciliation fields are present." },
    { external_ref: "case-fieldnote-audit", name: "Audit-history walkthrough request", status: "Scheduled", priority: "Normal", owner: "Maya Chen", next_action: "Run the 30-minute walkthrough on Thursday and capture follow-up questions.", summary: "Fieldnote Studio wants to confirm who can view export activity and retention events." },
    { external_ref: "case-harbor-timeout", name: "75k export renewal risk", status: "Engineering review", priority: "High", owner: "Jon Bell", next_action: "Attach the cancellation fixture evidence to the renewal brief.", summary: "Harbor’s renewal depends on a tested scheduled-export path for its largest data set." },
  ]) await ensureItem(token, "support_cases", item);
  for (const item of [
    { external_ref: "rel-28-owner", name: "Confirm Release 2.8 owner and scope", status: "Complete", priority: "High", owner: "Maya Chen", due_date: "2026-08-25", confidence_score: 96, next_action: "Keep the approval record with the release notes.", summary: "The release scope includes audit history and the export cancellation fix. The owner and customer communication path are confirmed." },
    { external_ref: "rel-28-cancel", name: "Run 50k and 75k cancellation fixtures", status: "Ready for review", priority: "High", owner: "Jon Bell", due_date: "2026-08-27", confidence_score: 82, next_action: "Publish results and ask Elena for release approval.", summary: "The fixture verifies worker-lease cleanup and removal of partial objects on a cancelled scheduled export." },
    { external_ref: "rel-28-notes", name: "Approve audit-history release notes", status: "In review", priority: "Normal", owner: "Elena Petrov", due_date: "2026-08-28", confidence_score: 74, next_action: "Apply the product-language edits and mark the release notes approved.", summary: "The notes explain time display and export activity entries without exposing implementation details." },
    { external_ref: "rel-28-lumen", name: "Send Lumen workaround after release decision", status: "Blocked by approval", priority: "High", owner: "Samira Okafor", next_action: "Send Priya the safe retry path after approval.", summary: "The customer communication must not promise a release date before the cancellation evidence is accepted." },
    { external_ref: "rel-28-observe", name: "Observe first scheduled export after rollout", status: "Planned", priority: "Normal", owner: "David Banerjee", next_action: "Review latency and worker lease events at 09:00 UTC.", summary: "The release team will monitor the first production-like scheduled export and attach the observation to the support case." },
  ]) await ensureItem(token, "release_work", item);

  await seedDashboard(token, {
    name: "Northstar Command Center", icon: "space_dashboard", color: "#2563EB",
    note: "The live customer, support, and release picture for the week.",
  }, [
    metricPanel("Contract value", "customer_accounts", "annual_contract_value", "sum", 1, 1, "#2563EB", "Annual contract value across the operating portfolio.", "$"),
    metricPanel("Active seats", "customer_accounts", "active_seats", "sum", 7, 1, "#0F766E", "People actively using Northstar Relay.", "", " seats"),
    metricPanel("Portfolio health", "customer_accounts", "health_score", "avg", 13, 1, "#F59E0B", "Average account health score across the portfolio.", "", "/100"),
    listPanel("Customer attention queue", "customer_accounts", "{{ name }} · {{ status }} · renewal {{ renewal_date }}", 1, 9, 12, 14, "Renewals and accounts that need a decision."),
    listPanel("Support handoffs", "support_cases", "{{ name }} · {{ priority }} · {{ owner }}", 13, 9, 12, 14, "Customer commitments with a named next action."),
  ]);
  await seedDashboard(token, {
    name: "Release Readiness", icon: "rocket_launch", color: "#7C3AED",
    note: "A working release board: ownership, evidence, approvals, and customer communication.",
  }, [
    metricPanel("Release confidence", "release_work", "confidence_score", "avg", 1, 1, "#16A34A", "Average confidence from release evidence and approval readiness.", "", "/100"),
    metricPanel("Work in flight", "release_work", "id", "count", 7, 1, "#7C3AED", "Release commitments with an owner and next action."),
    listPanel("Release board", "release_work", "{{ name }} · {{ status }} · {{ owner }}", 1, 9, 12, 16, "What ships next, who owns it, and what blocks it."),
    listPanel("Customer communication", "renewal_briefs", "{{ name }} · {{ status }} · {{ owner }}", 13, 9, 12, 16, "Customer reviews that depend on a safe release result."),
  ]);
  await seedDashboard(token, {
    name: "Customer Health Review", icon: "favorite", color: "#0F766E",
    note: "Prepare the weekly customer operating review from real support and renewal work.",
  }, [
    metricPanel("Renewal value", "renewal_briefs", "forecast_amount", "sum", 1, 1, "#0F766E", "Forecast value of customer decisions in the review window.", "$"),
    metricPanel("Accounts tracked", "customer_accounts", "id", "count", 7, 1, "#F59E0B", "Customer accounts reviewed this week."),
    listPanel("Renewal work", "renewal_briefs", "{{ name }} · {{ status }} · {{ owner }}", 1, 9, 12, 16, "The next customer action is visible without opening each record."),
    listPanel("Case follow-up", "support_cases", "{{ name }} · {{ priority }} · {{ owner }}", 13, 9, 12, 16, "Support work that can change a customer outcome."),
  ]);

  writeFileSync(marker, "seeded\n", { mode: 0o600 });
  console.error("[droplive] seeded Directus with 13 accounts, 6 renewal briefs, 5 support cases, 5 release-work items, and 3 dashboards");
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
