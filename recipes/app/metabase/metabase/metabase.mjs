import { spawn, execFileSync } from 'node:child_process';
import { mkdir, open, readFile, writeFile } from 'node:fs/promises';
import http from 'node:http';
import { setTimeout as delay } from 'node:timers/promises';

const state = '/data/metabase', base = 'http://127.0.0.1:3001';
let java, server, session, stopping = false;
function stop(code) {
  if (stopping) return;
  stopping = true;
  process.exitCode = code;
  server?.close();
  java?.kill('SIGTERM');
  const deadline = setTimeout(() => java?.kill('SIGKILL'), 15000);
  deadline.unref();
}
process.on('SIGTERM', () => stop(0));
process.on('SIGINT', () => stop(0));

async function api(path, body, method = 'POST') {
  const response = await fetch(base + path, {
    method, headers: { 'Content-Type': 'application/json', ...(session ? { 'X-Metabase-Session': session } : {}) },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }), signal: AbortSignal.timeout(60000),
  });
  if (!response.ok) throw new Error(`Metabase ${method} ${path} failed (${response.status})`);
  const text = await response.text();
  if (!text) return null;
  try { return JSON.parse(text); }
  catch { throw new Error(`Metabase ${method} ${path} returned invalid JSON`); }
}

try {
  if (!process.env.METABASE_OWNER_PASSWORD) throw new Error('Missing demo owner password');
  await mkdir(state, { recursive: true, mode: 0o700 });
  const pgEnv = { ...process.env, PGHOST: process.env.POSTGRES_HOST, PGPORT: process.env.POSTGRES_PORT,
    PGUSER: process.env.POSTGRES_USERNAME, PGPASSWORD: process.env.POSTGRES_PASSWORD, PGDATABASE: process.env.POSTGRES_DATABASE };
  const exists = execFileSync('/usr/bin/psql', ['-XAt', '-c', "SELECT EXISTS(SELECT FROM pg_namespace WHERE nspname='northstar')"],
    { env: pgEnv, encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim() === 't';
  if (!exists) execFileSync('/usr/bin/psql', ['-X', '-v', 'ON_ERROR_STOP=1', '-q', '-f', '/opt/droplive/northstar.sql'],
    { env: pgEnv, stdio: ['ignore', 'ignore', 'pipe'] });
  const log = await open(`${state}/startup.log`, 'w', 0o600);
  java = spawn('/opt/java/openjdk/bin/java', ['-Xmx512m', '-Djava.awt.headless=true', '-jar', '/opt/metabase/metabase.jar'], {
    env: { ...process.env, MB_DB_TYPE: 'h2', MB_DB_FILE: `${state}/app`, MB_JETTY_HOST: '127.0.0.1', MB_JETTY_PORT: '3001',
      MB_LOAD_SAMPLE_CONTENT: 'false', MB_ANON_TRACKING_ENABLED: 'false' }, stdio: ['ignore', log.fd, log.fd],
  });
  await log.close();
  java.on('error', () => stop(1));
  java.on('exit', code => { if (!stopping) stop(code || 1); });
  const deadline = Date.now() + 240000;
  let ready = false;
  while (!stopping && Date.now() < deadline) {
    try { ready = (await api('/api/health', undefined, 'GET')).status === 'ok'; } catch {}
    if (ready) break;
    await delay(500);
  }
  if (!ready || stopping) throw new Error('Metabase did not become ready; see private startup.log');
  const properties = await api('/api/session/properties', undefined, 'GET');
  const identity = { email: 'maya@northstar-relay.droplive.test', password: process.env.METABASE_OWNER_PASSWORD };
  if (properties['has-user-setup'] !== true && properties['setup-token']) {
    session = (await api('/api/setup', { token: properties['setup-token'], user: { ...identity, first_name: 'Maya', last_name: 'Chen', site_name: 'Northstar Relay' },
      prefs: { site_name: 'Northstar Relay', site_locale: 'en', allow_tracking: false } })).id;
  } else {
    session = (await api('/api/session', { username: identity.email, password: identity.password })).id;
  }
  if (!session) throw new Error('Metabase did not create an owner session');
  let review;
  try { review = JSON.parse(await readFile(`${state}/review.json`, 'utf8')); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  if (review) {
    await api(`/api/dashboard/${review.dashboard_id}`, undefined, 'GET');
  } else {
    const database = await api('/api/database', { engine: 'postgres', name: 'WorldFixture company',
      details: { host: process.env.POSTGRES_HOST, port: Number(process.env.POSTGRES_PORT), dbname: process.env.POSTGRES_DATABASE,
        user: process.env.POSTGRES_USERNAME, password: process.env.POSTGRES_PASSWORD, ssl: false, 'tunnel-enabled': false,
        'schema-filters-type': 'inclusion', 'schema-filters-patterns': 'northstar' }, is_full_sync: true });
    const queries = JSON.parse(await readFile('/opt/droplive/seed/queries.json', 'utf8')).databases.northstar.queries;
    const collection = await api('/api/collection', { name: 'Northstar Relay', description: 'WorldFixture company reports. Amounts are integer cents, separated by currency.' });
    const cards = [], results = [];
    for (const [name, query] of Object.entries(queries)) {
      const sql = query.sql.replace('from supplier_bills)', 'from supplier_bills) AS monthly')
        .replace(/\b(from|join)\s+([a-z_]+)/gi, (_, operation, table) => `${operation} northstar.${table}`);
      const dataset = { type: 'native', database: database.id, native: { query: sql, 'template-tags': {} } };
      const result = await api('/api/dataset', dataset);
      if (result.status !== 'completed' || !result.data?.rows?.length) throw new Error(`Empty or failed report: ${name}`);
      results.push({ name, rows: result.data.rows.length });
      cards.push(await api('/api/card', { name: query.title, display: 'table', dataset_query: dataset,
        visualization_settings: {}, collection_id: collection.id }));
    }
    const dashboard = await api('/api/dashboard', { name: 'Northstar Relay operations', description: 'Company work, finance, support, and messages from WorldFixture. Source dates are preserved.', collection_id: collection.id });
    await api(`/api/dashboard/${dashboard.id}`, { dashcards: cards.map((card, i) => ({ id: -i-1, card_id: card.id,
      row: Math.floor(i / 2) * 7, col: (i % 2) * 12, size_x: 12, size_y: 7, series: [], parameter_mappings: [], visualization_settings: {} })) }, 'PUT');
    await api('/api/setting/custom-homepage-dashboard', { value: dashboard.id }, 'PUT');
    await api('/api/setting/custom-homepage', { value: true }, 'PUT');
    await writeFile(`${state}/review.json`, JSON.stringify({ database_id: database.id, dashboard_id: dashboard.id, reports: results }), { mode: 0o600 });
  }
  server = http.createServer((request, response) => {
    if (request.url === '/healthz') { response.writeHead(200); response.end('ready'); return; }
    const upstream = http.request({ hostname: '127.0.0.1', port: 3001, path: request.url, method: request.method,
      headers: request.headers }, incoming => { response.writeHead(incoming.statusCode, incoming.headers); incoming.pipe(response); });
    upstream.on('error', () => { if (!response.headersSent) response.writeHead(502); response.end(); });
    request.pipe(upstream);
  });
  server.on('error', () => stop(1));
  server.listen(3000, '0.0.0.0');
  session = undefined;
  console.log('[worldfixture] Metabase company and six reports are ready');
} catch (error) {
  await writeFile(`${state}/failure.log`, error.stack || error.message, { mode: 0o600 });
  console.error(error?.cmd ? '[worldfixture] PostgreSQL company seed failed' : `[worldfixture] ${error.message}`);
  stop(1);
}
