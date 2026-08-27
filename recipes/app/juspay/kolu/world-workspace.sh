#!/usr/bin/env bash
set -euo pipefail

workspace_root=${DROPLIVE_WORKSPACE_ROOT:-/workspace}
workspace="$workspace_root/northstar-relay"

cd "$workspace_root"
rm -rf "$workspace"
mkdir -p "$workspace"/{apps/web-console/public,config,data,docs,services/exports-service,services/relay-core,scripts,var}

cat > "$workspace/README.md" <<'EOF'
# Northstar Relay

This is a synthetic, disposable engineering workspace for a 16-person B2B data-export company. It contains linked release, product, engineering, and support work. No production source, customer data, or credentials are present.

## Active operating stories

- **Release 2.8 readiness** — Large scheduled exports now complete, but cancellation cleanup still blocks release.
- **Lumen Labs escalation** — Support has a safe manual-retry workaround while engineering tests issue 318.
- **Audit clarity** — Issue 322 isolates customer-time-zone labels from the export fix.
- **On-call reliability** — Queue telemetry and runbooks are being updated before the next rotation.
EOF

cat > "$workspace/data/repositories.tsv" <<'EOF'
repository	language	description
relay-core	TypeScript	Export scheduling, worker leases, and audit events
web-console	TypeScript	Customer administration and audit-log interface
delivery-ops	Shell	Release checks, incident runbooks, and deployment automation
EOF

cat > "$workspace/data/issues.tsv" <<'EOF'
repository	number	state	assignee	title	labels
relay-core	318	in-progress	Jon Bell	Scheduled export uses legacy 120-second timeout	bug,release-2.8
relay-core	319	open	Noor Alvarez	Remove partial object when an export is cancelled	bug,release-blocker
relay-core	325	review	Elena Petrov	Expose worker lease age in queue telemetry	observability
web-console	322	in-progress	Hana Ito	Show audit timestamps in the account time zone	ux,audit
web-console	327	open	Lucas Meyer	Preserve export filters in shared links	enhancement
delivery-ops	88	review	Samira Okafor	Add cancellation fixture to the release gate	testing,release-2.8
EOF

cat > "$workspace/data/projects.tsv" <<'EOF'
project	status	target	owner	summary
Release 2.8	at-risk	2026-09-03	Maya Chen	Ship export reliability and audit improvements after cleanup passes
Export reliability	active	2026-08-31	Jon Bell	Remove timeouts and partial objects from large scheduled exports
Audit clarity	active	2026-09-02	Hana Ito	Make audit timestamps and filters clear for global teams
On-call hardening	planned	2026-09-10	Samira Okafor	Improve queue telemetry, alerts, and incident runbooks
EOF

cat > "$workspace/data/tasks.tsv" <<'EOF'
status	priority	due	assignee	project	title
done	high	2026-08-25	Jon Bell	Export reliability	Raise scheduled export timeout to the account limit
done	high	2026-08-26	Noor Alvarez	Export reliability	Verify the 50,000-row load case
done	high	2026-08-26	Noor Alvarez	Export reliability	Verify the 75,000-row load case
in-progress	urgent	2026-08-28	Noor Alvarez	Export reliability	Delete partial objects after cancellation
review	high	2026-08-28	Elena Petrov	Export reliability	Publish worker lease-age telemetry
blocked	high	2026-08-29	Maya Chen	Release 2.8	Approve the Release 2.8 go or no-go decision
in-progress	medium	2026-08-29	Hana Ito	Audit clarity	Render audit timestamps in the account time zone
review	medium	2026-08-30	Lucas Meyer	Audit clarity	Retain filters in shared audit links
todo	medium	2026-09-01	Hana Ito	Audit clarity	Update audit-log empty and loading states
in-progress	high	2026-08-28	Samira Okafor	On-call hardening	Add export cancellation to release checks
todo	medium	2026-09-04	Elena Petrov	On-call hardening	Add queue-depth warning thresholds
todo	medium	2026-09-05	Samira Okafor	On-call hardening	Revise the export incident runbook
done	high	2026-08-27	Imani Brooks	Release 2.8	Draft the Lumen manual-retry workaround
todo	medium	2026-09-02	Theo Martin	Release 2.8	Prepare conditional customer release notes
EOF

