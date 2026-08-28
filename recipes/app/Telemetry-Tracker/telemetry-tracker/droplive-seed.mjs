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

const deviceProfiles = [
  { platform: "web", browser: "Chrome", os: "Windows", country: "US" },
  { platform: "web", browser: "Safari", os: "macOS", country: "GB" },
  { platform: "mobile-web", browser: "Safari", os: "iOS", country: "CA" },
  { platform: "mobile-web", browser: "Chrome", os: "Android", country: "DE" },
  { platform: "web", browser: "Chrome", os: "macOS", country: "NL" },
  { platform: "web", browser: "Firefox", os: "Windows", country: "AU" },
  { platform: "web", browser: "Firefox", os: "Linux", country: "FR" },
  { platform: "web", browser: "Edge", os: "Windows", country: "SG" },
];

function sessionContext(index) {
  const customer = customerAt(index * 7);
  const device = pick(deviceProfiles, index * 5);
  const started = minutesAgo(5 + index * 12 + (index % 7) * 2);
  const duration = 8 + ((index * 17) % 39);
  const app = index % 7 === 0 ? "relay-admin" : "relay-web";
  return {
    index,
    customer,
    device,
    started,
    duration,
    app,
    environment: index % 29 === 0 ? "staging" : "production",
    release: index < 86 ? "2026.08.4" : index < 246 ? "2026.08.3" : "2026.08.2",
    sessionId: `relay-session-${String(index + 1).padStart(4, "0")}`,
  };
}

