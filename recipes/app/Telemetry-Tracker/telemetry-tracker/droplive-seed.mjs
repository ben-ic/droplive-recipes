import { createHash } from "node:crypto";
import { PrismaClient } from "@prisma/client";
import { hashPassword } from "./dist/lib/password.js";

const prisma = new PrismaClient();

const ids = {
  org: "51000000-0000-4000-8000-000000000001",
  owner: "51000000-0000-4000-8000-000000000010",
  editor: "51000000-0000-4000-8000-000000000011",
  viewer: "51000000-0000-4000-8000-000000000012",
  project: "51000000-0000-4000-8000-000000000100",
  projectMobile: "51000000-0000-4000-8000-000000000101",
};

const now = new Date();
const minutesAgo = (minutes) => new Date(now.getTime() - minutes * 60_000);
const daysAgo = (days, minutes = 0) => minutesAgo(days * 1440 + minutes);
const pick = (values, index) => values[index % values.length];
const sha = (value) => createHash("sha256").update(value).digest("hex");

const customers = [
  ["Avery Brooks", "avery@acmelogistics.test", "Acme Logistics"],
  ["Sofia Marin", "sofia@junipergoods.test", "Juniper Goods"],
  ["Noah Williams", "noah@morrowsupply.test", "Morrow Supply"],
  ["Fatima Zahra", "fatima@atlasfulfillment.test", "Atlas Fulfillment"],
  ["Ethan Park", "ethan@brightlane.test", "Brightlane Retail"],
  ["Camille Laurent", "camille@maisonverte.test", "Maison Verte"],
  ["Mateo Silva", "mateo@coastlinefoods.test", "Coastline Foods"],
  ["Priyanka Rao", "priyanka@orbitparts.test", "Orbit Parts"],
  ["Jonas Weber", "jonas@northwindlabs.test", "Northwind Labs"],
  ["Amara Okafor", "amara@kitemarket.test", "Kite Market"],
  ["Grace Kim", "grace@fieldstonehome.test", "Fieldstone Home"],
  ["Owen Campbell", "owen@cedaroutfitters.test", "Cedar Outfitters"],
  ["Leila Haddad", "leila@harborhealth.test", "Harbor Health"],
  ["Hugo Martin", "hugo@voltwheels.test", "Volt Wheels"],
  ["Mina Tanaka", "mina@papercrane.test", "Paper Crane"],
  ["Samuel Mensah", "samuel@laketrading.test", "Lake Trading"],
  ["Nora Jensen", "nora@fjordstudio.test", "Fjord Studio"],
  ["Diego Morales", "diego@solcommerce.test", "Sol Commerce"],
  ["Elena Rossi", "elena@terracotta.test", "Terracotta"],
  ["Isaac Cohen", "isaac@cornerstoneops.test", "Cornerstone Ops"],
  ["Zara Khan", "zara@kindredcare.test", "Kindred Care"],
  ["Theo Bernard", "theo@ateliernorth.test", "Atelier North"],
  ["Anika Patel", "anika@meridianworks.test", "Meridian Works"],
  ["Liam O'Brien", "liam@wildfern.test", "Wildfern"],
];

const customerAt = (index) => {
  const [name, email, company] = pick(customers, index);
  return { id: `contact-${String((index % customers.length) + 1).padStart(3, "0")}`, name, email, company };
};

