# Add realistic sample data

Sample data helps a visitor understand an application immediately. It is
optional. A reliable empty application is better than a fragile seeded one.

## Choose the safest interface

Use this order:

1. The application's public API
2. An official CLI or seed command
3. An official import or export format
4. A stable file archive for a file-based application
5. No seed

Do not write directly to private database tables. Complex applications change
their schemas, triggers, indexes, and encryption rules. An API or official tool
lets the application maintain those rules.

`seed.sh` can be a database seed script when it calls the application's official
seed or import command. It must not replace the application's schema migrations.

## Add `seed.sh`

Put `seed.sh` beside `droplive.yaml`:

```text
recipes/app/example/example/
├── droplive.yaml
├── seed.sh
└── seed-data.json          # optional
```

DropLive runs `seed.sh` after the application health check passes and before the
demo is ready. The script can use `DROPLIVE_APP_URL` to call the application on
its private session address.

Example:

```sh
#!/bin/sh
set -eu

curl --fail --silent --show-error \
  --header 'Content-Type: application/json' \
  --data @seed-data.json \
  "${DROPLIVE_APP_URL:?}/api/import"
```

The script must:

- be safe to run more than once;
- fail when the import fails;
- avoid printing credentials;
- use deterministic data;
- use names and addresses that are clearly fictional;
- finish without background processes;
- work at every commit for which the recipe is proposed.

Use `.invalid` for sample email domains. Do not copy production data.

## File archives

Use an archive only when the application owns a stable file format:

```yaml
seed:
  archive: seed.tar.zst
  target: /app/data
```

Good examples include documents, Markdown files, images, and an official export
archive. A hand-built database file or SQL dump is not a stable interface unless
the upstream project publishes and supports that format.

## Complicated applications

Do not try to model the whole schema in the recipe. Use the application's own
import path. If it has none, open a small upstream change that adds a development
seed command, or leave the application unseeded.

An update is tested with the seed again. If the seed no longer works, the new
candidate needs a seed repair. The existing working recipe remains useful.

## External-service data

Application seeding and emulator seeding are different.

- `seed.sh` creates data owned by the application.
- `seed.archive` plants files in the application filesystem.
- `emulators.<name>.dataset` selects a reviewed external-service dataset.

An application recipe cannot provide external-service identities, tokens,
mailboxes, OAuth users, or vendor fixtures. Those values must stay together in a
reviewed emulator dataset so an identity always matches its token.

Example selection:

```yaml
emulators:
  google:
    capability: google.gmail.v1
    dataset: google.productivity_mailbox.v1
    bindings:
      GMAIL_API_BASE_URL: api_base_url
```

The data is sample data. A demo must never present it as a real mailbox, account,
or vendor response.
