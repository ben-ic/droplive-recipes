#!/bin/sh
set -eu

# Keep the upstream bootstrap as the owner of migrations, the admin account and
# the server process. Run it in the background so the demo-only seed can wait for
# a healthy Django response before it touches the database.
# The edge terminates TLS and forwards to the app. Linkding checks the browser
# Origin on every POST, so give Django the exact per-session public origin before
# its bootstrap reads the environment.
if [ -n "${APP_URL:-}" ]; then
  export LD_CSRF_TRUSTED_ORIGINS="$APP_URL"
fi
/etc/linkding/bootstrap.sh &
app_pid=$!

finish() {
  kill "$app_pid" 2>/dev/null || true
  wait "$app_pid" 2>/dev/null || true
}
trap finish INT TERM EXIT

if [ "${DROPLIVE_DEMO:-}" = "1" ]; then
  ready=0
  attempt=0
  while [ "$attempt" -lt 60 ]; do
    if python -c 'import urllib.request; urllib.request.urlopen("http://127.0.0.1:9090/login/", timeout=1)' >/dev/null 2>&1; then
      ready=1
      break
    fi
    attempt=$((attempt + 1))
    sleep 1
  done

  if [ "$ready" -eq 1 ] && [ ! -f /etc/linkding/data/.droplive-seeded-v1 ]; then
    export DJANGO_SETTINGS_MODULE=bookmarks.settings.prod
    python - <<'PY'
import django
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone

django.setup()

from bookmarks.models import Bookmark, BookmarkBundle, Tag

User = get_user_model()
owner = User.objects.get(username="maya@northstar-relay.droplive.test")
if owner.email != owner.username:
    owner.email = owner.username
    owner.save(update_fields=["email"])
now = timezone.now()

