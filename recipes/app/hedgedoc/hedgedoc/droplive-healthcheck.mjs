try {
  const response = await fetch("http://127.0.0.1:3000/_health");
  const body = await response.json();
  if (!response.ok || body?.ready !== true) process.exit(1);
} catch (_error) {
  process.exit(1);
}
