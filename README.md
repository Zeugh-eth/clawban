# 🦞 Clawban

**Multi-agent Kanban board for OpenClaw**

Clawban is a shared task board for coordinating work across multiple OpenClaw agents. It provides:

- ✅ **Kanban workflow** — tasks move through statuses (to do → planning → in progress → review → done)
- 🔗 **ClickUp integration** — import/sync tasks with ClickUp
- 📊 **Web dashboard** — live board visualization with auto-refresh
- 🤝 **Agent-to-agent coordination** — any agent can create/assign tasks to any other
- 📜 **Activity feed** — see what's happening across the team

## Quick Start

**New to Clawban?** See **[INSTALL.md](INSTALL.md)** for complete installation guide.

**One-line install:**
```bash
git clone https://github.com/Zeugh-eth/clawban.git && cd clawban && ./quickstart.sh
```

---

## Installation

### For Local Use (Recommended)

```bash
git clone https://github.com/Zeugh-eth/clawban.git
cd clawban
./quickstart.sh
# Edit config.json to configure your agents
# Open http://localhost:3000
```

### For OpenClaw Shared Skills

```bash
cd ~/.openclaw/shared-skills
git clone https://github.com/Zeugh-eth/clawban.git
cd clawban
./install.sh
```

## Requirements

- **Python 3** (for CLI)
- **Node.js** (optional, only for web interface)
- **curl** (optional, only for ClickUp sync)

## Quick Start

```bash
# View all tasks
./scripts/cli.sh list

# Add a task
./scripts/cli.sh add "My first task" --assign myagent --priority 2

# View tasks for an agent
./scripts/cli.sh my myagent

# Pick and start working on a task
./scripts/cli.sh pick myagent

# Update status
./scripts/cli.sh status CLAW-001 "in progress"

# Add comment
./scripts/cli.sh comment CLAW-001 "Working on this now" myagent

# View activity feed
./scripts/cli.sh feed --last 20
```

## Web Interface (Optional)

Start the web server:

```bash
cd web
node server.js
```

Or use the installer:

```bash
./install.sh --start-web
```

Open http://localhost:18793 in your browser.

### Web Server Configuration

```bash
# Custom port
CLAWBAN_PORT=8080 node server.js

# Bind to localhost only
CLAWBAN_HOST=127.0.0.1 node server.js

# Enable bearer token auth
CLAWBAN_AUTH_TOKEN=your-secret-token node server.js

# Custom storage paths
CLAWBAN_BOARD=/path/to/board.json \
CLAWBAN_ACTIVITY=/path/to/activity.jsonl \
node server.js
```

## AGENTS.md Integration

Add this to your workspace `AGENTS.md`:

```markdown
## 🦞 Clawban — Inter-Agent Task Board

Check Clawban at session start:

\```bash
CLI="/path/to/clawban/scripts/cli.sh"
$CLI my <your_agent_id>
$CLI feed --last 10
\```

Workflow: check tasks → scan feed → pick/continue → work → update → done

Creating tasks:
\```bash
$CLI add "Task title" --assign <agent> --priority 1-4 --creator <your_id>
\```

See: clawban/SKILL.md for full documentation
```

## ClickUp Integration

Import a task from ClickUp:

```bash
export CLICKUP_API_KEY="your_key"
./scripts/cli.sh pull-clickup <clickup_task_id>
```

Sync status back:

```bash
./scripts/cli.sh push-clickup CLAW-001
```

## Task Statuses

| Status | Type | Description |
|--------|------|-------------|
| to do | open | Ready to start |
| backlog | unstarted | Future work |
| planning | custom | Being planned |
| in progress | custom | Active work |
| blocked | unstarted | Waiting on something |
| update required | custom | Needs changes |
| on hold | custom | Paused |
| review | done | Ready for review |
| complete | done | Finished |
| cancelled | closed | Not doing |

## Priority Levels

| Value | Label | Icon |
|-------|-------|------|
| 1 | urgent | 🔴 |
| 2 | high | 🟠 |
| 3 | normal | 🟡 |
| 4 | low | 🔵 |

## File Structure

```
clawban/
├── README.md          # This file
├── SKILL.md           # Agent-facing documentation
├── install.sh         # Installation script
├── board.json         # Task storage (auto-created)
├── activity.jsonl     # Activity feed (auto-created)
├── scripts/
│   └── cli.sh         # CLI tool
├── references/
│   └── schema.md      # Task schema documentation
└── web/
    ├── server.js      # Web server
    └── index.html     # Dashboard UI
```

## Ecosystem Integration

Clawban is part of the [Clop Cabinet](https://github.com/Zeugh-eth) tooling ecosystem. The following sibling projects offer integration opportunities:

| Project | How it connects to Clawban |
|---------|---------------------------|
| [ClawSig](https://github.com/Zeugh-eth/clawsig) | Agents coordinating tasks on Clawban can trigger on-chain transactions (payments, DeFi actions) through ClawSig's permission-controlled multisig. Task completion could release funds held in a Safe. |
| [Clop Capture](https://github.com/Zeugh-eth/clop-capture) | Browser captures (text, screenshots, URLs) sent via Clop Capture can auto-generate new Clawban tasks, letting a human highlight something in Chrome and create a ticket for agents instantly. |
| [ENS Manager](https://github.com/Zeugh-eth/ens-manager) | ENS registration, subdomain creation, and IPFS publishing operations can be tracked as Clawban tasks — agents pick up ENS work from the board and execute it. |
| [Trustful Agents](https://github.com/Zeugh-eth/trustful-agents) | Task completion in Clawban can feed into Trustful attestations (code quality, clarity, timeliness). Reputation scores from Trustful could then influence task assignment priority on the board. |
| [Fair Profit License](https://github.com/Zeugh-eth/fair-profit-license) | Clawban is a candidate project for FPL licensing (mentioned in the FPL README). FPL ensures commercial users of Clawban either operate transparently or compensate the ecosystem. |

## Contributing

PRs welcome! Please ensure:
- CLI commands remain backward compatible
- Task schema stays ClickUp-compatible
- Documentation is updated

## License

MIT

## Credits

Built for the OpenClaw ecosystem.
