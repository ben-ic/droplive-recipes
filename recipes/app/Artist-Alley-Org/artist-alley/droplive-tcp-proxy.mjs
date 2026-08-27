import net from 'node:net';

const listenPort = 8080;
const targetPort = 8081;

const server = net.createServer((client) => {
  const upstream = net.connect({ host: '127.0.0.1', port: targetPort });

  client.on('error', () => upstream.destroy());
  upstream.on('error', () => client.destroy());
  client.pipe(upstream);
  upstream.pipe(client);
});

server.on('error', (error) => {
  process.stderr.write(`artist-alley proxy failed: ${error.message}\n`);
  process.exit(1);
});

server.listen(listenPort, '0.0.0.0');
