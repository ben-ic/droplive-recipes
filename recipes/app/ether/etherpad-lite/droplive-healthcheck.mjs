const response = await fetch('http://127.0.0.1:9001/health');

if (!response.ok) process.exit(1);

let body;
try {
  body = await response.json();
} catch {
  process.exit(1);
}

if (body?.status !== 'pass' || typeof body.releaseId !== 'string' || body.releaseId.length === 0) {
  process.exit(1);
}
