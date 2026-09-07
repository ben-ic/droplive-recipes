export const part = 's3';
export async function setup(b) {
  for (const key of ['S3_BASE_URL', 'S3_ACCESS_KEY_ID', 'S3_SECRET_ACCESS_KEY', 'S3_REGION']) {
    if (!b[key]) throw new Error(`Missing ${key}`);
  }
  const endpoint = new URL(b.S3_BASE_URL);
  if (endpoint.hostname !== '127.0.0.1' || endpoint.protocol !== 'http:') {
    throw new Error('S3 must run on loopback inside this guest');
  }
  return { command: '/usr/local/bin/s3manager', args: [], options: {
    env: { ...process.env, ENDPOINT: endpoint.host, ACCESS_KEY_ID: b.S3_ACCESS_KEY_ID,
      SECRET_ACCESS_KEY: b.S3_SECRET_ACCESS_KEY, REGION: b.S3_REGION, USE_SSL: 'false', PORT: '8080' },
  } };
}