cat > "$workspace/data/support-cases.tsv" <<'EOF'
state	priority	owner	customer	title	next action
engineering	high	Imani Brooks	Lumen Labs	Scheduled export stops at two minutes	Send the manual-retry steps, then update after cancellation testing
waiting-on-customer	medium	Theo Martin	Harbor Mobility	Audit timestamps differ from the finance report	Confirm the account time zone and attach the issue 322 preview
EOF

cat > "$workspace/docs/release-2.8.md" <<'EOF'
# Release 2.8 readiness

Status: **AT RISK**

The audit improvements are ready. The scheduled-export timeout fix completed the 50k and 75k load cases. Cancellation releases the worker lease, but the partial export object remains. Do not merge or promise Release 2.8 until cleanup is verified.

## Decision record

- Keep the release notes conditional.
- Keep issue 322 separate from the export branch.
- Use manual retry as the safe Lumen workaround.
- Do not state a release date in the customer reply.
EOF

cat > "$workspace/docs/lumen-support.md" <<'EOF'
# Lumen Labs export case

Customer contact: Priya Raman
Case: Scheduled export stops at two minutes
Priority: High
State: Engineering

The scheduled 52,184-row export uses the legacy 120-second worker timeout. Manual retry uses the account limit and is the current safe workaround. Send the workaround before 15:00 and give the next update after the cancellation test.
EOF

cat > "$workspace/config/export-worker.conf" <<'EOF'
# Issue 318 branch: scheduled jobs must use the account limit.
scheduled_timeout_seconds=360
manual_timeout_seconds=360
cleanup_partial_object_on_cancel=false
EOF

cat > "$workspace/services/relay-core/worker.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
config=${1:-../../config/export-worker.conf}
scheduled=$(sed -n 's/^scheduled_timeout_seconds=//p' "$config")
printf 'scheduled worker timeout: %ss\n' "$scheduled"
test "$scheduled" -ge 300
EOF

cat > "$workspace/services/exports-service/cancel-fixture.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
config=${1:-../../config/export-worker.conf}
cleanup=$(sed -n 's/^cleanup_partial_object_on_cancel=//p' "$config")
printf 'worker lease released: yes\npartial object removed: %s\n' "$cleanup"
test "$cleanup" = true
EOF

cat > "$workspace/apps/web-console/audit-timezone.ts" <<'EOF'
export function auditTimestampLabel(value: Date, zone: string): string {
  return `${value.toLocaleString("en-US", { timeZone: zone })} ${zone}`;
}
EOF

cat > "$workspace/apps/web-console/public/index.html" <<'EOF'
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<title>Northstar Relay development console</title>
<h1>Northstar Relay</h1>
<p>Release 2.8 development console</p>
<ul>
  <li>Scheduled export timeout: fixed</li>
  <li>Cancellation cleanup: under test</li>
  <li>Audit time-zone labels: isolated</li>
</ul>
EOF
printf '%s\n' 'northstar-web-console: ready' > "$workspace/apps/web-console/public/health.txt"

cat > "$workspace/scripts/release-checks" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
cd "$(dirname "$0")/.."
printf '\nNorthstar Relay · Release 2.8 gate\n'
failed=0
if services/relay-core/worker.sh config/export-worker.conf >/dev/null; then
  printf '%-38s %s\n' 'scheduled worker timeout' 'PASS  360s'
else
  printf '%-38s %s\n' 'scheduled worker timeout' 'FAIL  issue 318'
  failed=1
fi
printf '%-38s %s\n' '50,000-row scheduled export' 'PASS  92s'
printf '%-38s %s\n' '75,000-row scheduled export' 'PASS  141s'
if services/exports-service/cancel-fixture.sh config/export-worker.conf >/dev/null; then
  printf '%-38s %s\n' 'partial object removed on cancel' 'PASS'
else
  printf '%-38s %s\n' 'partial object removed on cancel' 'FAIL  issue 319'
  failed=1
