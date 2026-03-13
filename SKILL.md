---
name: clawban
description: Clawban is a CLI-first shared Kanban board for OpenClaw agents. Use it when creating, assigning, updating, reviewing, or syncing tasks across agents or ClickUp.
homepage: https://github.com/yourusername/clawban
metadata:
  {
    "openclaw": {
      "emoji": "🦞",
      "requires": {
        "bins": ["python3"],
        "optionalBins": ["node", "curl"]
      }
    }
  }
---

# Clawban

Clawban is a shared task board with a stable CLI. The CLI is the canonical interface. The web UI is optional.

## Use It For

- creating or assigning work across agents
- reviewing your queue at session start
- updating status, comments, or priority during execution
- syncing imported ClickUp tasks back to ClickUp

## Session Start Protocol

At the start of each session:

```bash
CLI="/root/.openclaw/shared-skills/clawban/scripts/cli.sh"
$CLI my <agent_id>
$CLI feed --last 10
```

Unless the human gives direct instructions, pick or continue a task before starting unrelated work.

## Canonical Commands

```bash
CLI="/root/.openclaw/shared-skills/clawban/scripts/cli.sh"

$CLI list
$CLI my cta
$CLI view CLAW-001
$CLI add "Task title" --assign cta --priority 2 --creator main
$CLI status CLAW-001 "in progress" cta
$CLI comment CLAW-001 "Started implementation" cta
$CLI assign CLAW-001 cra
$CLI priority CLAW-001 1
$CLI pick cta
$CLI feed --last 10
```

For automation, add `--json` before the subcommand:

```bash
$CLI --json list
$CLI --json view CLAW-001
```

## ClickUp Sync

Import from ClickUp:

```bash
export CLICKUP_API_KEY="your_key"
$CLI pull-clickup <clickup_task_id>
```

Push status back:

```bash
$CLI push-clickup CU-<clickup_task_id>
```

Only imported ClickUp tasks can be pushed back.

## Files To Read When Needed

- `references/cli.md` for the full command reference and automation behavior
- `references/storage.md` for file layout, locking, and environment variables
- `references/clickup.md` for import/sync details and failure modes
- `references/schema.md` for the task schema

## File Layout

- `scripts/clawban.py` is the canonical CLI backend
- `scripts/cli.sh` is the compatibility entrypoint
- `board.json` is the board source of truth
- `activity.jsonl` is the append-only activity log
- `web/` is an optional dashboard on top of the same storage
