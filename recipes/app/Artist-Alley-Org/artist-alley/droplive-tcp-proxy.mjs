import net from 'node:net';
import fs from 'node:fs';

const listenPort = 8080;
const targetPort = 8081;
const readyMarker = '/tmp/droplive-artist-alley-ready';
const preparingBody = `<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Preparing Artist Alley</title>
<style>body{margin:0;background:#111827;color:#f9fafb;font:18px system-ui,sans-serif;display:grid;min-height:100vh;place-items:center}main{max-width:36rem;padding:2rem}h1{font-size:2rem;margin:0 0 1rem}p{color:#d1d5db;line-height:1.5}</style>
<main><h1>Preparing the art library</h1><p>Artist Alley is importing its official demo collection and creating image previews. This page will refresh automatically.</p></main>
<script>setTimeout(()=>location.reload(),5000)</script></html>`;

function warmingResponse(request) {
  const firstLine = request.toString('ascii', 0, 256).split('\r\n', 1)[0] ?? '';
  const isHealth = firstLine.includes(' /healthz ');
  const body = isHealth ? 'ok\n' : preparingBody;
  const status = isHealth ? '200 OK' : '503 Service Unavailable';
  const retry = isHealth ? '' : 'Retry-After: 5\r\n';
  return `HTTP/1.1 ${status}\r\nContent-Type: ${isHealth ? 'text/plain' : 'text/html'}; charset=utf-8\r\nContent-Length: ${Buffer.byteLength(body)}\r\n${retry}Connection: close\r\n\r\n${body}`;
}

const server = net.createServer((client) => {
  client.once('data', (request) => {
    if (!fs.existsSync(readyMarker)) {
      client.end(warmingResponse(request));
      return;
    }

    const upstream = net.connect({ host: '127.0.0.1', port: targetPort }, () => {
      upstream.write(request);
      client.pipe(upstream);
      upstream.pipe(client);
    });

    client.on('error', () => upstream.destroy());
    upstream.on('error', () => client.destroy());
  });
});

server.on('error', (error) => {
  process.stderr.write(`artist-alley proxy failed: ${error.message}\n`);
  process.exit(1);
});

server.listen(listenPort, '0.0.0.0');
