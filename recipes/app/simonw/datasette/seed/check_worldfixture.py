"""Check the adapter against the actual artifact: python3 check_worldfixture.py PATH."""

import hashlib
import json
import shutil
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

from worldfixture import build, load_tables, quoted, scalar


SOURCE = Path(sys.argv.pop(1)).resolve()


class WorldFixtureTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / "source"
        self.source.mkdir()
        shutil.copy(SOURCE / "manifest.json", self.source)
        shutil.copytree(SOURCE / "packs", self.source / "packs")
        self.output = self.root / "northstar.db"

    def test_records_queries_and_repeatability(self):
        build(self.source, self.output)
        manifest, tables = load_tables(self.source)
        with sqlite3.connect(self.output) as db:
            db.row_factory = sqlite3.Row
            for table, expected in tables.items():
                actual = [dict(row) for row in db.execute(f"select * from {quoted(table)}")]
                self.assertEqual(len(actual), len(expected), table)
                # Compare every original value, including cents and JSON content.
                for original, stored in zip(expected, actual):
                    for field, value in original.items():
                        self.assertEqual(stored[field], scalar(value), (table, field))
            self.assertEqual(db.execute("PRAGMA foreign_key_check").fetchall(), [])
            self.assertEqual(db.execute("select artifact_sha256 from worldfixture_source").fetchone()[0], manifest["artifact_sha256"])
            metadata = json.loads(Path(__file__).with_name("metadata.json").read_text())
            for name, query in metadata["databases"]["northstar"]["queries"].items():
                self.assertTrue(db.execute(query["sql"]).fetchall(), name)
        second = self.root / "second.db"
        build(self.source, second)
        self.assertEqual(self.output.read_bytes(), second.read_bytes())

    def test_existing_database_is_unchanged(self):
        self.output.write_bytes(b"existing demo database")
        with self.assertRaises(FileExistsError):
            build(self.source, self.output)
        self.assertEqual(self.output.read_bytes(), b"existing demo database")

    def test_changed_pack_is_refused(self):
        pack = self.source / "packs/work.json"
        pack.write_bytes(pack.read_bytes() + b" ")
        with self.assertRaisesRegex(ValueError, "integrity check failed"):
            build(self.source, self.output)
        self.assertFalse(self.output.exists())

    def test_broken_link_is_refused_and_partial_database_removed(self):
        pack = self.source / "packs/work.json"
        data = json.loads(pack.read_text())
        data["tasks"][0]["assignee_id"] = "missing-person"
        raw = json.dumps(data).encode()
        pack.write_bytes(raw)
        path = self.source / "manifest.json"
        manifest = json.loads(path.read_text())
        manifest["files"]["packs/work.json"] = {"sha256": hashlib.sha256(raw).hexdigest(), "size": len(raw)}
        path.write_text(json.dumps(manifest))
        with self.assertRaisesRegex(ValueError, "broken record links"):
            build(self.source, self.output)
        self.assertFalse(self.output.exists())


if __name__ == "__main__":
    unittest.main()
