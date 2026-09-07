import { spawn } from 'node:child_process';
import { mkdir, readFile, writeFile, rm } from 'node:fs/promises';
import { loadManifests } from '/opt/worldfixture/runtime/src/manifests.mjs';
import { resolveEnvironment } from '/opt/worldfixture/runtime/src/resolve.mjs';
import { start } from '/opt/worldfixture/runtime/src/supervisor.mjs';
import { startWorkbench } from '/opt/worldfixture/runtime/src/workbench.mjs';

const artifactPath = '/opt/worldfixture/dist/business.saas-company.v3';
const serviceRoot = '/opt/worldfixture/emulators';
const stateDir = '/data/worldfixture';
// Provider manifests execute `node`. Node-RED retains its original executable.
process.env.PATH = `/opt/worldfixture/bin:${process.env.PATH}`;
let instance, workbench, app, stopping = false;

async function stop(code) {
  if (stopping) return;
  stopping = true;
  process.exitCode = code;
  app?.kill('SIGTERM');
  const deadline = setTimeout(() => app?.kill('SIGKILL'), 10000);
  deadline.unref();
  await workbench?.close();
  await instance?.stop({ graceMs: 5000 });
  await rm(`${stateDir}/bindings.json`, { force: true });
}

try {
  await mkdir(stateDir, { recursive: true });
  await rm(`${stateDir}/bindings.json`, { force: true });
  const world = JSON.parse(await readFile(`${artifactPath}/world.json`, 'utf8'));
  const profiles = { GITHUB: 'github.repositories.v1', SLACK: 'slack.messaging.v1', NOTION: 'notion.pages-read.v1' };
  const lock = resolveEnvironment({
    api_version: 'worldfixture.environment/v1',
    world: { use: `${world.id}:${world.version}` },
    requires: [...Object.values(profiles), 'github.issues.v1', 'notion.blocks-read.v1'],
    execution: { mode: 'selected-capabilities' },
    bindings: Object.fromEntries(Object.entries(profiles).flatMap(([name, profile]) => [
      [`${name}_BASE_URL`, `${profile}/base_url`], [`${name}_TOKEN`, `${profile}/token`],
    ])),
    target: { kind: 'none', identity: world.people.find(person => person.primary).id },
  }, { manifests: loadManifests(serviceRoot), artifactPath });
  console.log('[worldfixture] Starting GitHub, Slack, and Notion');
  // WorldFixture verifies the artifact, generates credentials, starts the
  // providers, and proves their seed state before it returns. Its clock stays
  // paused: this demo changes provider state through the two manual workflows.
  instance = await start(lock, { artifactPath, serviceRoot, stateDir, runner: 'process', readyTimeoutMs: 120000 });
  process.on('SIGTERM', () => { void stop(0); });
  process.on('SIGINT', () => { void stop(0); });
  for (const record of instance.children) {
    record.child.on('exit', () => { void stop(1); });
    if (record.exited) throw new Error(`WorldFixture ${record.service} stopped`);
  }
  workbench = await startWorkbench(instance, {
    artifactPath, stateDir, host: '0.0.0.0',
    port: Number(process.env.DROPLIVE_WORKBENCH_PORT || 4715),
  });
  const bindings = instance.bindings();
  bindings.GITHUB_ORGANIZATION = world.people.find(person => person.primary).organization_id;
  for (const name of Object.keys(profiles)) {
    if (!bindings[`${name}_TOKEN`] || new URL(bindings[`${name}_BASE_URL`]).hostname !== '127.0.0.1') {
      throw new Error(`WorldFixture ${name} has no local binding`);
    }
  }
  await writeFile(`${stateDir}/bindings.json`, JSON.stringify(bindings), { mode: 0o600 });
  console.log('[worldfixture] GitHub, Slack, and Notion are ready; starting Node-RED');
  app = spawn('/usr/local/bin/node', [
    '/usr/src/node-red/node_modules/node-red/red.js', '--userDir', '/data', '--settings', '/data/settings.js',
  ], { env: { ...process.env, ...bindings }, stdio: 'inherit' });
  app.on('error', () => { void stop(1); });
  app.on('exit', code => { void stop(code || 1); });
} catch (error) {
  console.error(`[worldfixture] ${error.message}`);
  await stop(1);
}