fi
printf '%-38s %s\n' 'audit timestamp label isolated' 'PASS  issue 322'
if (( failed == 0 )); then
  printf '\nDecision: READY — all local release checks pass.\n\n'
else
  printf '\nDecision: BLOCKED — cleanup remains the release gate.\n\n'
fi
exit "$failed"
EOF

cat > "$workspace/scripts/briefing" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
printf '\nNorthstar Relay · operating brief\n\n'
column -t -s $'\t' data/projects.tsv 2>/dev/null || sed 's/\t/  /g' data/projects.tsv
printf '\nOpen engineering issues\n\n'
column -t -s $'\t' data/issues.tsv 2>/dev/null || sed 's/\t/  /g' data/issues.tsv
printf '\nSupport queue\n\n'
column -t -s $'\t' data/support-cases.tsv 2>/dev/null || sed 's/\t/  /g' data/support-cases.tsv
EOF

cat > "$workspace/scripts/watch-tests" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
watched=config/export-worker.conf
last=$(stat -c %Y "$watched")
printf '\nNorthstar Relay · file watcher\nWatching %s and rerunning the release gate.\n' "$watched"
scripts/release-checks || true
while sleep 2; do
  current=$(stat -c %Y "$watched")
  if [[ "$current" != "$last" ]]; then
    printf '\n[watch] %s changed; rerunning checks\n' "$watched"
    scripts/release-checks || true
    last=$current
  fi
done
EOF

cat > "$workspace/scripts/dev-server" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
busybox httpd -f -p 4173 -h apps/web-console/public &
http_pid=$!
cleanup() {
  kill "$http_pid" 2>/dev/null || true
  wait "$http_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM
printf '\nNorthstar Relay · web-console development server\n'
printf '[dev] serving guest files on http://127.0.0.1:4173\n'
while kill -0 "$http_pid" 2>/dev/null; do
  code=$(curl --silent --output /dev/null --write-out '%{http_code}' http://127.0.0.1:4173/health.txt || true)
  printf '[dev] GET /health.txt -> %s · source apps/web-console/public\n' "$code"
  sleep 7
done
wait "$http_pid"
EOF

cat > "$workspace/scripts/export-worker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
printf '\nNorthstar Relay · issue 319 worker\n'
printf '[worker] reproducing cancellation cleanup against guest fixture\n'
if services/exports-service/cancel-fixture.sh config/export-worker.conf; then
  printf '[worker] fixture unexpectedly passed; no edit required\n'
else
  printf '[worker] confirmed partial object remains; preparing local fix\n'
fi
sleep 12
sed 's/cleanup_partial_object_on_cancel=false/cleanup_partial_object_on_cancel=true/' \
  config/export-worker.conf > config/export-worker.conf.next
mv config/export-worker.conf.next config/export-worker.conf
printf '[worker] changed config/export-worker.conf in this disposable guest\n'
services/exports-service/cancel-fixture.sh config/export-worker.conf
scripts/release-checks
printf '[worker] work complete; the shell remains open for inspection\n'
EOF

chmod +x "$workspace"/scripts/* "$workspace"/services/*/*.sh

cd "$workspace"
git init -q -b main
git config user.name "Northstar Relay"
git config user.email "engineering@northstar-relay.test"
git add .
git commit -q -m "Build Release 2.8 operating workspace"
git switch -q -c fix/scheduled-export-timeout
sed 's/scheduled_timeout_seconds=360/scheduled_timeout_seconds=120/' config/export-worker.conf > config/export-worker.conf.next
mv config/export-worker.conf.next config/export-worker.conf
git commit -qam "Reproduce scheduled export timeout"
sed 's/scheduled_timeout_seconds=120/scheduled_timeout_seconds=360/' config/export-worker.conf > config/export-worker.conf.next
mv config/export-worker.conf.next config/export-worker.conf
cat > var/activity.log <<'EOF'
[workspace] 16 people · 4 projects · 14 tasks · 3 repositories · 2 support cases
[workspace] Release 2.8 is at risk; cancellation cleanup is the active gate.
EOF
