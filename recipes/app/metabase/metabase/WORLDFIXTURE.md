# Metabase with WorldFixture PostgreSQL

WorldFixture 0.2.5 owns the PostgreSQL process and generated connection credentials inside the same guest as Metabase. The recipe imports the pinned world's 21 company tables and one provenance table into a separate `northstar` schema. Metabase uses H2 for its own app settings and accounts, and connects to WorldFixture PostgreSQL for all six company reports.

The company import checks pack hashes, record links, and SQLite integrity before it emits PostgreSQL SQL. The SQL import runs in one transaction with primary and foreign keys. Money stays in integer cents with its currency, and source dates remain unchanged. This is a fixed starting dataset on a live PostgreSQL provider; timeline events are not applied to these tables.

The image pins WorldFixture, the upstream Metabase jar, and a Java 21 runtime. The upstream Metabase image uses Alpine; a pinned glibc Java runtime runs its jar on the WorldFixture Debian filesystem. A scratch stage retains the filesystem without inheriting unrelated exposed ports. Only app port 3000 is exposed.

The pinned CLI's `--only` list does not include PostgreSQL. The launcher uses `loadManifests`, `resolveEnvironment`, and `start` from the pinned runtime to select `postgres.wire.v1` only. No WorldFixture source is changed. This internal API dependency must be checked when the image pin changes.

Startup creates the owner through Metabase's setup API, adds the PostgreSQL database, verifies six native queries, and creates their saved cards and a dashboard. A local proxy opens only after these actions pass. On subsequent starts, native database/schema and saved dashboard state determine what already exists. The wrapper stops Metabase if the provider process stops. Detailed startup logs stay under `/data/metabase` and `/data/worldfixture` with private permissions.

The launch UI supplies username `maya@northstar-relay.droplive.test` and a generated password. No external account is required.

## Local validation

The native arm64 image built. Sign-in reached the populated dashboard and opened the saved open-work report. The six queries returned 472, 509, 27, 25, 15, and 100 rows. `seed/check_postgres.py` read every imported value back through PostgreSQL, checked provenance, and proved a test update was removed by transaction rollback. It uses the private instance bindings without printing them.

The first local runs stopped because the adapter tried to parse an empty successful Metabase API response as JSON. The adapter now accepts an empty success response. These runs also showed why readiness must include dashboard setup, not just Metabase's health response.

A restart check found that Metabase retains a setup token after the owner exists. The adapter now checks `has-user-setup` before choosing setup or login. The corrected restart reached readiness with the saved dashboard, and the all-table data/rollback check passed again.

The local test uses the final app source mounted over a built pinned image. Public development sandbox review, exact-version sign-off, production release, and production browser review remain required.
