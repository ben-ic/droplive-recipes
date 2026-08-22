#!/usr/bin/env node
"use strict";

const { io } = require("/app/node_modules/socket.io-client");

const password = process.env.DROPLIVE_ADMIN_PASSWORD;
const wanted = [
  ["Northstar customer portal", process.env.DROPLIVE_STABLE_URL],
  ["Northstar billing incident", process.env.DROPLIVE_FAILING_URL],
  ["Northstar worker fleet", process.env.DROPLIVE_FLAPPING_URL],
];

function call(socket, event, ...args) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`${event} timed out`)), 10000);
    socket.emit(event, ...args, (response) => {
      clearTimeout(timer);
      if (!response || response.ok !== true) return reject(new Error(response?.msg || `${event} failed`));
      resolve(response);
    });
  });
}

function valueCall(socket, event) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`${event} timed out`)), 10000);
    socket.emit(event, (response) => {
      clearTimeout(timer);
      resolve(response);
    });
  });
}

function monitor(name, url) {
  return {
    type: "http", name, description: "Synthetic Northstar service from the shared DropLive world",
    parent: null, url, method: "GET", interval: 20, retryInterval: 20,
    resendInterval: 0, maxretries: 0, retryOnlyOnStatusCodeFailure: false,
    notificationIDList: {}, ignoreTls: false, upsideDown: false,
    expiryNotification: false, domainExpiryNotification: false, maxredirects: 10,
    accepted_statuscodes: ["200-299"], saveResponse: true, saveErrorResponse: true,
    responseMaxLength: 1024, dns_resolve_type: "A", dns_resolve_server: "",
    docker_container: "", docker_host: null, proxyId: null, basic_auth_user: "",
    basic_auth_pass: "", bearer_token: "", authMethod: null, oauth_auth_method: "client_secret_basic",
    httpBodyEncoding: "json", kafkaProducerBrokers: [], kafkaProducerSaslOptions: { mechanism: "None" },
    kafkaProducerSsl: false, kafkaProducerAllowAutoTopicCreation: false,
    rabbitmqNodes: [], rabbitmqUsername: "", rabbitmqPassword: "", conditions: [],
    active: true,
  };
}

async function main() {
  const deadline = Date.now() + 60000;
  let socket;
  while (Date.now() < deadline) {
    try {
      socket = io("http://127.0.0.1:3001", {
        transports: ["websocket"], reconnection: false, timeout: 3000, autoConnect: false,
      });
      await new Promise((resolve, reject) => {
        socket.once("connect", resolve);
        socket.once("connect_error", reject);
        socket.connect();
      });
      break;
    } catch (_) {
      socket?.close();
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
  }
  if (!socket?.connected) throw new Error("Uptime Kuma did not become ready for setup");

  // The server starts accepting WebSockets just before every socket handler is
  // attached. Give that startup edge time to close, and bound the query so a
  // missing acknowledgement fails the launch instead of hanging it.
  await new Promise((resolve) => setTimeout(resolve, 500));
  const needsSetup = await valueCall(socket, "needSetup");
  if (needsSetup) await call(socket, "setup", "maya", password);
  await call(socket, "login", { username: "maya", password, token: "" });

  const existing = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error("monitor list timed out")), 10000);
    socket.once("monitorList", (list) => { clearTimeout(timer); resolve(list || {}); });
    call(socket, "getMonitorList").catch(reject);
  });
  const names = new Set(Object.values(existing).map((item) => item.name));
  for (const [name, url] of wanted) {
    if (!names.has(name)) await call(socket, "add", monitor(name, url));
  }
  socket.close();
}

main().catch((error) => {
  console.error(`Uptime Kuma setup failed: ${error.message}`);
  process.exit(1);
});
