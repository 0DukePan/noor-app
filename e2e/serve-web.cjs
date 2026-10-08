// Minimal static server for the Flutter web release build (build/web).
// Used as e2e `app.command` so runs are self-contained locally and in CI:
// the runner spawns `node e2e/serve-web.cjs {port}`, probes readiness, and
// stops it afterwards. Logs go to .e2e/logs/ via the config `log` setting.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const root = path.join(__dirname, '..', 'build', 'web');
const port = Number(process.argv[2] ?? '3000');

const types = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.wasm': 'application/wasm',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.map': 'application/json; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
};

const server = http.createServer((req, res) => {
  const url = new URL(req.url ?? '/', 'http://127.0.0.1');
  let file = path.join(root, decodeURIComponent(url.pathname));
  if (url.pathname.endsWith('/')) file = path.join(file, 'index.html');
  fs.readFile(file, (error, data) => {
    if (error) {
      // Single-page app: unknown paths fall back to index.html.
      fs.readFile(path.join(root, 'index.html'), (fallbackError, fallback) => {
        if (fallbackError) {
          res.writeHead(404).end('not found');
          return;
        }
        res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' }).end(fallback);
      });
      return;
    }
    res
      .writeHead(200, {
        'content-type': types[path.extname(file)] ?? 'application/octet-stream',
      })
      .end(data);
  });
});

server.listen(port, '127.0.0.1', () => {
  console.log(`serving build/web on http://127.0.0.1:${port}`);
});
