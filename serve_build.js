const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, 'build', 'web');
const port = 8765;

const mime = {
  '.html': 'text/html', '.js': 'application/javascript', '.css': 'text/css',
  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml', '.ico': 'image/x-icon', '.wasm': 'application/wasm',
  '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff': 'font/woff', '.woff2': 'font/woff2',
  '.txt': 'text/plain',
};

http.createServer((req, res) => {
  let reqPath = decodeURIComponent(req.url.split('?')[0]);
  let filePath = path.join(root, reqPath);
  if (!filePath.startsWith(root)) { res.writeHead(403); res.end(); return; }
  fs.stat(filePath, (err, stat) => {
    if (err || !stat.isFile()) filePath = path.join(root, 'index.html');
    const ext = path.extname(filePath).toLowerCase();
    res.writeHead(200, { 'Content-Type': mime[ext] || 'application/octet-stream', 'Cache-Control': 'no-cache' });
    fs.createReadStream(filePath).pipe(res);
  });
}).listen(port, () => console.log(`Serving build/web on http://localhost:${port}`));
