"""Convert the verified company snapshot to PostgreSQL input for a new guest."""
import sqlite3
import sys
import tempfile
from pathlib import Path
from worldfixture import build, quoted


def literal(value):
    if value is None:
        return "NULL"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def export(source, output):
    with tempfile.TemporaryDirectory() as scratch:
        database = Path(scratch) / "source.db"
        build(source, database)
        with sqlite3.connect(database) as db:
            tables = [r[0] for r in db.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
            statements = ["BEGIN;", "SET standard_conforming_strings=on;", "CREATE SCHEMA northstar;", "SET search_path=northstar,public;"]
            for table in tables:
                columns = list(db.execute(f"PRAGMA table_info({quoted(table)})"))
                definitions = [f"{quoted(c[1])} {'BIGINT' if c[2] == 'INTEGER' else 'TEXT'}" for c in columns]
                keys = [quoted(c[1]) for c in sorted(columns, key=lambda c: c[5]) if c[5]]
                if keys:
                    definitions.append(f"PRIMARY KEY ({','.join(keys)})")
                statements.append(f"CREATE TABLE {quoted(table)} ({','.join(definitions)});")
            for table in tables:
                rows = list(db.execute(f"SELECT * FROM {quoted(table)}"))
                if rows:
                    values = ',\n'.join('(' + ','.join(map(literal, row)) + ')' for row in rows)
                    statements.append(f"INSERT INTO {quoted(table)} VALUES {values};")
            for table in tables:
                for fk in db.execute(f"PRAGMA foreign_key_list({quoted(table)})"):
                    statements.append(f"ALTER TABLE {quoted(table)} ADD FOREIGN KEY ({quoted(fk[3])}) REFERENCES {quoted(fk[2])} ({quoted(fk[4])});")
            statements.append("COMMIT;")
            output.write_text('\n'.join(statements) + '\n')


if __name__ == '__main__':
    export(Path(sys.argv[1]), Path(sys.argv[2]))
