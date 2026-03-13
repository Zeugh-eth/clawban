# Clawban CLI

## Entry Points

- Canonical backend: `scripts/clawban.py`
- Stable shell wrapper: `scripts/cli.sh`

The shell wrapper should remain stable so existing AGENTS.md snippets do not break.

## Global Option

- `--json` emits machine-readable JSON for command results and errors

## Commands

### `list [status]`

- Lists open tasks by default
- If `status` is provided, lists tasks with that exact normalized status

### `my <agent>`

- Lists open tasks assigned to the agent

### `view <task_id>`

- Shows all task fields and comments

### `add <title> [options]`

Options:
- `--assign <agent[,agent]>`
- `--priority <1-4>`
- `--creator <agent>`
- `--status <status>`
- `--tags <a,b>`
- `--description <text>`
- `--parent <task_id>`
- `--due <YYYY-MM-DD or ISO value>`

### `status <task_id> <status> [agent]`

- Updates the task status
- Logs a `status_change` activity event under the provided agent or `system`

### `comment <task_id> <text> [agent]`

- Appends a comment
- Updates `date_updated`

### `assign <task_id> <agent>`

- Replaces the assignee list with a single assignee

### `priority <task_id> <1-4>`

- Sets ClickUp-compatible priority metadata

### `pick <agent>`

- Finds the highest-priority task assigned to the agent in:
  - `to do`
  - `backlog`
  - `planning`
- Changes it to `in progress`

### `feed --last <n>`

- Reads the append-only activity log
- Returns the most recent `n` events, default `20`

### `pull-clickup <task_id>`

- Requires `curl`
- Requires `CLICKUP_API_KEY` in env or `~/.openclaw/openclaw.json`

### `push-clickup <task_id>`

- Requires a task with `source: "clickup"`
- Only pushes status back to ClickUp

## Exit Codes

- `0` success
- `1` runtime or external integration failure
- `2` validation or input error

## Automation Expectations

- Use `--json` in scripts, bots, or wrappers
- Treat `board.json` as the source of truth, not terminal output
- Avoid writing `board.json` directly outside the CLI unless you also preserve schema and locking behavior
