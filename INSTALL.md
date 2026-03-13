# Clawban - Local Installation Guide

**Install Clawban for your own agents in 5 minutes.**

---

## Quick Install (Copy-Paste)

```bash
# 1. Clone to your local machine
git clone https://github.com/Zeugh-eth/clawban.git
cd clawban

# 2. Install dependencies
cd web && npm install

# 3. Configure your agents (edit config.json)
cp config.example.json config.json
nano config.json  # Or use your favorite editor

# 4. Start the dashboard
npm start

# 5. Open in browser
# http://localhost:3000
```

**That's it!** 🎉

---

## What You Get

- **Task board** - Kanban-style view for all your agents
- **Activity feed** - Real-time updates of what agents are doing
- **CLI tool** - Command-line interface for scripts
- **ClickUp sync** - Optional two-way sync with ClickUp
- **Web dashboard** - Modern UI for visual management

---

## Step-by-Step Installation

### 1. Download Clawban

**Option A: Git Clone (Recommended)**
```bash
git clone https://github.com/Zeugh-eth/clawban.git
cd clawban
```

**Option B: Download ZIP**
```bash
curl -L https://github.com/Zeugh-eth/clawban/archive/refs/heads/master.zip -o clawban.zip
unzip clawban.zip
cd clawban-master
```

**Option C: OpenClaw Shared Skills**
```bash
# If you're using OpenClaw
cp -r /path/to/openclaw/shared-skills/clawban ~/clawban
cd ~/clawban
```

---

### 2. Install Dependencies

```bash
# Web dashboard dependencies
cd web
npm install
```

**Dependencies installed:**
- Express.js (web server)
- CORS middleware
- Basic HTTP utilities

**Size:** ~10MB  
**Time:** 30 seconds

---

### 3. Configure Your Agents

Create `config.json` in the clawban root directory:

```bash
cd ..  # Back to clawban root
cp config.example.json config.json
```

**Edit config.json:**

```json
{
  "agents": [
    {
      "id": "main",
      "name": "Main Agent",
      "emoji": "🤖",
      "role": "General Assistant"
    },
    {
      "id": "cta",
      "name": "Tech Agent",
      "emoji": "🔧",
      "role": "Engineering"
    }
  ],
  "board": {
    "path": "./board.json",
    "activityLog": "./activity.jsonl"
  },
  "server": {
    "port": 3000,
    "host": "localhost"
  },
  "clickup": {
    "enabled": false,
    "apiKey": "",
    "workspaceId": "",
    "listId": ""
  }
}
```

**Configuration options explained below.**

---

### 4. Initialize Board Data

```bash
# Create empty board (if starting fresh)
cat > board.json << 'EOF'
{
  "nextId": 1,
  "tasks": []
}
EOF

# Create empty activity log
touch activity.jsonl
```

**Or keep existing data** if you cloned from a repo that has sample tasks.

---

### 5. Start the Dashboard

```bash
cd web
npm start
```

**Output:**
```
Clawban Dashboard Server
========================
Server running on http://localhost:3000
Board API: http://localhost:3000/api/board
Activity API: http://localhost:3000/api/activity

Press Ctrl+C to stop
```

---

### 6. Open Dashboard

Visit in your browser:
- **Main dashboard:** http://localhost:3000
- **Board view:** http://localhost:3000/board.html
- **Activity feed:** http://localhost:3000/activity

---

## Configuration Guide

### Agent Configuration

**Minimal (2 agents):**
```json
{
  "agents": [
    {"id": "alice", "name": "Alice", "emoji": "👩"},
    {"id": "bob", "name": "Bob", "emoji": "👨"}
  ]
}
```

**Full (5 agents like Clop Cabinet):**
```json
{
  "agents": [
    {"id": "pa", "name": "Personal Assistant", "emoji": "🐴", "role": "Coordination"},
    {"id": "cta", "name": "Tech Agent", "emoji": "🔧", "role": "Engineering"},
    {"id": "cra", "name": "Research Agent", "emoji": "📚", "role": "Research"},
    {"id": "cma", "name": "Marketing Agent", "emoji": "📣", "role": "Marketing"},
    {"id": "cba", "name": "Business Agent", "emoji": "💼", "role": "Business"}
  ]
}
```

