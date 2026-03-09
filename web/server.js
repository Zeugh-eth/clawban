const http = require('http');
const fs = require('fs');
const path = require('path');

// Configuration via environment variables
const PORT = parseInt(process.env.CLAWBAN_PORT || '18793', 10);
const HOST = process.env.CLAWBAN_HOST || '0.0.0.0';
const SKILL_ROOT = path.join(__dirname, '..');
const BOARD = process.env.CLAWBAN_BOARD || path.join(SKILL_ROOT, 'board.json');
const ACTIVITY = process.env.CLAWBAN_ACTIVITY || path.join(SKILL_ROOT, 'activity.jsonl');
const AUTH_TOKEN = process.env.CLAWBAN_AUTH_TOKEN || null;
const HTML = path.join(__dirname, 'index.html');

const server = http.createServer((req, res) => {
  // CORS (if configured)
  const origin = process.env.CLAWBAN_CORS_ORIGIN;
  if (origin) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }

  // Basic auth (optional)
  if (AUTH_TOKEN && req.url.startsWith('/api/')) {
    const auth = req.headers.authorization;
    if (!auth || auth !== `Bearer ${AUTH_TOKEN}`) {
      res.writeHead(401, { 'WWW-Authenticate': 'Bearer' });
      res.end('Unauthorized');
      return;
    }
  }

  if (req.url === '/api/board') {
    try {
      const data = fs.readFileSync(BOARD, 'utf8');
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(data);
    } catch (e) {
      res.writeHead(500);
      res.end(JSON.stringify({ error: e.message }));
    }
  } else if (req.url === '/api/activity') {
    try {
      const raw = fs.readFileSync(ACTIVITY, 'utf8').trim();
      const lines = raw ? raw.split('\n').map(l => { try { return JSON.parse(l); } catch { return null; } }).filter(Boolean) : [];
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(lines));
    } catch (e) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end('[]');
    }
  } else {
    try {
      const html = fs.readFileSync(HTML, 'utf8');
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(html);
    } catch (e) {
      res.writeHead(500);
      res.end('Error loading page');
    }
  }
});

server.listen(PORT, HOST, () => {
  console.log(`🦞 Clawban Board: http://${HOST}:${PORT}`);
  console.log(`   Board: ${BOARD}`);
  console.log(`   Activity: ${ACTIVITY}`);
  if (AUTH_TOKEN) console.log(`   Auth: enabled (Bearer token)`);
});