function uuid(kind, index) {
  const hex = createHash("sha256").update(`${kind}:${index}`).digest("hex");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-8${hex.slice(17, 20)}-${hex.slice(20, 32)}`;
}

async function seedIdentity() {
  const password = process.env.TELEMETRY_OWNER_PASSWORD;
  if (!password) throw new Error("TELEMETRY_OWNER_PASSWORD is required");

  await prisma.organization.upsert({
    where: { id: ids.org },
    update: { name: "Northstar Relay", plan_tier: "BUSINESS", deleted_at: null },
    create: { id: ids.org, name: "Northstar Relay", plan_tier: "BUSINESS", created_at: daysAgo(420) },
  });

  const users = [
    { id: ids.owner, email: "owner@northstar-relay.test", display_name: "Lucas Ferreira", role: "OWNER" },
    { id: ids.editor, email: "maya@northstar-relay.test", display_name: "Maya Chen", role: "EDITOR" },
    { id: ids.viewer, email: "priya@northstar-relay.test", display_name: "Priya Nair", role: "VIEWER" },
  ];
  for (const user of users) {
    const password_hash = user.id === ids.owner ? hashPassword(password) : hashPassword(sha(user.email));
    await prisma.user.upsert({
      where: { email: user.email },
      update: { display_name: user.display_name, password_hash },
      create: {
        id: user.id,
        email: user.email,
        display_name: user.display_name,
        password_hash,
        created_at: daysAgo(user.role === "OWNER" ? 410 : 220),
      },
    });
    await prisma.organizationMembership.upsert({
      where: { user_id_organization_id: { user_id: user.id, organization_id: ids.org } },
      update: { role: user.role },
      create: {
        id: uuid("membership", users.indexOf(user)),
        user_id: user.id,
        organization_id: ids.org,
        role: user.role,
        created_at: daysAgo(user.role === "OWNER" ? 410 : 220),
      },
    });
  }

  await prisma.project.upsert({
    where: { id: ids.project },
    update: {
      name: "Relay Console",
      slug: "relay-console",
      deleted_at: null,
      alert_settings: {
        errorSpike: { enabled: true, threshold: 20, windowMinutes: 15 },
        quota: { enabled: true, nearPercent: 80 },
        email: { roles: ["OWNER", "EDITOR"] },
      },
      pii_scrub_settings: { denyKeys: ["password", "token", "authorization", "credit_card"] },
    },
    create: {
      id: ids.project,
      organization_id: ids.org,
      name: "Relay Console",
      slug: "relay-console",
      created_at: daysAgo(350),
      alert_settings: {
        errorSpike: { enabled: true, threshold: 20, windowMinutes: 15 },
        quota: { enabled: true, nearPercent: 80 },
        email: { roles: ["OWNER", "EDITOR"] },
      },
      pii_scrub_settings: { denyKeys: ["password", "token", "authorization", "credit_card"] },
    },
  });

  await prisma.project.upsert({
    where: { id: ids.projectMobile },
    update: { name: "Relay Mobile", slug: "relay-mobile", deleted_at: null },
    create: {
      id: ids.projectMobile,
      organization_id: ids.org,
      name: "Relay Mobile",
      slug: "relay-mobile",
      created_at: daysAgo(95),
    },
  });
}

async function clearDemoRows() {
  await prisma.alertWebhookDelivery.deleteMany({ where: { project_id: ids.project } });
  await prisma.alertEvent.deleteMany({ where: { project_id: ids.project } });
  await prisma.projectWebhook.deleteMany({ where: { project_id: ids.project } });
  await prisma.alertRule.deleteMany({ where: { project_id: ids.project } });
  await prisma.sourceMapArtifact.deleteMany({ where: { project_id: ids.project } });
  await prisma.errorOccurrence.deleteMany({ where: { error_group: { project_id: ids.project } } });
  await prisma.errorGroup.deleteMany({ where: { project_id: ids.project } });
  await prisma.event.deleteMany({ where: { project_id: ids.project } });
  await prisma.session.deleteMany({ where: { project_id: ids.project } });
  await prisma.usageMonthly.deleteMany({ where: { project_id: ids.project } });
  await prisma.apiKey.deleteMany({ where: { project_id: ids.project } });
  await prisma.organizationAuditEvent.deleteMany({ where: { organization_id: ids.org } });
}

async function seedSessions() {
  const countries = ["US", "DE", "GB", "CA", "NL", "AU", "FR", "SG"];
  const browsers = ["Chrome", "Safari", "Firefox", "Edge"];
  const systems = ["macOS", "Windows", "iOS", "Android", "Linux"];
  const rows = [];
  for (let i = 0; i < 420; i += 1) {
    const customer = customerAt(i * 7);
    const started = minutesAgo(i * 12 + (i % 7) * 2);
    const duration = 4 + ((i * 17) % 43);
    rows.push({
      id: uuid("session", i),
      project_id: ids.project,
      session_id: `relay-session-${String(i + 1).padStart(4, "0")}`,
      app: i % 7 === 0 ? "relay-admin" : "relay-web",
      platform: i % 5 === 0 ? "mobile-web" : "web",
      environment: i % 29 === 0 ? "staging" : "production",
      release: i < 86 ? "2026.08.4" : i < 246 ? "2026.08.3" : "2026.08.2",
      user_id: customer.id,
      anonymous_id: `browser-${sha(customer.email).slice(0, 10)}`,
      user_email: customer.email,
      country: pick(countries, i * 3),
      device_browser: pick(browsers, i),
      device_os: pick(systems, i * 2),
      sdk_version: "1.17.5",
      started_at: started,
      ended_at: i < 3 ? null : new Date(started.getTime() + duration * 60_000),
    });
  }
  await prisma.session.createMany({ data: rows });
}

async function seedEvents() {
  const productEvents = [
    "workspace_opened",
    "shipment_created",
    "route_optimized",
    "tracking_link_shared",
    "exception_reviewed",
    "delivery_confirmed",
    "team_member_invited",
    "report_exported",
  ];
  const routes = ["/dashboard", "/shipments", "/routes", "/exceptions", "/reports", "/settings/team"];
  const releases = ["2026.08.4", "2026.08.3", "2026.08.2"];
  const rows = [];

  for (let i = 0; i < 8500; i += 1) {
    const customer = customerAt(i * 11);
    const route = pick(routes, i * 5);
    rows.push({
      id: uuid("event", i),
      project_id: ids.project,
      app: i % 8 === 0 ? "relay-admin" : "relay-web",
      platform: "web",
      environment: i % 31 === 0 ? "staging" : "production",
      release: pick(releases, Math.floor(i / 130)),
      name: pick(productEvents, i * 3),
      user_id: customer.id,
      session_id: `relay-session-${String((i % 420) + 1).padStart(4, "0")}`,
      anonymous_id: `browser-${sha(customer.email).slice(0, 10)}`,
      sdk_version: "1.17.5",
      properties: {
        route,
        workspace: customer.company,
        plan: pick(["growth", "business", "starter"], i * 2),
        source: pick(["navigation", "command-palette", "notification"], i * 5),
        shipment_id: `SHP-${20260000 + (i % 1840)}`,
        carrier: pick(["DHL", "UPS", "FedEx", "LocalFleet"], i * 3),
      },
      created_at: minutesAgo(Math.floor(i * 0.72) + (i % 5)),
    });
  }

  for (let i = 0; i < 2500; i += 1) {
    const customer = customerAt(i * 5);
    const route = pick(routes, i);
    rows.push({
      id: uuid("request", i),
      project_id: ids.project,
      app: "relay-api",
      platform: "node",
      environment: "production",
      release: pick(releases, Math.floor(i / 90)),
      name: "$request",
      user_id: customer.id,
      session_id: `relay-session-${String((i % 420) + 1).padStart(4, "0")}`,
      sdk_version: "1.17.5",
      properties: {
        method: i % 5 === 0 ? "POST" : "GET",
        url: `https://app.northstar-relay.test${route}`,
        path: route,
        duration_ms: 54 + ((i * 47) % 520),
        status_code: i % 211 === 0 ? 500 : i % 97 === 0 ? 429 : i % 23 === 0 ? 204 : 200,
        region: pick(["iad", "fra", "lhr", "sin"], i),
      },
      created_at: minutesAgo(Math.floor(i * 1.55) + 3),
    });
  }

  const metrics = ["LCP", "INP", "CLS", "TTFB"];
  for (let i = 0; i < 1000; i += 1) {
    const customer = customerAt(i * 13);
    const metric = pick(metrics, i);
    const base = metric === "LCP" ? 1550 : metric === "INP" ? 85 : metric === "CLS" ? 0.035 : 310;
    const spread =
      metric === "LCP" ? (i * 41) % 1250
        : metric === "INP" ? (i * 17) % 260
          : metric === "CLS" ? ((i * 7) % 14) / 100
            : (i * 29) % 760;
    rows.push({
      id: uuid("vital", i),
      project_id: ids.project,
      app: "relay-web",
      platform: "web",
      environment: "production",
      release: pick(releases, Math.floor(i / 85)),
      name: "$web_vital",
      user_id: customer.id,
      session_id: `relay-session-${String((i % 420) + 1).padStart(4, "0")}`,
      sdk_version: "1.17.5",
      properties: { metric, value: base + spread, path: pick(routes, i * 3) },
      created_at: minutesAgo(Math.floor(i * 3.6) + 7),
    });
  }

  await prisma.event.createMany({ data: rows });
}