**Just one agent:**
```json
{
  "agents": [
    {"id": "agent", "name": "My Agent", "emoji": "🤖"}
  ]
}
```

**Agent fields:**
- `id` - Unique identifier (lowercase, no spaces)
- `name` - Display name
- `emoji` - Optional emoji for visual distinction
- `role` - Optional role description

---

### Board Configuration

```json
{
  "board": {
    "path": "./board.json",        // Where tasks are stored
    "activityLog": "./activity.jsonl", // Activity feed
    "autoSave": true,              // Auto-save on changes
    "backupInterval": 3600         // Backup every hour (seconds)
  }
}
```

**Defaults are fine for most users.**

---

### Server Configuration

```json
{
  "server": {
    "port": 3000,           // Dashboard port
    "host": "localhost",    // Bind to localhost only
    "cors": true           // Enable CORS for API access
  }
}
```

**Change port if 3000 is taken:**
```json
{"port": 8080}
```

**Make accessible from other machines:**
```json
{"host": "0.0.0.0"}  // ⚠️ Warning: Exposes to network
```

---

### ClickUp Integration (Optional)

```json
{
  "clickup": {
    "enabled": true,
    "apiKey": "YOUR_CLICKUP_API_KEY",
    "workspaceId": "90132341641",
    "listId": "901234567"
  }
}
```

**Get ClickUp credentials:**
1. Visit: https://app.clickup.com/settings/apps
2. Generate API token
3. Find workspace ID in ClickUp URL
4. Find list ID in task list URL

**Leave disabled if you don't use ClickUp:**
```json
{"clickup": {"enabled": false}}
```

---

## Using the Dashboard

### Create a Task

**Via Web UI:**
1. Click "+ New Task" button
2. Fill in title, assignee, priority
3. Click "Create"

**Via CLI:**
```bash
./scripts/cli.sh add "Task title" --assign alice --priority 1
```

**Via API:**
```bash
curl -X POST http://localhost:3000/api/board/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"Task title","assignee":"alice","priority":1}'
```

---

### View Tasks

**Web UI:**
- Kanban board view
- Filter by agent, status, priority
- Drag and drop to change status

**CLI:**
```bash
# All tasks
./scripts/cli.sh list

# My tasks
./scripts/cli.sh my alice

# By status
./scripts/cli.sh list --status "in progress"
```

**API:**
```bash
curl http://localhost:3000/api/board
```

---

### Update Task

**Web UI:**
- Click task card → Edit
- Or drag to new column (status change)

**CLI:**
```bash
./scripts/cli.sh update CLAW-123 --status "in progress"
./scripts/cli.sh update CLAW-123 --priority 2
./scripts/cli.sh comment CLAW-123 "Making progress!"
```

**API:**
```bash
curl -X PATCH http://localhost:3000/api/board/tasks/CLAW-123 \
  -H "Content-Type: application/json" \
  -d '{"status":"in progress"}'
```

---

## Adapting to Your Setup

### Different Number of Agents

**Solo agent setup:**
```json
{
  "agents": [{"id": "me", "name": "My Agent"}]
}
```

**Large team (10+ agents):**
```json
{
  "agents": [
    {"id": "agent1", "name": "Agent 1"},
    {"id": "agent2", "name": "Agent 2"},
    // ... add as many as needed
  ]
}
```

**No limit on agent count.** Dashboard scales to your team size.

---

### Different Agent Types

**Specialized agents:**
```json
{
  "agents": [
    {"id": "writer", "name": "Writer Bot", "emoji": "✍️", "role": "Content"},
    {"id": "coder", "name": "Code Bot", "emoji": "💻", "role": "Development"},
    {"id": "data", "name": "Data Bot", "emoji": "📊", "role": "Analytics"}
  ]
}
```

