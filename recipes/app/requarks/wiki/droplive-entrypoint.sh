#!/bin/sh
set -eu

: "${WIKI_ADMIN_PASSWORD:?DropLive must generate the Wiki.js owner password}"
: "${APP_URL:?DropLive must provide the public Wiki.js URL}"

seed_marker=/wiki/data/.droplive-seeded
bootstrap_port=3001

if [ -f "$seed_marker" ]; then
  exec "$@"
fi

# Keep the setup server private. The public port must not pass its HTTP health
# check until the owner and sample pages are present; otherwise a short
# verification session can end in the middle of a successful first setup.
PORT="$bootstrap_port" "$@" &
wiki_pid=$!

# Wiki.js exposes its setup endpoint only until the first configuration is
# complete. Boot it once, use that endpoint on loopback, then use its normal
# authenticated API to write public pages. No value is copied into the image.
node - "$APP_URL" "maya@northstar-relay.droplive.test" "$WIKI_ADMIN_PASSWORD" "$seed_marker" "$bootstrap_port" <<'NODE'
const [siteUrl, email, password, marker, port] = process.argv.slice(2);
const base = `http://127.0.0.1:${port}`;

async function sleep(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }

async function waitFor(url, attempts = 90) {
  let last;
  for (let i = 0; i < attempts; i += 1) {
    try {
      const response = await fetch(url);
      if (response.ok) return response;
      last = new Error(`${url} returned ${response.status}`);
    } catch (error) {
      last = error;
    }
    await sleep(1000);
  }
  throw last || new Error(`timed out waiting for ${url}`);
}

async function graph(query, variables, token) {
  const response = await fetch(`${base}/graphql`, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      ...(token ? { authorization: `Bearer ${token}` } : {})
    },
    body: JSON.stringify({ query, variables })
  });
  const payload = await response.json();
  if (!response.ok || payload.errors) throw new Error(JSON.stringify(payload));
  return payload.data;
}

async function main() {
  await waitFor(`${base}/`);
  const setup = await fetch(`${base}/finalize`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ adminEmail: email, adminPassword: password, siteUrl, telemetry: false })
  }).then(response => response.json());
  if (!setup.ok) throw new Error(setup.error || "Wiki.js setup failed");

  await waitFor(`${base}/graphql`);
  let token;
  for (let i = 0; i < 30; i += 1) {
    try {
      const data = await graph(
        "mutation Login($username:String!,$password:String!){authentication{login(username:$username,password:$password,strategy:\"local\"){jwt responseResult{succeeded message}}}}",
        { username: email, password }
      );
      token = data.authentication.login.jwt;
      if (token) break;
    } catch (_) {
      // The setup server restarts as the main server after finalization.
    }
    await sleep(1000);
  }
  if (!token) throw new Error("Wiki.js owner login did not become ready");

  const create = "mutation Create($content:String!,$description:String!,$editor:String!,$isPublished:Boolean!,$isPrivate:Boolean!,$locale:String!,$path:String!,$tags:[String]!,$title:String!){pages{create(content:$content,description:$description,editor:$editor,isPublished:$isPublished,isPrivate:$isPrivate,locale:$locale,path:$path,tags:$tags,title:$title){responseResult{succeeded message}}}}";
  const pages = [
    ["home", "Northstar Relay", "# Northstar Relay\\n\\nA small software company that automates large operational data exports.\\n\\n## This week\\n\\n- Lumen Labs needs a reliable large export.\\n- Release 2.8 needs a decision on the timeout fix.\\n- Theo starts while the team manages customer work."],
    ["customers", "Customers", "# Customers\\n\\n## Lumen Labs\\nNorthstar Scale plan. Renewal depends on a reliable export.\\n\\n## Ember Commerce\\nNorthstar Growth plan. Preparing release-readiness feedback.\\n\\n## Fieldnote Studio\\nNorthstar Team plan. Requests a simpler finance export."],
    ["work", "Work in flight", "# Work in flight\\n\\n- **Lumen renewal** — active, load and cancellation tests remain.\\n- **Release 2.8** — at risk until the export timeout decision.\\n- **Theo onboarding** — staging access still needs an owner."],
    ["export-incident", "The export incident", "# The export incident\\n\\nScheduled exports above 50,000 rows time out after two minutes. The team has a proposed fix, but it must pass load and cancellation tests before release."]
  ];
  for (const [path, title, content] of pages) {
    const data = await graph(create, { content, description: title, editor: "markdown", isPublished: true, isPrivate: false, locale: "en", path, tags: ["northstar"], title }, token);
    const result = data.pages.create.responseResult;
    if (!result.succeeded) throw new Error(result.message || `could not create ${path}`);
  }
  await require("fs").promises.writeFile(marker, "seeded\\n");
}

main().catch(error => {
  console.error("DropLive Wiki.js setup failed:", error);
  process.exit(1);
});
NODE

seed_status=$?
if [ "$seed_status" -ne 0 ]; then
  kill "$wiki_pid" 2>/dev/null || true
  wait "$wiki_pid" 2>/dev/null || true
  exit "$seed_status"
fi

kill "$wiki_pid" 2>/dev/null || true
wait "$wiki_pid" 2>/dev/null || true
exec "$@"
