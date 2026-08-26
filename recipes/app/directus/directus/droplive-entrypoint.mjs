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
  await grantOwnerAccess(token, ["customer_accounts", "renewal_briefs"]);
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
  ]) await ensureItem(token, "customer_accounts", item);
  for (const item of [
    { external_ref: "brief-lumen-aug", name: "Lumen Labs renewal", status: "Waiting for engineering", owner: "Maya Chen", next_action: "Send the tested export workaround before 15:00 UTC.", summary: "Keep invoice 4471 separate from the export incident. The customer needs a clear status and a safe manual retry path." },
    { external_ref: "brief-harbor-sep", name: "Harbor Mobility renewal", status: "Risk review", owner: "Jon Bell", next_action: "Run the cancellation fixture at 75k rows and publish the result.", summary: "The interactive retry works. The scheduled route still uses the legacy worker timeout." },
  ]) await ensureItem(token, "renewal_briefs", item);

  writeFileSync(marker, "seeded\n", { mode: 0o600 });
  console.error("[droplive] seeded Directus with 3 customer accounts and 2 renewal briefs");
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
