#!/usr/bin/env node
import { spawn } from "node:child_process";
import { existsSync, writeFileSync } from "node:fs";

const base = "http://127.0.0.1:5678";
const stateFile = "/home/node/.n8n/.droplive-northstar-seed-v2";
const owner = {
  email: "maya@northstar-relay.droplive.test",
  firstName: "Maya",
  lastName: "Chen",
  password: process.env.N8N_OWNER_PASSWORD,
};

function sleep(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function request(path, options = {}) {
  const response = await fetch(`${base}${path}`, options);
  const text = await response.text();
  let data = {};
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }
  if (!response.ok) throw new Error(`${path}: ${response.status} ${text}`);
  // N8N uses both `{data: ...}` and direct JSON responses across its internal
  // REST endpoints. Keep the transport detail here so every caller sees the
  // payload itself, including an empty list from a new installation.
  const payload =
    data && typeof data === "object" && !Array.isArray(data) && Object.hasOwn(data, "data")
      ? data.data
      : data;
  return { data: payload, cookies: response.headers.getSetCookie?.() ?? [] };
}

function list(payload, path) {
  let candidate = payload;

  // n8n has used several equivalent list envelopes across releases. The
  // request helper removes one `data` envelope, but a fresh install can still
  // return another envelope (for example `{data: {data: []}}`). Follow only
  // known list keys so an unexpected error object is still reported.
  for (let depth = 0; depth < 3; depth += 1) {
    if (Array.isArray(candidate)) return candidate;
    if (!candidate || typeof candidate !== "object") break;

    const keys = ["data", "results", "credentials", "workflows", "items"];
    const next = keys.map((key) => candidate[key]).find((value) => Array.isArray(value));

    if (next !== undefined) return next;

    const nested = keys
      .map((key) => candidate[key])
      .find((value) => value && typeof value === "object");

    if (nested === undefined) break;
    candidate = nested;
  }

  throw new Error(`${path}: expected a list response`);
}

async function waitForN8n() {
  // A first boot runs database migrations before N8N serves its API. The seed
  // is part of the demo contract, so wait for that bounded cold-start path
  // instead of silently giving up after one minute.
  for (let attempt = 0; attempt < 300; attempt += 1) {
    try {
      await request("/healthz");
      return;
    } catch {
      await sleep(1000);
    }
  }
  throw new Error("n8n did not become ready");
}

async function sessionCookie() {
  const settings = await request("/rest/settings");
  if (settings.data?.userManagement?.showSetupOnFirstLoad) {
    await request("/rest/owner/setup", {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify(owner),
    });
  }

  const login = await request("/rest/login", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ emailOrLdapLoginId: owner.email, password: owner.password }),
  });
  return login.cookies.map((cookie) => cookie.split(";", 1)[0]).join("; ");
}

async function seed() {
  if (existsSync(stateFile)) return;
  if (!owner.password) throw new Error("N8N_OWNER_PASSWORD is required");

  const cookie = await sessionCookie();
  const headers = { "content-type": "application/json", cookie };
  const credentials = await request("/rest/credentials", { headers });
  let smtp = list(credentials.data, "/rest/credentials").find(
    (credential) => credential.name === "Northstar Relay SMTP",
  );

  if (!smtp) {
    smtp = (
      await request("/rest/credentials", {
        method: "POST",
        headers,
        body: JSON.stringify({
          name: "Northstar Relay SMTP",
          type: "smtp",
          data: {
            host: process.env.N8N_SEED_SMTP_HOST,
            port: Number(process.env.N8N_SEED_SMTP_PORT),
            secure: false,
            user: "",
            password: "",
          },
        }),
      })
    ).data;
  }

  const workflows = await request("/rest/workflows", { headers });
  const existingWorkflows = list(workflows.data, "/rest/workflows");
  const seededWorkflows = [
    paymentWorkflow(smtp),
    renewalBriefingWorkflow(smtp),
    incidentUpdateWorkflow(smtp),
    incomingPaymentWebhook(smtp),
  ];

  for (const definition of seededWorkflows) {
    if (existingWorkflows.some((workflow) => workflow.name === definition.name)) continue;

    const workflow = (
      await request("/rest/workflows", {
        method: "POST",
        headers,
        body: JSON.stringify(definition),
      })
    ).data;

    if (definition.name === "Incoming payment webhook (integration example)") {
      await request(`/rest/workflows/${workflow.id}/activate`, {
        method: "POST",
        headers,
        body: JSON.stringify({ versionId: workflow.versionId }),
      });
    }
  }

  writeFileSync(stateFile, "seeded\n", { mode: 0o600 });
}

function paymentWorkflow(smtp) {
  const from = `Maya Chen <${process.env.N8N_SEED_SMTP_FROM}>`;
  const slackUrl = `${process.env.N8N_SEED_SLACK_BASE_URL}/api/chat.postMessage`;
  return {
    name: "Lumen payment confirmation",
    nodes: [
      { parameters: {}, id: "payment", name: "Click Execute workflow", type: "n8n-nodes-base.manualTrigger", typeVersion: 1, position: [260, 300] },
      { parameters: { fromEmail: from, toEmail: "priya@lumen-labs.droplive.test", subject: "Payment received for invoice 4471", emailType: "text", message: "Hi Priya,\n\nWe received the 412 USD payment for invoice 4471. The export incident remains separate from billing; Samira will send the tested workaround before 15:00.\n\nMaya" }, id: "email", name: "Send customer confirmation", type: "n8n-nodes-base.emailSend", typeVersion: 2.1, position: [520, 300], credentials: { smtp: { id: smtp.id, name: smtp.name } } },
      { parameters: { method: "POST", url: slackUrl, sendBody: true, contentType: "json", specifyBody: "json", jsonBody: JSON.stringify({ channel: "#lumen-renewal", text: "Invoice 4471 is paid (412 USD). Billing is clear; the export incident remains open." }) }, id: "slack", name: "Notify Lumen renewal", type: "n8n-nodes-base.httpRequest", typeVersion: 4.2, position: [780, 300] },
    ],
    connections: { "Click Execute workflow": { main: [[{ node: "Send customer confirmation", type: "main", index: 0 }]] }, "Send customer confirmation": { main: [[{ node: "Notify Lumen renewal", type: "main", index: 0 }]] } },
    settings: {},
  };
}

