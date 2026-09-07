import { spawn } from 'node:child_process';
import { createInterface } from 'node:readline';
import { mkdir, readFile, writeFile, rm } from 'node:fs/promises';
import { loadManifests } from '/opt/worldfixture/runtime/src/manifests.mjs';
import { resolveEnvironment } from '/opt/worldfixture/runtime/src/resolve.mjs';
import { start } from '/opt/worldfixture/runtime/src/supervisor.mjs';
import { setup } from './app-setup.mjs';

const artifactPath = '/opt/worldfixture/dist/business.saas-company.v3';
const serviceRoot = '/opt/worldfixture/emulators', stateDir = '/data/worldfixture';
let instance, app, stopping = false;
async function stop(code) {
  if (stopping) return;
  stopping = true;
  process.exitCode = code;
  app?.kill('SIGTERM');
  const deadline = setTimeout(() => app?.kill('SIGKILL'), 20000);
  deadline.unref();
  await instance?.stop({ graceMs: 5000 });
  await rm(`${stateDir}/bindings.json`, { force: true });
}
process.on('SIGTERM', () => { console.error('[worldfixture] Received SIGTERM'); void stop(0); });
process.on('SIGINT', () => { console.error('[worldfixture] Received SIGINT'); void stop(0); });
try {
  await mkdir(stateDir, { recursive: true });
  await rm(`${stateDir}/bindings.json`, { force: true });
  const world = JSON.parse(await readFile(`${artifactPath}/world.json`, 'utf8'));
  const lock = resolveEnvironment({
    api_version: 'worldfixture.environment/v1', world: { use: `${world.id}:${world.version}` },
    requires: ['postgres.wire.v1'], execution: { mode: 'selected-capabilities' },
    bindings: Object.fromEntries(Object.entries({ HOST: 'host', PORT: 'port', USERNAME: 'username', PASSWORD: 'password', DATABASE: 'database' })
      .map(([name, binding]) => [`POSTGRES_${name}`, `postgres.wire.v1/${binding}`])),
    target: { kind: 'none', identity: world.people.find(person => person.primary).id },
  }, { manifests: loadManifests(serviceRoot), artifactPath });
  console.log('[worldfixture] Starting PostgreSQL');
  instance = await start(lock, {
    artifactPath, serviceRoot, stateDir, runner: 'process', readyTimeoutMs: 120000,
    onSpawned(starting) {
      for (const record of starting.children) {
        const password = record.launch.environment.POSTGRES_PASSWORD;
        for (const stream of [record.child.stdout, record.child.stderr]) {
          const output = stream === record.child.stderr ? process.stderr : process.stdout;
          createInterface({ input: stream }).on('line', line => {
            const safe = password ? line.replaceAll(password, '[REDACTED]') : line;
            output.write(`[worldfixture postgres] ${safe}\n`);
          });
        }
        record.child.on('exit', (code, signal) => {
          console.error(`[worldfixture] PostgreSQL exited: code=${code} signal=${signal}`);
        });
      }
    },
  });
  console.log('[worldfixture] PostgreSQL is ready');
  if (stopping) { await instance.stop({ graceMs: 5000 }); process.exitCode = 1; }
  else {
    for (const record of instance.children) {
      record.child.on('exit', () => { void stop(1); });
      if (record.exited) throw new Error('WorldFixture PostgreSQL stopped');
    }
    const bindings = instance.bindings();
    await writeFile(`${stateDir}/bindings.json`, JSON.stringify(bindings), { mode: 0o600 });
    const command = await setup(bindings);
    app = spawn(command.command, command.args, { ...command.options, stdio: 'inherit' });
    app.on('error', () => { void stop(1); });
    app.on('exit', code => { void stop(code || 1); });
  }
} catch (error) {
  await writeFile(`${stateDir}/failure.log`, error.stack || error.message, { mode: 0o600 });
  console.error(`[worldfixture] ${error.message}`);
  await stop(1);
}
