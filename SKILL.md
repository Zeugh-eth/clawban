---
name: clawban
description: Clawban — shared Kanban task board for inter-agent coordination. Use when creating, picking, updating, or reviewing tasks across teams. Compatible with ClickUp task format for bidirectional sync.
---

# Clawban

Shared Kanban board for multi-agent coordination.

## Installation

Run the installer to set up storage and make scripts executable:

```bash
./install.sh
```

Or with web server:

```bash
./install.sh --start-web
```

## Requirements

- **Python 3** (for CLI commands)
- **Node.js** (optional, only for web interface)
- **curl** (optional, only for ClickUp sync)

## Session Start Protocol

On every session start:
1. Run `./scripts/cli.sh my <agent_id>` to see your assigned tasks
2. Run `./scripts/cli.sh feed --last 10` to catch up on recent activity
3. Pick or continue a task before doing anything else (unless user gives direct instructions)

## Quick Reference

All commands use the CLI at `scripts/cli.sh`.

```bash
CLI="path/to/clawban/scripts/cli.sh"

# View board
$CLI list                          # All open tasks
$CLI my cta                        # My tasks (replace with your agent id)
$CLI view CLAW-001                 # Task detail
$CLI feed --last 10                # Recent activity

# Create tasks
$CLI add "Title" --assign cta --priority 2 --creator pa --status "to do"
$CLI add "Title" --assign cra --priority 3 --creator cta --tags "research,ens" --description "Details here"

# Update tasks
$CLI status CLAW-001 "in progress"
$CLI status CLAW-001 "complete"
$CLI comment CLAW-001 "Deployed to staging, testing now"
$CLI assign CLAW-001 cra
$CLI priority CLAW-001 1

# Pick next task
$CLI pick cta                      # Grab highest-priority ready task

# ClickUp sync
$CLI pull-clickup <task_id>        # Import a ClickUp task
$CLI push-clickup CLAW-001         # Sync status back to ClickUp
```

## Statuses (ClickUp-compatible)

Flow: `to do` → `backlog` → `planning` → `in progress` → `blocked` → `update required` → `on hold` → `review` → `complete` → `cancelled`

Status types:
- **Open:** `to do`, `backlog`
- **Active:** `planning`, `in progress`, `update required`
- **Blocked:** `blocked`, `on hold`
- **Done:** `review`, `complete`, `cancelled`

## Priority (ClickUp-compatible)

| Value | Label |
|-------|-------|
| 1 | Urgent |
| 2 | High |
| 3 | Normal |
| 4 | Low |
| null | None |

## Task ID Format

- Local tasks: `CLAW-001`, `CLAW-002`, etc. (auto-incremented)
- ClickUp imports: `CU-86ag0yfpm` (preserves original ID for sync)

## Creating Tasks for Other Agents

Any agent can create tasks for any other agent. Include enough context in the description so the receiving agent can work independently:

```bash
$CLI add "Analyze ENS delegation patterns Q1 2026" \
  --assign cra \
  --priority 3 \
  --creator cta \
  --tags "research,ens" \
  --description "Need data on delegation patterns for the ENS services proposal. Focus on: top 20 delegates, voting participation rates, delegation concentration. Output: summary in memory/research/"
```

## Web Interface (Optional)

The web dashboard provides a live Kanban view with:
- Real-time board status
- Agent activity tracking
- Auto-refresh every 15 seconds
- Click tasks to expand details/comments

**Start the server:**

```bash
cd web && node server.js
```

**Configuration:**

```bash
# Custom port
CLAWBAN_PORT=8080 node server.js

# Localhost only
CLAWBAN_HOST=127.0.0.1 node server.js

# Bearer token auth
CLAWBAN_AUTH_TOKEN=secret node server.js
```

Default: http://localhost:18793

## Configuration

The CLI and web server use environment variables for configuration:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAWBAN_HOME` | Skill directory | Storage location |
| `CLAWBAN_BOARD` | `$CLAWBAN_HOME/board.json` | Task storage file |
| `CLAWBAN_ACTIVITY` | `$CLAWBAN_HOME/activity.jsonl` | Activity feed file |
| `CLAWBAN_PORT` | 18793 | Web server port |
| `CLAWBAN_HOST` | 0.0.0.0 | Web server bind address |
| `CLAWBAN_AUTH_TOKEN` | (none) | Bearer token for API auth |
| `CLICKUP_API_KEY` | (none) | ClickUp API key for sync |

## ClickUp Integration

Clawban tasks use a ClickUp-compatible format for seamless bidirectional sync.

**Import from ClickUp:**

```bash
export CLICKUP_API_KEY="your_key"
$CLI pull-clickup <clickup_task_id>
```

**Sync status back:**

```bash
$CLI push-clickup CLAW-001
```

Only tasks imported from ClickUp can be synced back (they have `source: "clickup"`).

## Data Structure

See [references/schema.md](references/schema.md) for the full ClickUp-compatible task schema.

## Files

- `board.json` — Single source of truth for all tasks
- `activity.jsonl` — Append-only activity feed
- `scripts/cli.sh` — CLI interface for all operations
- `web/server.js` — Optional web server
- `web/index.html` — Dashboard UI

## Troubleshooting

**CLI commands fail with "No such file"**
- Run `./install.sh` to initialize storage files

**ClickUp commands fail**
- Set `CLICKUP_API_KEY` environment variable
- Ensure `curl` is installed

**Web server won't start**
- Install Node.js
- Check port availability: `lsof -i :18793`

**Tasks not appearing in web UI**
- Check browser console for errors
- Verify server is running: `curl http://localhost:18793/api/board`

## See Also

- [README.md](README.md) — Installation and distribution guide
- [references/schema.md](references/schema.md) — Task schema specification
