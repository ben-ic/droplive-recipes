import { mkdir, writeFile, chown } from 'node:fs/promises';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
export const part = 'mail';
export async function setup(bindings) {
  if (!bindings.IMAP_PASSWORD || !bindings.IMAP_USERNAME) throw new Error('Missing mailbox binding');
  await mkdir('/data/snappymail', { recursive: true });
  await chown('/data/snappymail', 33, 33);
  await writeFile('/snappymail/include.php', "<?php define('APP_DATA_FOLDER_PATH', '/data/snappymail/');\n");
  await writeFile('/data/snappymail/bindings.json', JSON.stringify(bindings), { mode: 0o600 });
  await chown('/data/snappymail/bindings.json', 33, 33);
  await promisify(execFile)('php', ['/opt/droplive/setup.php'], { uid: 33, gid: 33 });
  return { command: 'php', args: ['-d','display_errors=0','-d','log_errors=1','-d','upload_max_filesize=16M','-d','post_max_size=20M','-S','0.0.0.0:8888','-t','/snappymail','/opt/droplive/router.php'], options: { uid:33, gid:33, cwd:'/snappymail' } };
}