records = [
    ("Northstar release notes", "https://docs.droplive.test/releases/2026-08", "product,release", "The August release includes row-backed emulator profiles and signed promotion manifests.", "Read before the release review.", False, False, True),
    ("Launch readiness checklist", "https://ops.droplive.test/checklists/launch", "operations,checklist", "A practical check for health, credentials, data, and clean teardown.", "Confirm each item in a disposable session.", True, False, True),
    ("Emulator profile policy", "https://docs.droplive.test/platform/emulator-profiles", "engineering,platform", "Profiles are immutable topology contracts. A new fixture means a new profile.", "Keep the digest beside the promotion receipt.", False, False, False),
    ("Signed manifest guide", "https://docs.droplive.test/promotion/manifests", "engineering,release", "Promotion carries application versions, fixtures, worlds, and profile definitions together.", "Use the arrival audit before canary.", False, False, True),
    ("Visitor data boundaries", "https://docs.droplive.test/security/session-data", "security,operations", "All demo-session data services run inside the visitor microVM.", "A host_daemon member is a launch defect.", False, False, True),
    ("Support handoff template", "https://support.droplive.test/templates/handoff", "operations,support", "Capture the app, version, launch facts, useful screen, and next action.", "Link the receipt, never a private token.", True, False, False),
    ("Database backup runbook", "https://ops.droplive.test/runbooks/backup", "operations,reliability", "Backup and restore steps for a tenant database.", "Test restore on a disposable copy.", False, True, False),
    ("Recipe review rubric", "https://recipes.droplive.test/review/rubric", "engineering,recipes", "Review source pin, health path, owner setup, data seed, and safe product action.", "A passing build is not a useful demo by itself.", False, False, True),
    ("OAuth callback matrix", "https://docs.droplive.test/integrations/oauth-callbacks", "engineering,integrations", "Provider endpoints must accept the session callback and the runtime contract must bind both sides.", "Check browser and server access separately.", True, False, False),
    ("Change review notes", "https://notes.droplive.test/2026-08/change-review", "reading,engineering", "Notes from the last topology and recipe review.", "Follow up on the two open questions.", True, False, False),
    ("Inbox Zero demo mailbox", "https://mail.droplive.test/inbox/demo", "product,integrations", "A sample mailbox with invoices, scheduling requests, newsletters, and customer questions.", "Useful for checking OAuth and categorisation flows.", False, False, True),
    ("Grafana dashboard examples", "https://grafana.droplive.test/dashboards/examples", "product,observability", "Example release, customer, and support panels for a small team.", "Prefer a dashboard with a clear decision or action.", False, False, True),
    ("N8N workflow cookbook", "https://automation.droplive.test/workflows/cookbook", "product,automation", "Small workflows for a webhook, a scheduled check, and a notification.", "Run each once and inspect its execution history.", False, False, True),
    ("FreshRSS feed list", "https://reading.droplive.test/feeds/team", "reading,product", "A sample feed list for product, engineering, and operations reading.", "Keep feeds obviously synthetic.", False, False, False),
    ("Incident timeline example", "https://status.droplive.test/incidents/example", "operations,reliability", "A worked example of detection, mitigation, and follow-up.", "Use the timeline format for launch defects.", True, False, True),
    ("Data quality checks", "https://data.droplive.test/checks/demo-data", "data,operations", "Checks for row counts, ownership, timestamps, and safe placeholder domains.", "Do not cite seeded data as customer data.", False, False, True),
    ("Product feedback queue", "https://feedback.droplive.test/queue", "product,support", "A triage view for visitor feedback and recurring friction.", "Tag each item with evidence and owner.", True, False, False),
    ("Team architecture map", "https://docs.droplive.test/platform/architecture", "engineering,platform", "A compact map of control plane, build plane, run plane, and edge.", "Use it when assigning an incident.", False, False, False),
    ("Release owner calendar", "https://calendar.droplive.test/release-owners", "operations,release", "Review slots for release owners, canary windows, and rollback checks.", "Keep the next owner visible.", False, False, True),
    ("Security review questions", "https://security.droplive.test/reviews/questions", "security,checklist", "Questions for OAuth, secret scope, callback URLs, and tenant boundaries.", "Answer with a test receipt.", True, False, False),
    ("Bookmark import notes", "https://docs.droplive.test/linkding/import", "recipes,product", "The demo seed is private to this session and uses non-resolving example domains.", "Try tags, bundles, archive, and unread filters.", False, False, True),
    ("Platform changelog", "https://docs.droplive.test/changelog", "reading,release", "Short entries for the latest platform changes.", "Archive entries after the review.", False, True, False),
    ("Canary decision log", "https://ops.droplive.test/canary/decisions", "operations,release", "Record the evidence used to promote or hold a release.", "Do not approve from build status alone.", True, False, True),
    ("Recipe authoring tips", "https://recipes.droplive.test/guides/authoring", "recipes,engineering", "Use the app's own UI and API to make a demo useful without changing its product behavior.", "Keep adapter code small and idempotent.", False, False, False),
    ("Customer interview prompts", "https://research.droplive.test/interviews/prompts", "research,product", "Prompts for learning which demo screens make the value clear.", "Ask for one concrete next action.", False, False, True),
    ("Reliability scorecard", "https://status.droplive.test/scorecard", "observability,reliability", "A weekly view of launch success, useful-screen completion, and clean teardown.", "Use measured outcomes, not impressions.", False, False, True),
    ("Deployment logs primer", "https://docs.droplive.test/operations/deploy-logs", "operations,engineering", "How to read launch facts, build output, and stage timing in CP.", "Capture the failure stage before retrying.", True, False, False),
    ("World data catalogue", "https://worlds.droplive.test/catalogue", "data,platform", "Published worlds provide shared service data; app adapters still own private records.", "Verify the world pin in the manifest.", False, False, True),
    ("Demo teardown checklist", "https://ops.droplive.test/checklists/teardown", "operations,checklist", "End the session through the public UI and confirm all services are gone.", "A clean end is part of sign-off.", False, False, True),
    ("OIDC troubleshooting", "https://docs.droplive.test/integrations/oidc", "integrations,support", "Compare issuer, client id, redirect URI, and profile binding when OIDC fails.", "Application-not-found is usually a provider registration mismatch.", True, False, False),
    ("Search and tagging guide", "https://docs.droplive.test/linkding/search", "product,reading", "Examples for tag search, unread review, archive, and bundles.", "Try the saved bundles below.", False, False, True),
    ("On-call contact sheet", "https://ops.droplive.test/on-call", "operations,support", "Synthetic on-call roles for a release day.", "Never put private contact data in a public demo.", False, True, False),
    ("Demo evidence standard", "https://docs.droplive.test/review/evidence", "security,checklist", "A sign-off needs a useful screen, a safe action, and a clean end.", "Attach the receipt to the release.", False, False, True),
    ("App data adapter patterns", "https://recipes.droplive.test/guides/data-adapters", "recipes,data", "Patterns for API, CLI, database, and file-based demo seeds.", "Use the smallest reliable adapter.", True, False, False),
    ("Monthly planning board", "https://planning.droplive.test/monthly", "product,operations", "A synthetic board for release, support, and research work.", "Move one card during the demo.", False, False, True),
    ("Visitor success notes", "https://notes.droplive.test/visitor-success", "research,support", "Common signs that a demo gave a visitor enough context to continue.", "Review after a session, not before.", False, False, True),
]

tag_cache = {}
for _, _, tag_text, _, _, _, _, _ in records:
    for name in tag_text.split(","):
        tag_cache[name] = Tag.objects.get_or_create(name=name, owner=owner, defaults={"date_added": now})[0]

for index, (title, url, tag_text, description, notes, unread, archived, shared) in enumerate(records):
    bookmark, created = Bookmark.objects.get_or_create(
        owner=owner,
        url=url,
        defaults={
            "title": title,
            "description": description,
            "notes": notes,
            "unread": unread,
            "is_archived": archived,
            "shared": shared,
            "date_added": now - timedelta(days=index),
            "date_modified": now - timedelta(days=index),
        },
    )
    if created:
        bookmark.tags.set([tag_cache[name] for name in tag_text.split(",")])

bundles = [
    ("Release review", "release OR checklist", "", "", "", 1),
    ("Unread follow-up", "", "", "", "yes", 2),
    ("Product examples", "", "product", "", "", 3),
    ("Operations", "", "operations", "", "", 4),
]
for name, search, any_tags, all_tags, filter_unread, order in bundles:
    BookmarkBundle.objects.get_or_create(
        owner=owner,
        name=name,
        defaults={
            "search": search,
            "any_tags": any_tags,
            "all_tags": all_tags,
            "filter_unread": filter_unread or BookmarkBundle.FILTER_STATE_OFF,
            "filter_shared": BookmarkBundle.FILTER_STATE_OFF,
            "order": order,
        },
    )
PY
    touch /etc/linkding/data/.droplive-seeded-v1
  fi
fi

wait "$app_pid"
