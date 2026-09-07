"""Read every imported value back through the WorldFixture PostgreSQL protocol."""
import json
import os
import subprocess
from pathlib import Path
from worldfixture import load_tables, scalar, quoted

bindings = json.loads(Path('/data/worldfixture/bindings.json').read_text())
environment = dict(os.environ, PGHOST=bindings['POSTGRES_HOST'], PGPORT=str(bindings['POSTGRES_PORT']),
                   PGUSER=bindings['POSTGRES_USERNAME'], PGPASSWORD=bindings['POSTGRES_PASSWORD'], PGDATABASE=bindings['POSTGRES_DATABASE'])


def sql(query):
    return subprocess.check_output(['/usr/bin/psql', '-XAtq', '-v', 'ON_ERROR_STOP=1', '-c', query], env=environment, text=True).strip()


manifest, tables = load_tables(Path('/opt/worldfixture/dist/business.saas-company.v3'))
counts = {}
for name, source in tables.items():
    actual = json.loads(sql(f'SELECT json_agg(t) FROM northstar.{quoted(name)} t'))
    columns = set().union(*(row.keys() for row in source))
    expected = [{column: int(row[column]) if isinstance(row.get(column), bool) else scalar(row.get(column)) for column in columns} for row in source]
    key = lambda row: json.dumps(row, sort_keys=True, ensure_ascii=False)
    assert sorted(actual, key=key) == sorted(expected, key=key), f'Value mismatch: {name}'
    counts[name] = len(actual)
assert sql('SELECT artifact_sha256 FROM northstar.worldfixture_source') == manifest['artifact_sha256']
assert sql("BEGIN; UPDATE northstar.tasks SET status='worldfixture-check' WHERE id=(SELECT id FROM northstar.tasks ORDER BY id LIMIT 1); SELECT count(*) FROM northstar.tasks WHERE status='worldfixture-check'; ROLLBACK;") == '1'
assert sql("SELECT count(*) FROM northstar.tasks WHERE status='worldfixture-check'") == '0'
print(json.dumps({'tables_verified': counts, 'rollback_verified': True}, sort_keys=True))