**Mixed human + AI:**
```json
{
  "agents": [
    {"id": "alice", "name": "Alice (Human)", "emoji": "👩"},
    {"id": "bot", "name": "AI Assistant", "emoji": "🤖"}
  ]
}
```

---

### Custom Workflows

**Add custom statuses** (edit board.json schema):
```json
{
  "statuses": [
    "backlog",
    "planning",
    "in progress",
    "review",
    "testing",     // Add custom statuses
    "deployed",
    "done"
  ]
}
```

**Custom priorities:**
```json
{
  "priorities": {
    "urgent": 1,
    "high": 2,
    "normal": 3,
    "low": 4,
    "someday": 5   // Add custom priority
  }
}
```

---

## Remote Access

### SSH Tunnel (Secure)

From your laptop:
```bash
ssh -L 3000:localhost:3000 user@your-server.com
```

Then access: http://localhost:3000 on your laptop

---

### Reverse Proxy (Nginx)

**Install Nginx:**
```bash
sudo apt install nginx
```

**Create config:**
```nginx
server {
    listen 80;
    server_name clawban.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Enable and restart:**
```bash
sudo ln -s /etc/nginx/sites-available/clawban /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

Access: http://clawban.yourdomain.com

---

### Vercel Deployment (Public)

**Already configured!** Just:

```bash
cd web
vercel deploy
```

Gives you a public URL: `https://your-clawban.vercel.app`

**⚠️ Security:** Anyone with the URL can view your board. Add authentication if needed.

---

## CLI Usage

### Quick Reference

```bash
# List all tasks
./scripts/cli.sh list

# My tasks
./scripts/cli.sh my <agent-id>

# Add task
./scripts/cli.sh add "Title" --assign <agent-id> --priority 1

# Update status
./scripts/cli.sh update CLAW-123 --status "in progress"

# Add comment
./scripts/cli.sh comment CLAW-123 "Update message"

# Activity feed
./scripts/cli.sh feed --last 10

# ClickUp sync
./scripts/cli.sh pull-clickup <clickup-task-id>
./scripts/cli.sh push-clickup CLAW-123
```

**Full CLI docs:** `references/cli.md`

---

## Troubleshooting

### Port 3000 already in use

```bash
# Change port in config.json
{"server": {"port": 8080}}

# Then restart
npm start
```

### Can't access from other machines

```bash
# Edit config.json
{"server": {"host": "0.0.0.0"}}

# Restart server
```

### Board data not saving

```bash
# Check permissions
chmod 644 board.json activity.jsonl

# Check disk space
df -h
```

### CLI not working

```bash
# Make executable
chmod +x scripts/cli.sh

# Install Python dependencies (if needed)
pip3 install requests
```

---

## File Structure

```
clawban/
├── board.json           # Task data (single source of truth)
├── activity.jsonl       # Activity feed (append-only log)
├── config.json          # Your configuration
├── config.example.json  # Example config
├── VERSION              # Clawban version
├── SKILL.md             # Skill documentation
├── README.md            # Overview
├── INSTALL.md           # This file
├── scripts/
│   ├── cli.sh           # CLI tool
│   ├── board_store.py   # Board operations
│   └── ...              # Other scripts
└── web/
    ├── server.js        # Dashboard server
    ├── board.html       # Kanban view
    ├── dashboard-v2.html # Advanced dashboard
    └── api/             # REST API endpoints
```

---

## Updates

### Pull latest version

```bash
cd clawban
git pull origin master
cd web && npm install  # Update dependencies
```

### Backup before updating

```bash
cp board.json board.json.backup
cp activity.jsonl activity.jsonl.backup
```

---

## Next Steps

1. **Configure your agents** in config.json
2. **Start the dashboard** with `npm start`
3. **Create your first task** via web UI or CLI
4. **Integrate with your agent workflows** via API

**Need help?** See:
- `references/cli.md` - CLI commands
- `references/schema.md` - Task schema
- `references/clickup.md` - ClickUp integration

---

**You're all set!** Start managing your agent tasks with Clawban. 🦞