async function seedErrors() {
  const groups = [
    ["Carrier rate request exceeded 2.5 s", "at fetchCarrierRates (src/carriers/rates.ts:118:17)", "relay-api", "node", 18, false],
    ["Route map could not render a checkpoint", "at ShipmentMap (src/components/ShipmentMap.tsx:142:29)", "relay-web", "web", 14, false],
    ["Webhook signature rejected after carrier key rotation", "at verifyCarrierWebhook (src/webhooks/carrier.ts:61:11)", "relay-api", "node", 11, false],
    ["Delivery checkpoint write conflicted", "at saveCheckpoint (src/workers/checkpoints.ts:118:13)", "relay-worker", "node", 9, false],
    ["Operations export exceeded the workbook row limit", "at buildOperationsExport (src/reports/export.ts:207:9)", "relay-api", "node", 7, true],
    ["Notification preference update conflicted", "at updatePreferences (src/settings/notifications.ts:73:15)", "relay-web", "web", 5, true],
    ["Geocoder returned an incomplete dock address", "at normalizeAddress (src/geocoding/normalize.ts:49:7)", "relay-worker", "node", 4, true],
  ];
  for (let g = 0; g < groups.length; g += 1) {
    const [message, top_stack, app, platform, count, resolved] = groups[g];
    const groupId = uuid("error-group", g);
    await prisma.errorGroup.create({
      data: {
        id: groupId,
        project_id: ids.project,
        fingerprint: sha(`${app}:${message}`).slice(0, 32),
        message,
        top_stack,
        app,
        environment: g === 6 ? "staging" : "production",
        release: g < 3 ? "2026.08.4" : g < 6 ? "2026.08.3" : "2026.08.2",
        platform,
        occurrences: count,
        first_seen: daysAgo(12 - g),
        last_seen: minutesAgo(12 + g * 43),
        resolved_at: resolved ? daysAgo(1 + (g % 2), 90) : null,
      },
    });
    const occurrences = [];
    for (let i = 0; i < count; i += 1) {
      occurrences.push({
        id: uuid(`occurrence-${g}`, i),
        error_group_id: groupId,
        stack: `${top_stack}\n    at processRequest (src/server/request.ts:${90 + g}:11)\n    at async handler (src/server/handler.ts:31:5)`,
        release: g < 3 ? "2026.08.4" : g < 6 ? "2026.08.3" : "2026.08.2",
        platform,
        environment: g === 6 ? "staging" : "production",
        context: {
          route: pick(["/routes/optimize", "/shipments/active", "/exceptions", "/reports/operations"], g + i),
          request_id: `req_${sha(`${g}:${i}`).slice(0, 12)}`,
          carrier: pick(["DHL", "UPS", "FedEx", "LocalFleet"], i),
          handled: false,
        },
        session_id: `relay-session-${String(((g * 47 + i * 19 + 31) % 420) + 1).padStart(4, "0")}`,
        user_id: customerAt(g * 5 + i).id,
        anonymous_id: `browser-${sha(customerAt(g * 5 + i).email).slice(0, 10)}`,
        sdk_version: "1.17.5",
        created_at: minutesAgo(45 + g * 77 + i * (1100 + g * 17)),
      });
    }
    await prisma.errorOccurrence.createMany({ data: occurrences });
  }
}

