#!/usr/bin/env node

/**
 * Clawban Dashboard Server
 * Simple local server for running Clawban on your machine
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

// Paths
const SKILL_ROOT = path.join(__dirname, '..');
const CONFIG_PATH = path.join(SKILL_ROOT, 'config.json');
const BOARD_PATH = path.join(SKILL_ROOT, 'board.json');
const ACTIVITY_PATH = path.join(SKILL_ROOT, 'activity.jsonl');

// Load configuration
let config = {
  server: { port: 3000, host: 'localhost', cors: true },
  board: { path: BOARD_PATH, activityLog: ACTIVITY_PATH },
  agents: []
};

try {
  const userConfig = JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
  config = { ...config, ...userConfig };
} catch (e) {
  console.warn('⚠️  No config.json found, using defaults');
  console.warn('   Create config.json from config.example.json to customize');
}

const PORT = process.env.PORT || config.server.port;
const HOST = process.env.HOST || config.server.host;

// MIME types
const MIME_TYPES = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml'
};

// Serve static files
function serveFile(filePath, res) {
  const ext = path.extname(filePath);
  const contentType = MIME_TYPES[ext] || 'text/plain';
  
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(data);
    }
  });
}

// Create server
const server = http.createServer((req, res) => {
  // CORS
  if (config.server.cors) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PATCH, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
      res.writeHead(200);
      res.end();
      return;
    }
  }
  
  // API: Get board data
  if (req.url === '/api/board') {
    try {
      const data = fs.readFileSync(config.board.path, 'utf8');
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(data);
    } catch (e) {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Failed to read board' }));
    }
  }
  
  // API: Get activity feed
  else if (req.url === '/api/activity') {
    try {
      const raw = fs.readFileSync(config.board.activityLog, 'utf8').trim();
      const lines = raw ? raw.split('\n').map(l => {
        try { return JSON.parse(l); } catch { return null; }
      }).filter(Boolean) : [];
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(lines));
    } catch (e) {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end('[]');
    }
  }
  
  // API: Get configuration (for frontend)
  else if (req.url === '/api/config') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      agents: config.agents || [],
      ui: config.ui || {}
    }));
  }
  
  // Root - serve index.html
  else if (req.url === '/' || req.url === '/index.html') {
    serveFile(path.join(__dirname, 'index.html'), res);
  }
  
  // Board view
  else if (req.url === '/board' || req.url === '/board.html') {
    serveFile(path.join(__dirname, 'board.html'), res);
  }
  
  // Dashboard v2
  else if (req.url === '/dashboard' || req.url === '/dashboard-v2.html') {
    serveFile(path.join(__dirname, 'dashboard-v2.html'), res);
  }
  
  // Static files
  else {
    const filePath = path.join(__dirname, req.url);
    
    // Security: Don't serve files outside web directory
    if (!filePath.startsWith(__dirname)) {
      res.writeHead(403);
      res.end('Forbidden');
      return;
    }
    
    serveFile(filePath, res);
  }
});

// Start server
server.listen(PORT, HOST, () => {
  console.log('');
  console.log('🦞 Clawban Dashboard Server');
  console.log('========================');
  console.log(`Server running on http://${HOST}:${PORT}`);
  console.log('');
  console.log('Views:');
  console.log(`  Main: http://${HOST}:${PORT}/`);
  console.log(`  Board: http://${HOST}:${PORT}/board.html`);
  console.log(`  Dashboard: http://${HOST}:${PORT}/dashboard-v2.html`);
  console.log('');
  console.log('API:');
  console.log(`  Board: http://${HOST}:${PORT}/api/board`);
  console.log(`  Activity: http://${HOST}:${PORT}/api/activity`);
  console.log(`  Config: http://${HOST}:${PORT}/api/config`);
  console.log('');
  console.log(`Agents: ${config.agents.length || 0} configured`);
  console.log(`Data: ${config.board.path}`);
  console.log('');
  console.log('Press Ctrl+C to stop');
  console.log('');
});
