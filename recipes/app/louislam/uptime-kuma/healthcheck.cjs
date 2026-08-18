#!/usr/bin/env node
"use strict";

// `/` is an intentional redirect after setup. `/dashboard` remains a public
// SPA shell with a deterministic 200 before and after owner creation.
const expected = "http://127.0.0.1:3001/dashboard";
if (process.argv[2] !== expected) {
  console.error("healthcheck URL must remain the pinned internal Uptime Kuma endpoint");
  process.exit(64);
}

const http = require("node:http");
const request = http.get(expected, { timeout: 4000 }, (response) => {
  let body = "";
  response.setEncoding("utf8");
  response.on("data", (chunk) => {
    if (body.length < 65536) body += chunk;
  });
  response.on("end", () => {
    process.exit(response.statusCode === 200 && body.includes("Uptime Kuma") ? 0 : 1);
  });
});

request.on("timeout", () => request.destroy(new Error("healthcheck timed out")));
request.on("error", () => process.exit(1));
