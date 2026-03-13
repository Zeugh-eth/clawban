# Clawban ClickUp Sync

## Auth

Clawban looks for `CLICKUP_API_KEY` in:

1. the current environment
2. `~/.openclaw/openclaw.json` under `env.vars.CLICKUP_API_KEY`

## Import Behavior

`pull-clickup <id>`:

- fetches the ClickUp task via API
- preserves the original ClickUp ID in `source_id`
- stores the local task ID as `CU-<clickup_id>`
- converts ClickUp timestamps to ISO 8601
- maps status names directly into Clawban status fields

## Push Behavior

`push-clickup <id>`:

- only works for tasks with `source: "clickup"`
- currently syncs status only

## Failure Modes

- missing `curl`
- missing `CLICKUP_API_KEY`
- API authentication failure
- network or ClickUp API errors
- attempting to push a non-ClickUp task

Use `--json` if another tool needs structured error handling.
