"""Build Datasette's immutable database from verified WorldFixture packs."""

import hashlib
import json
import sqlite3
import sys
from contextlib import closing
from pathlib import Path


COLLECTIONS = {
    "identity": {"organizations": "organizations", "people": "people"},
    "work": {"projects": "projects", "tasks": "tasks", "time_entries": "time_entries"},
    "finance": {
        "customers": "customers", "suppliers": "suppliers", "invoices": "invoices",
        "bills": "supplier_bills", "payments": "payments", "ledger_entries": "ledger_entries",
    },
    "support": {"cases": "support_cases"},
    "software": {"repositories": "repositories"},
    "communication": {
        "calendars": "calendars", "calendar_events": "calendar_events",
        "channels": "channels", "documents": "documents", "resolved_mail": "email_messages",
    },
}

# These links use the IDs in the source packs. No application IDs are invented.
REFERENCES = {
    "organization_id": "organizations", "person_id": "people", "owner_id": "people",
    "assignee_id": "people", "reporter_id": "people", "contact_id": "people",
    "author_id": "people", "from_id": "people", "project_id": "projects",
    "task_id": "tasks", "customer_id": "customers", "supplier_id": "suppliers",
    "invoice_id": "invoices", "support_case_id": "support_cases",
    "repository_id": "repositories", "channel_id": "channels", "calendar_id": "calendars",
}


def quoted(name):
    return '"' + name.replace('"', '""') + '"'


def scalar(value):
    if isinstance(value, (dict, list)):
        return json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    return value


def load_tables(source):
    manifest = json.loads((source / "manifest.json").read_text())
    if manifest["api_version"] != "worldfixture.world-artifact/v1" or manifest["synthetic"] is not True:
        raise ValueError("expected a synthetic WorldFixture v1 artifact")
    tables = {}
    for pack, collections in COLLECTIONS.items():
        name = f"packs/{pack}.json"
        raw = (source / name).read_bytes()
        pin = manifest["files"][name]
        if len(raw) != pin["size"] or hashlib.sha256(raw).hexdigest() != pin["sha256"]:
            raise ValueError(f"WorldFixture integrity check failed: {name}")
        data = json.loads(raw)
        for collection, table in collections.items():
            tables[table] = data[collection]

    # Nested records become ordinary linked tables that Datasette can browse.
    for parent, nested, child, foreign_key in (
        ("channels", "messages", "chat_messages", "channel_id"),
        ("repositories", "issues", "issues", "repository_id"),
    ):
        tables[child] = [
            {**row, foreign_key: record["id"]}
            for record in tables[parent] for row in record[nested]
        ]
        tables[parent] = [{k: v for k, v in row.items() if k != nested} for row in tables[parent]]
    tables["project_members"] = [
        {"project_id": project["id"], "person_id": person}
        for project in tables["projects"] for person in project["member_ids"]
    ]
    return manifest, tables


def build(source, output):
    manifest, tables = load_tables(source)
    # Refuse to overwrite an existing database, including one used by a demo.
    with output.open("xb"):
        pass
    try:
        with closing(sqlite3.connect(output)) as db, db:
            for table, rows in tables.items():
                if not rows:
                    raise ValueError(f"required collection is empty: {table}")
                columns = sorted({key for row in rows for key in row}, key=lambda key: (key != "id", key))
                definitions = []
                for column in columns:
                    values = [row[column] for row in rows if row.get(column) is not None]
                    kind = "INTEGER" if values and all(isinstance(v, (int, bool)) for v in values) else "TEXT"
                    definition = f"{quoted(column)} {kind}"
                    if column == "id":
                        definition += " PRIMARY KEY NOT NULL"
                    if column in REFERENCES:
                        target = "organizations" if (table, column) == ("repositories", "owner_id") else REFERENCES[column]
                        definition += f" REFERENCES {quoted(target)}(id)"
                    definitions.append(definition)
                if table == "project_members":
                    definitions.append("PRIMARY KEY (project_id, person_id)")
                db.execute(f"CREATE TABLE {quoted(table)} ({', '.join(definitions)})")
                names = ", ".join(map(quoted, columns))
                placeholders = ", ".join("?" for _ in columns)
                db.executemany(
                    f"INSERT INTO {quoted(table)} ({names}) VALUES ({placeholders})",
                    ([scalar(row.get(column)) for column in columns] for row in rows),
                )
            violations = db.execute("PRAGMA foreign_key_check").fetchall()
            if violations:
                raise ValueError(f"WorldFixture has broken record links: {violations[:5]}")
            db.execute("CREATE TABLE worldfixture_source (world_id TEXT, world_version TEXT, artifact_sha256 TEXT, manifest_sha256 TEXT)")
            db.execute("INSERT INTO worldfixture_source VALUES (?, ?, ?, ?)", (
                manifest["world_id"], manifest["world_version"], manifest["artifact_sha256"],
                hashlib.sha256((source / "manifest.json").read_bytes()).hexdigest(),
            ))
            if db.execute("PRAGMA integrity_check").fetchone() != ("ok",):
                raise ValueError("SQLite integrity check failed")
        print(json.dumps({table: len(rows) for table, rows in tables.items()}, sort_keys=True))
    except BaseException:
        output.unlink(missing_ok=True)
        raise


if __name__ == "__main__":
    build(Path(sys.argv[1]), Path(sys.argv[2]))
