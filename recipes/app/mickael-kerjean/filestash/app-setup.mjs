import { mkdir, writeFile, chown, rm, symlink } from 'node:fs/promises';
import { randomBytes } from 'node:crypto';
export const part = 's3';
export async function setup(b) {
  for (const key of ['S3_BASE_URL','S3_ACCESS_KEY_ID','S3_SECRET_ACCESS_KEY','S3_REGION']) {
    if (!b[key]) throw new Error(`Missing ${key}`);
  }
  const folder = '/data/filestash/state/config';
  await mkdir(folder, { recursive: true });
  const label = 'Northstar files';
  const config = {
    general: { name:label, secret_key:randomBytes(8).toString('hex'), force_ssl:false, telemetry:false },
    connections:[{type:'s3',label}],
    middleware:{
      identity_provider:{type:'passthrough',params:JSON.stringify({strategy:'direct'})},
      attribute_mapping:{related_backend:label,params:JSON.stringify({[label]:{
        type:'s3',endpoint:b.S3_BASE_URL,access_key_id:b.S3_ACCESS_KEY_ID,
        secret_access_key:b.S3_SECRET_ACCESS_KEY,region:b.S3_REGION,path:'/',
      }})},
    },
  };
  await writeFile(`${folder}/config.json`, JSON.stringify(config), {mode:0o600});
  for (const path of ['/data/filestash','/data/filestash/state',folder,`${folder}/config.json`]) await chown(path,1000,1000);
  await rm('/app/data', {recursive:true,force:true});
  await symlink('/data/filestash','/app/data');
  return {command:'/app/filestash',args:[],options:{cwd:'/app',uid:1000,gid:1000,env:{...process.env,CONFIG_ENCRYPT:'false',ADMIN_PASSWORD:randomBytes(24).toString('hex')}}};
}