function renewalBriefingWorkflow(smtp) {
  const from = `Maya Chen <${process.env.N8N_SEED_SMTP_FROM}>`;
  const slackUrl = `${process.env.N8N_SEED_SLACK_BASE_URL}/api/chat.postMessage`;
  return {
    name: "Lumen renewal briefing",
    nodes: [
      { parameters: {}, id: "briefing-trigger", name: "Click Execute workflow", type: "n8n-nodes-base.manualTrigger", typeVersion: 1, position: [260, 300] },
      { parameters: { fromEmail: from, toEmail: "priya@lumen-labs.droplive.test", subject: "Lumen renewal briefing — week of 26 August", emailType: "text", message: "Hi Priya,\n\nRenewal status is green: invoice 4471 is paid and the customer success review is booked for Thursday. The export incident is still tracked separately with Samira.\n\nMaya" }, id: "briefing-email", name: "Send customer briefing", type: "n8n-nodes-base.emailSend", typeVersion: 2.1, position: [520, 300], credentials: { smtp: { id: smtp.id, name: smtp.name } } },
      { parameters: { method: "POST", url: slackUrl, sendBody: true, contentType: "json", specifyBody: "json", jsonBody: JSON.stringify({ channel: "#lumen-renewal", text: "Weekly renewal briefing sent to Priya. Invoice 4471 is paid; Thursday's customer-success review is confirmed." }) }, id: "briefing-slack", name: "Post renewal briefing", type: "n8n-nodes-base.httpRequest", typeVersion: 4.2, position: [780, 300] },
    ],
    connections: { "Click Execute workflow": { main: [[{ node: "Send customer briefing", type: "main", index: 0 }]] }, "Send customer briefing": { main: [[{ node: "Post renewal briefing", type: "main", index: 0 }]] } },
    settings: {},
  };
}

function incidentUpdateWorkflow(smtp) {
  const from = `Maya Chen <${process.env.N8N_SEED_SMTP_FROM}>`;
  const slackUrl = `${process.env.N8N_SEED_SLACK_BASE_URL}/api/chat.postMessage`;
  return {
    name: "Lumen export incident update",
    nodes: [
      { parameters: {}, id: "incident-trigger", name: "Click Execute workflow", type: "n8n-nodes-base.manualTrigger", typeVersion: 1, position: [260, 300] },
      { parameters: { fromEmail: from, toEmail: "samira@northstar-relay.droplive.test", subject: "Lumen export incident — customer update needed", emailType: "text", message: "Hi Samira,\n\nPlease send the tested export workaround to Priya before 15:00. Billing is clear: invoice 4471 was paid today.\n\nMaya" }, id: "incident-email", name: "Email incident owner", type: "n8n-nodes-base.emailSend", typeVersion: 2.1, position: [520, 300], credentials: { smtp: { id: smtp.id, name: smtp.name } } },
      { parameters: { method: "POST", url: slackUrl, sendBody: true, contentType: "json", specifyBody: "json", jsonBody: JSON.stringify({ channel: "#lumen-renewal", text: "Export incident update: Samira owns the tested workaround and will contact Priya before 15:00." }) }, id: "incident-slack", name: "Post incident update", type: "n8n-nodes-base.httpRequest", typeVersion: 4.2, position: [780, 300] },
    ],
    connections: { "Click Execute workflow": { main: [[{ node: "Email incident owner", type: "main", index: 0 }]] }, "Email incident owner": { main: [[{ node: "Post incident update", type: "main", index: 0 }]] } },
    settings: {},
  };
}

function incomingPaymentWebhook(smtp) {
  const from = `Maya Chen <${process.env.N8N_SEED_SMTP_FROM}>`;
  return {
    name: "Incoming payment webhook (integration example)",
    nodes: [
      { parameters: { httpMethod: "POST", path: "lumen-payment-received", responseMode: "lastNode" }, id: "webhook", name: "Payment received", type: "n8n-nodes-base.webhook", typeVersion: 2, position: [260, 300] },
      { parameters: { fromEmail: from, toEmail: "priya@lumen-labs.droplive.test", subject: "Payment received for invoice 4471", emailType: "text", message: "This workflow is an integration example. A connected payment system sent a POST request to the production webhook URL." }, id: "webhook-email", name: "Send customer confirmation", type: "n8n-nodes-base.emailSend", typeVersion: 2.1, position: [520, 300], credentials: { smtp: { id: smtp.id, name: smtp.name } } },
    ],
    connections: { "Payment received": { main: [[{ node: "Send customer confirmation", type: "main", index: 0 }]] } },
    settings: {},
  };
}

const command = process.argv.slice(2);
const child = spawn(command[0], command.slice(1), { stdio: "inherit" });
child.on("exit", (code) => process.exit(code ?? 1));
for (const signal of ["SIGTERM", "SIGINT"]) process.on(signal, () => child.kill(signal));

waitForN8n().then(seed).then(() => console.error("[droplive] seeded Northstar workflows")).catch((error) => console.error(`[droplive] seed failed: ${error.message}`));
