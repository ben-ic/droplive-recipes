# Seeding a demo with the shared world

A visitor who launches an app and lands on an empty state, a "create your first
item" prompt, or a setup wizard has been shown nothing. Every listed recipe
should open on a screen that already has believable content in it.

All seeded recipes share one fictional company, **Northstar Relay**, so a visitor
who opens two of them reads one world. The world is the source of record for
people, customers, projects, tasks, issues, support cases, invoices and the
timeline. Read it; do not invent a person, customer, invoice or issue that is not
in it.

## The four pieces

A seeded recipe folder holds exactly these, beside `droplive.yaml`:

| File | What it is |
|---|---|
| `droplive.yaml` | Declares the credential DropLive mints per session, and `run.open` |
| `seed/<name>.<ext>` | One complete request per line, generated from the world |
| `droplive-entrypoint.sh` | Starts the app, waits for readiness, seeds, `wait`s on it |
| `Dockerfile` | `COPY`s both; `ENTRYPOINT` is the script, `CMD` the upstream one |

The Dockerfile wraps the image's own startup rather than replacing it:

```dockerfile
COPY --chmod=0444 seed/kanboard.jsonl /usr/local/lib/droplive-kanboard-seed.jsonl
COPY --chmod=0555 droplive-entrypoint.sh /usr/local/bin/droplive-kanboard
ENTRYPOINT ["/usr/local/bin/droplive-kanboard"]
CMD ["/usr/local/bin/entrypoint.sh"]
```

and the script backgrounds the command it was given:

```sh
"$@" &
server_pid=$!
trap 'kill -TERM "$server_pid" 2>/dev/null || true' TERM INT
seed || echo "[droplive] seed failed; the app is still running" >&2
wait "$server_pid"
```

An app that needs no runtime seeding needs none of this. Datasette's database is
built into the image by one `RUN` and there is no entrypoint at all.

## One complete request per line

The seed file is generated from the world at authoring time and never assembled
at runtime, so the shell never quotes or escapes anything. Two shapes are in use:

- **One JSON-RPC body per line**, when every call goes to one endpoint. The
  binding name for whatever the call returns rides in the JSON-RPC `id`
  (`recipes/app/kanboard/kanboard/seed/kanboard.jsonl`).
- **`<METHOD> <PATH> <BIND> <BODY>`**, when calls go to different endpoints with
  different verbs. The runtime splits on the first three spaces and the body is
  the rest of the line
  (`recipes/app/metabase/metabase/seed/metabase.requests`).

Identifiers the application assigns are written as placeholders — `"@user:lucas@"`
— and substituted from a `sed` script the runtime appends to as each call
returns. Write two rules per binding: the quoted one first so a binding used as a
JSON value becomes a number, then the bare one so the same name works inside a
request path.

Reading a top-level `id` out of a response needs more than `sed`. Applications
answer with nested objects that carry `id` fields of their own — the creator, the
collection, the result metadata — so matching the first or the last `"id":` in
the text returns somebody else's number. `json_id()` in the Metabase and Kimai
entrypoints walks the response and keeps only what is at depth one; copy it.

## Rules that have earned their place

**Prefer the official API, CLI, or import format.** Use a database seed only when
the app has no stable supported import path, and say in the commit message which
you used and why.

**Probe the real image before writing anything.** `docker run` the pinned digest
and hit its API by hand. Half the apps disagree with their own docs, and several
disagree with themselves:

- Kanboard's *user* API forces `creator_id` and refuses any comment not authored
  by the calling user, so a ten-person company arrives signed by one person. Its
  *application* API has no user session and does not.
- Kanboard names a project's owner but does not put them in its member list, and
  then refuses to assign a card to a non-member. Add every member, owner
  included.
- Metabase reports "did not produce a ResultSet" for a statement that returns no
  rows, even though the database ran it. Open a DDL batch with `SELECT 1 AS ok;`
  and end an insert with `RETURNING`, and a real failure still looks like one.
- Metabase requires a digit in a password. Declare that with `pattern`, which is
  a rejection sampler, not a one-shot check.
- Kimai refuses a timesheet outside its project's own dates. That is the app
  enforcing the world, not something to work around.

**Check what tools the image actually has.** Memos has only BusyBox `wget`, which
speaks GET and POST — enough, and the reason no memo is pinned, because pinning
is a PATCH. Metabase is a JRE and a jar with no database client at all, which is
why its tables are built through its own SQL editor. Do not install packages.

**Retire a shipped default credential.** Kanboard ships `admin`/`admin` and prints
nothing about it. Create the owner DropLive minted, then disable the shipped
account — and do that on every start, not only after a fresh seed, so an
interrupted seed can never leave a published default live on a demo.

**Answer the first-run wizard.** Kimai opens on one until somebody does. It is a
setup screen where the demo should have been.

**Deterministic and idempotent.** Key idempotency on a fact the app itself owns
and that can only happen once: Memos' first-user call, Metabase's setup token,
Kanboard's and Kimai's own record of the first thing the seed creates. Re-running
the entrypoint must not double the data.

**Never fail the app because seeding failed.** Log and carry on. A demo with no
data beats a demo that will not boot.

**Watch for content the app parses.** Memos turned `#318` into a tag and polluted
the tag sidebar. Kanboard turns `#123` into a task link. Write "issue 318".

**Look at what you wrote.** Open it in a browser. If the first screen is not
obviously a working company's app, it is not done.

## Dates

Everything a fresh seed creates is stamped "now", and applications show it: a
card created after it was started, a comment reading "a few seconds ago", a board
where every card is "<15m" old. Where the API can express a date, pass one. Where
it cannot, and only where it cannot, write the date columns the application owns
on the rows its own API just created — see `droplive.task_dates` in the Kanboard
entrypoint — and say so in the commit message.

Use the world's own absolute dates. They are internally consistent with every
other Northstar demo.

## What may be generated

The world fixes the last few days of a company's life, not its history. A time
tracker showing three days of one person's week, or a BI tool with four rows,
shows nothing. Background volume may be generated when:

- it is the kind of record the world implies but does not enumerate — export
  runs, routine timesheets;
- it matches every number the world does fix. Metabase's export runs reproduce
  48,000 rows in 1m34s and 52,184 rows at the two-minute worker limit exactly,
  because those are the numbers the support case quotes;
- it is deterministic, from a fixed seed, so the committed file is reproducible;
- the same generated facts are reused across apps, so two demos agree.

Say plainly in the commit message which tables are the world's and which are not.

## Verify before you commit

1. `docker build` the recipe folder and run it with the env the recipe declares.
2. Read the data back through the app's own API. Confirm counts and content.
3. Restart the container and confirm the data did not double.
4. Sign in with the minted credential and confirm the shipped default no longer
   works.
5. Open it in a browser and look at the first screen.
6. `python3 tools/lint_recipes.py` must be clean.
