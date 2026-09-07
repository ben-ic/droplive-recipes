# Datasette with WorldFixture

This candidate builds Datasette's SQLite database from the six neutral packs in
WorldFixture 0.2.5, using `business.saas-company:v3`. The Dockerfile pins both
WorldFixture and Datasette by image digest. Python checks each source pack's
size and SHA-256 before it creates the database.

The application serves a fixed snapshot. WorldFixture does not run as a service,
and the application does not connect to worldfixture.com. The snapshot keeps
the source dates, which extend to 2027. It does not apply timeline events.

## Data mapping

The database has 21 data tables and one source table. It includes 161 people,
16 projects, 514 tasks, 648 invoices, 621 payments, 15 support cases,
153 repository issues, 1,517 chat messages, and 3,069 emails.

Source IDs remain unchanged. Nested channel messages and repository issues
become linked tables. Project membership becomes a join table. Other nested
values remain JSON. Money remains integer cents with its source currency.
The adapter checks all declared foreign keys and SQLite integrity.

The source table records the world ID, version, artifact SHA-256, and manifest
SHA-256. The pinned artifact SHA-256 is:

```text
7d732ffd80204dcb4b2dcd0c938791cf5676c707cd570ebd72d9053c8893fe1f
```

The old static SQL file is removed. Its export-run data is not in this
WorldFixture pack set, so the two export-run queries are removed. Six saved
queries cover open work, time entries, unpaid invoices, monthly invoices and
supplier bills, support cases, and recent team messages. Provider configuration,
duplicate unresolved mail, and the empty refunds collection are not imported.

The old `world: business.saas_company.v2` declaration is removed. The new data
is included in the application image, so a session must not claim the old
artifact as its data source.

## Local check

From the recipe repository root:

```sh
docker build --platform linux/amd64 -t droplive-worldfixture-datasette:candidate recipes/app/simonw/datasette
docker run --rm --platform linux/amd64 -p 127.0.0.1:18761:8001 droplive-worldfixture-datasette:candidate
```

Open `http://127.0.0.1:18761/northstar`. No login is required.

To test against an extracted copy of the pinned image's
`/opt/worldfixture/dist/business.saas-company.v3` directory:

```sh
python3 recipes/app/simonw/datasette/seed/check_worldfixture.py /path/to/business.saas-company.v3
```

## Evidence: 2026-09-07

- The final `linux/amd64` image built and served the database.
- Four adapter tests passed: all imported values and saved queries, identical
  output from repeat builds, refusal to overwrite an existing database,
  changed-pack refusal, and broken-link refusal with partial-output removal.
- All six saved queries passed through Datasette's HTTP API. They returned
  472, 509, 27, 25, 15, and 100 rows respectively.
- Browser review reached the database page and ran the open-work query.
- Environment, kind, entrypoint, and BYOK schema checks passed.
- Full repository validation has 57 existing errors in other recipes, compared
  with 58 on the unchanged branch. This change adds no errors. Datasette has
  no recipe validation errors.

## Publication boundary

This is a local candidate. No public version, active session, shared emulator,
or catalogue listing was changed. Import an exact recipe commit as an unlisted
candidate, complete the public launch/browser/teardown gate, and only then
select that exact version for listing. Keep the current listed version available
throughout that check. Local Docker evidence does not pass the public gate.