function eventTime(session, ordinal, total) {
  const ageMinutes = Math.max(1, (now.getTime() - session.started.getTime()) / 60_000);
  const availableMinutes = Math.max(1, Math.min(session.duration - 1, ageMinutes - 1));
  return new Date(session.started.getTime() + ((ordinal + 1) / (total + 1)) * availableMinutes * 60_000);
}

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
  const rows = [];
  for (let i = 0; i < 420; i += 1) {
    const session = sessionContext(i);
    rows.push({
      id: uuid("session", i),
      project_id: ids.project,
      session_id: session.sessionId,
      app: session.app,
      platform: session.device.platform,
      environment: session.environment,
      release: session.release,
      user_id: session.customer.id,
      anonymous_id: `browser-${sha(session.customer.email).slice(0, 10)}`,
      user_email: session.customer.email,
      country: session.device.country,
      device_browser: session.device.browser,
      device_os: session.device.os,
      sdk_version: "1.17.5",
      started_at: session.started,
      ended_at: i < 3 ? null : new Date(session.started.getTime() + session.duration * 60_000),
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
  const rows = [];
  const metrics = ["LCP", "INP", "CLS", "TTFB"];
  let productIndex = 0;
  let pageIndex = 0;
  let requestIndex = 0;
  let vitalIndex = 0;

  for (let i = 0; i < 420; i += 1) {
    const session = sessionContext(i);
    const productCount = 12 + ((i * 7) % 13);
    const pageCount = 2 + (i % 4);
    const requestCount = 4 + ((i * 3) % 5);
    const vitalCount = session.app === "relay-web" ? 2 + (i % 2) : 0;
    const total = productCount + pageCount + requestCount + vitalCount;
    let ordinal = 0;

    for (let j = 0; j < productCount; j += 1) {
      const route = pick(routes, i + j * 5);
      const eventName = j === 0 ? "workspace_opened" : pick(productEvents, i * 3 + j * 5);
      rows.push({
        id: uuid("event", productIndex),
        project_id: ids.project,
        app: session.app,
        platform: session.device.platform,
        environment: session.environment,
        release: session.release,
        name: eventName,
        user_id: session.customer.id,
        session_id: session.sessionId,
        anonymous_id: `browser-${sha(session.customer.email).slice(0, 10)}`,
        sdk_version: "1.17.5",
        properties: {
          route,
          workspace: session.customer.company,
          plan: pick(["growth", "business", "starter"], i + j),
          source: pick(["navigation", "command-palette", "notification"], i * 2 + j),
          shipment_id: `SHP-${20260000 + ((i * 31 + j * 7) % 1840)}`,
          carrier: pick(["DHL", "UPS", "FedEx", "LocalFleet"], i + j * 3),
        },
        created_at: eventTime(session, ordinal++, total),
      });
      productIndex += 1;
    }

    for (let j = 0; j < pageCount; j += 1) {
      const route = pick(routes, i * 3 + j);
      rows.push({
        id: uuid("page", pageIndex),
        project_id: ids.project,
        app: session.app,
        platform: session.device.platform,
        environment: session.environment,
        release: session.release,
        name: "page_view",
        user_id: session.customer.id,
        session_id: session.sessionId,
        anonymous_id: `browser-${sha(session.customer.email).slice(0, 10)}`,
        sdk_version: "1.17.5",
        properties: { name: pick(["Operations", "Shipments", "Routes", "Exceptions", "Reports", "Team settings"], i + j), path: route, url: `https://app.northstar-relay.test${route}` },
        created_at: eventTime(session, ordinal++, total),
      });
      pageIndex += 1;
    }

    for (let j = 0; j < requestCount; j += 1) {
      const route = pick(routes, i + j * 2);
      rows.push({
        id: uuid("request", requestIndex),
        project_id: ids.project,
        app: "relay-api",
        platform: "node",
        environment: session.environment,
        release: session.release,
        name: "$request",
        user_id: session.customer.id,
        session_id: session.sessionId,
        sdk_version: "1.17.5",
        properties: {
          method: (i + j) % 5 === 0 ? "POST" : "GET",
          url: `https://app.northstar-relay.test${route}`,
          path: route,
          duration_ms: 54 + (((i * 29 + j * 47)) % 520),
          status_code: requestIndex % 211 === 0 ? 500 : requestIndex % 97 === 0 ? 429 : requestIndex % 23 === 0 ? 204 : 200,
          region: pick(["iad", "fra", "lhr", "sin"], i + j),
        },
        created_at: eventTime(session, ordinal++, total),
      });
      requestIndex += 1;
    }

    for (let j = 0; j < vitalCount; j += 1) {
      const metric = pick(metrics, i + j);
      const base = metric === "LCP" ? 1550 : metric === "INP" ? 85 : metric === "CLS" ? 0.035 : 310;
      const spread = metric === "LCP" ? (vitalIndex * 41) % 1250 : metric === "INP" ? (vitalIndex * 17) % 260 : metric === "CLS" ? ((vitalIndex * 7) % 14) / 100 : (vitalIndex * 29) % 760;
      rows.push({
        id: uuid("vital", vitalIndex),
        project_id: ids.project,
        app: session.app,
        platform: session.device.platform,
        environment: session.environment,
        release: session.release,
        name: "$web_vital",
        user_id: session.customer.id,
        session_id: session.sessionId,
        sdk_version: "1.17.5",
        properties: { metric, value: base + spread, path: pick(routes, i + j * 3) },
        created_at: eventTime(session, ordinal++, total),
      });
      vitalIndex += 1;
    }
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
    const firstOccurrenceMinutes = 45 + g * 77;
    const lastOccurrenceMinutes = firstOccurrenceMinutes + (count - 1) * (1100 + g * 17);
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
        first_seen: minutesAgo(lastOccurrenceMinutes),
        last_seen: minutesAgo(firstOccurrenceMinutes),
        resolved_at: resolved ? daysAgo(1 + (g % 2), 90) : null,
      },
    });
    const occurrences = [];
    for (let i = 0; i < count; i += 1) {
      const occurrenceMinutes = firstOccurrenceMinutes + i * (1100 + g * 17);
      const sessionIndex = Math.min(419, Math.max(0, Math.floor((occurrenceMinutes - 5) / 12)));
      const linkedSession = sessionContext(sessionIndex);
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
        session_id: linkedSession.sessionId,
        user_id: linkedSession.customer.id,
        anonymous_id: `browser-${sha(linkedSession.customer.email).slice(0, 10)}`,
        sdk_version: "1.17.5",
        created_at: minutesAgo(occurrenceMinutes),
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
