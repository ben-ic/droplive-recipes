#!/usr/bin/env bash
set -euo pipefail

world_path=${DROPLIVE_WORLD_PATH:?DROPLIVE_WORLD_PATH is required}
workspace_root=${DROPLIVE_WORKSPACE_ROOT:-/workspace}
workspace="$workspace_root/northstar-relay"
world_json="$world_path/world.json"
software_json="$world_path/packs/software.json"
work_json="$world_path/packs/work.json"
support_json="$world_path/packs/support.json"
timeline_json="$world_path/timeline.json"

jq -e '.id == "business.saas-company" and .version == "v2"' "$world_json" >/dev/null
for required in "$software_json" "$work_json" "$support_json" "$timeline_json"; do
  test -s "$required"
done

rm -rf "$workspace"
mkdir -p "$workspace"/{apps/web-console,config,data,docs,services/exports-service,services/relay-core,scripts,var}

jq -r '
  "# " + .title + "\n\n" +
  .synthetic_notice + "\n\n" +
  "## Active operating stories\n\n" +
  ([.stories[] | "- **" + .title + "** — " + .summary] | join("\n")) + "\n\n" +
  "This disposable workspace contains the current engineering, support, and release context for Northstar Relay."
' "$world_json" > "$workspace/README.md"

jq -r '["repository","language","description"], (.repositories[] | [.name,.language,.description]) | @tsv' \
  "$software_json" > "$workspace/data/repositories.tsv"
jq -r '["repository","number","state","assignee","title","labels"], (.repositories[] as $r | $r.issues[] | [$r.name,(.number|tostring),.state,.assignee,.title,(.labels|join(","))]) | @tsv' \
  "$software_json" > "$workspace/data/issues.tsv"
jq -r '["project","status","target","owner","summary"], (.projects[] | [.name,.status,.target_on,.owner_id,.summary]) | @tsv' \
  "$work_json" > "$workspace/data/projects.tsv"
jq -r '["status","priority","due","assignee","project","title"], (.tasks[] | [.status,.priority,.due_on,.assignee_id,.project_id,.title]) | @tsv' \
  "$work_json" > "$workspace/data/tasks.tsv"
jq -r '["state","priority","owner","customer","title","next action"], (.cases[] | [.state,.priority,.owner_id,.customer_id,.title,.next_action]) | @tsv' \
  "$support_json" > "$workspace/data/support-cases.tsv"
cp "$timeline_json" "$workspace/data/timeline.json"

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

cat > "$workspace/scripts/release-checks" <<'EOF'
#!/usr/bin/env bash
set -u
cd "$(dirname "$0")/.."
printf '\nNorthstar Relay · Release 2.8 gate\n'
printf '%-34s %s\n' '50,000-row scheduled export' 'PASS  92s'
printf '%-34s %s\n' '75,000-row scheduled export' 'PASS  141s'
printf '%-34s %s\n' 'worker lease released on cancel' 'PASS'
printf '%-34s %s\n' 'partial object removed on cancel' 'FAIL  issue 319'
printf '%-34s %s\n' 'audit timestamp label isolated' 'PASS  issue 322'
printf '\nDecision: BLOCKED — cleanup remains the release gate.\n\n'
exit 0
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

cat > "$workspace/scripts/activity" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
printf '\nNorthstar Relay · live world activity\n\n'
touch var/activity.log
tail -n 25 -f var/activity.log
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
