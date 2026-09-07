export async function setup(bindings) {
  for (const key of ['POSTGRES_HOST', 'POSTGRES_PORT', 'POSTGRES_USERNAME', 'POSTGRES_PASSWORD', 'POSTGRES_DATABASE']) {
    if (!bindings[key]) throw new Error(`Missing ${key} binding`);
  }
  if (bindings.POSTGRES_HOST !== '127.0.0.1') throw new Error('PostgreSQL must be inside this guest');
  return { command: process.execPath, args: ['/opt/droplive/metabase.mjs'], options: { env: { ...process.env, ...bindings } } };
}
