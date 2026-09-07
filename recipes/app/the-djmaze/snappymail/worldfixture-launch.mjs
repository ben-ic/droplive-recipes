import { spawn } from 'node:child_process';
import { mkdir, open, readFile, rm } from 'node:fs/promises';
import { setTimeout as delay } from 'node:timers/promises';
import { setup, part } from './app-setup.mjs';

const state = '/data/worldfixture';
const children = new Set();
let stopping = false, monitor;
function stop(code) {
  if (stopping) return;
  stopping = true;
  process.exitCode = code;
  clearInterval(monitor);
  for (const child of children) child.kill('SIGTERM');
  const deadline = setTimeout(() => {
    for (const child of children) child.kill('SIGKILL');
  }, 20000);
  deadline.unref();
}
function run(command, args, options = {}) {
  const child = spawn(command, args, options);
  children.add(child);
  child.on('error', () => stop(1));
  child.on('exit', code => { children.delete(child); if (!stopping) stop(code || 1); });
  return child;
}
process.on('SIGTERM', () => stop(0));
process.on('SIGINT', () => stop(0));
try {
  await mkdir(state, { recursive: true });
  await rm(`${state}/bindings.json`, { force: true });
  const log = await open(`${state}/startup.log`, 'w', 0o600);
  console.log(`[worldfixture] Starting ${part}`);
  run(process.execPath, ['/opt/worldfixture/runtime/bin/worldfixture.mjs', 'up',
    '--world-path', '/opt/worldfixture/dist/business.saas-company.v3',
    '--service-root', '/opt/worldfixture/emulators', '--state', state,
    '--only', part, '--no-rebase', '--setup'], {
    env: { ...process.env, WORLDFIXTURE_SINGLE_CONTAINER: '1' },
    stdio: ['ignore', log.fd, log.fd],
  });
  await log.close();
  let bindings;
  const deadline = Date.now() + 300000;
  while (!stopping && Date.now() < deadline) {
    try { bindings = JSON.parse(await readFile(`${state}/bindings.json`, 'utf8')); break; }
    catch (error) { if (error.code !== 'ENOENT') throw error; }
    await delay(250);
  }
  if (!bindings || stopping) throw new Error('WorldFixture did not become ready; see private startup.log');
  const app = await setup(bindings);
  if (stopping) throw new Error('Startup interrupted');
  run(app.command, app.args, { ...app.options, stdio: 'inherit' });
  console.log(`[worldfixture] ${part} is ready; application started`);
  // CLI 0.2.5 remains alive if a provider fails. Its progress file records that
  // failure. Stop the app instead of leaving a usable-looking dead connection.
  monitor = setInterval(async () => {
    try {
      const progress = JSON.parse(await readFile(`${state}/progress.json`, 'utf8'));
      if (progress.phase === 'failed') stop(1);
    } catch { stop(1); }
  }, 1000);
} catch (error) {
  console.error(`[worldfixture] ${error.message}`);
  stop(1);
}