async function seedOperations() {
  const yearMonth = now.toISOString().slice(0, 7);
  await prisma.usageMonthly.create({
    data: { id: uuid("usage", 0), project_id: ids.project, year_month: yearMonth, ingest_units: 68420 },
  });

  await prisma.apiKey.createMany({
    data: [
      {
        id: uuid("key", 0), project_id: ids.project, name: "Production web",
        public_id: "relayprod01", secret_hash: sha("relayprod01:disabled-demo-secret"),
        created_at: daysAgo(120), last_used_at: minutesAgo(4), allowed_app: "relay-web",
      },
      {
        id: uuid("key", 1), project_id: ids.project, name: "Backend services",
        public_id: "relayapi001", secret_hash: sha("relayapi001:disabled-demo-secret"),
        created_at: daysAgo(110), last_used_at: minutesAgo(2), allowed_app: "relay-api",
      },
      {
        id: uuid("key", 2), project_id: ids.project, name: "Retired staging key",
        public_id: "relaystage1", secret_hash: sha("relaystage1:disabled-demo-secret"),
        created_at: daysAgo(90), revoked_at: daysAgo(14), allowed_app: "relay-web",
      },
    ],
  });

  await prisma.alertRule.createMany({
    data: [
      {
        id: uuid("rule", 0), project_id: ids.project, name: "Production error burst", enabled: true,
        conditions: [{ type: "ERROR_COUNT", threshold: 12, windowMinutes: 15, environment: "production" }],
        destination_ids: ["project-email"], cooldown_minutes: 20, last_fired_at: minutesAgo(95),
      },
      {
        id: uuid("rule", 1), project_id: ids.project, name: "Traffic heartbeat", enabled: true,
        conditions: [{ type: "HEARTBEAT", windowMinutes: 30 }], destination_ids: ["project-email"], cooldown_minutes: 30,
      },
      {
        id: uuid("rule", 2), project_id: ids.project, name: "High affected-user count", enabled: true,
        conditions: [{ type: "AFFECTED_USERS", threshold: 12, windowMinutes: 60, environment: "production" }],
        destination_ids: ["project-email"], cooldown_minutes: 60, last_fired_at: daysAgo(1, 20),
      },
      {
        id: uuid("rule", 3), project_id: ids.project, name: "Staging noise monitor", enabled: false,
        conditions: [{ type: "ERROR_COUNT", threshold: 8, windowMinutes: 30, environment: "staging" }],
        destination_ids: ["project-email"], cooldown_minutes: 30,
      },
    ],
  });

  await prisma.alertEvent.createMany({
    data: [
      {
        id: uuid("alert", 0), project_id: ids.project, rule: "ERROR_SPIKE",
        title: "Carrier rate latency increased", body: "Carrier rate failures crossed 12 occurrences during the release ramp.",
        href: `/dashboard/errors/${uuid("error-group", 0)}`, dedupe_key: "demo:error-spike:latest", fired_at: minutesAgo(95),
      },
      {
        id: uuid("alert", 1), project_id: ids.project, rule: "ALERT_RULE",
        title: "Affected users threshold reached", body: "12 operators saw delayed checkpoint updates in the last hour.",
        href: `/dashboard/errors/${uuid("error-group", 3)}`, dedupe_key: "demo:affected-users:latest", fired_at: daysAgo(1, 20),
      },
      {
        id: uuid("alert", 2), project_id: ids.project, rule: "QUOTA_NEAR",
        title: "Monthly ingest at 68%", body: "Relay Console is tracking slightly above its monthly telemetry budget.",
        href: "/dashboard/settings/billing", dedupe_key: "demo:quota:latest", fired_at: daysAgo(3, 45),
      },
    ],
  });

  const auditRows = [
    [ids.owner, "owner@northstar-relay.test", "organization.created", "Northstar Relay", 350],
    [ids.owner, "owner@northstar-relay.test", "project.created", "Relay Console", 350],
    [ids.owner, "owner@northstar-relay.test", "member.invited", "maya@northstar-relay.test", 220],
    [ids.editor, "maya@northstar-relay.test", "api_key.created", "Production web", 120],
    [ids.owner, "owner@northstar-relay.test", "project.created", "Relay Mobile", 95],
    [ids.editor, "maya@northstar-relay.test", "alert_rule.created", "Production error burst", 42],
    [ids.owner, "owner@northstar-relay.test", "api_key.revoked", "Retired staging key", 14],
    [ids.editor, "maya@northstar-relay.test", "project.settings.updated", "PII scrub deny list", 5],
  ];
  await prisma.organizationAuditEvent.createMany({
    data: auditRows.map(([actor_user_id, actor_email, action, target, days], index) => ({
      id: uuid("audit", index), organization_id: ids.org, actor_user_id, actor_email, action, target,
      created_at: daysAgo(days, index * 13),
    })),
  });

  const sourceMap = JSON.stringify({ version: 3, file: "relay-web.min.js", sources: ["src/app.tsx"], names: [], mappings: "AAAA" });
  await prisma.sourceMapArtifact.create({
    data: {
      id: uuid("source-map", 0), project_id: ids.project, app: "relay-web", release: "2026.08.4",
      bundle_url: "https://assets.northstar-relay.test/relay-web.2026.08.4.min.js", content: sourceMap,
      sha256: sha(sourceMap), size_bytes: Buffer.byteLength(sourceMap), uploaded_at: daysAgo(2),
    },
  });
}

async function main() {
  await seedIdentity();
  await clearDemoRows();
  await seedSessions();
  await seedEvents();
  await seedErrors();
  await seedOperations();

  const [events, sessions, groups, occurrences, rules, alerts] = await Promise.all([
    prisma.event.count({ where: { project_id: ids.project } }),
    prisma.session.count({ where: { project_id: ids.project } }),
    prisma.errorGroup.count({ where: { project_id: ids.project } }),
    prisma.errorOccurrence.count({ where: { error_group: { project_id: ids.project } } }),
    prisma.alertRule.count({ where: { project_id: ids.project } }),
    prisma.alertEvent.count({ where: { project_id: ids.project } }),
  ]);
  console.log(`[droplive] seeded Relay Console: ${events} events, ${sessions} sessions, ${groups} error groups, ${occurrences} occurrences, ${rules} rules, ${alerts} alerts`);
}

main()
  .catch((error) => {
    console.error("[droplive] telemetry seed failed", error);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
