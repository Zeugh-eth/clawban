# Clawban Storage

## Files

- `board.json`: source of truth for tasks and `next_id`
- `activity.jsonl`: append-only activity stream
- `board.json.lock`: advisory lock file created by the CLI during writes

## Write Model

The Python CLI is responsible for writes.

It uses:
- storage initialization on startup
- advisory locking for board mutations
- atomic replace when writing `board.json`

This is intended to reduce corruption when multiple agents touch the board near the same time.

## Environment Variables

- `CLAWBAN_HOME`
  - default: skill root
- `CLAWBAN_BOARD`
  - default: `$CLAWBAN_HOME/board.json`
- `CLAWBAN_ACTIVITY`
  - default: `$CLAWBAN_HOME/activity.jsonl`
- `CLAWBAN_PORT`
  - default: `18793`
- `CLAWBAN_HOST`
  - default: `0.0.0.0`
- `CLAWBAN_AUTH_TOKEN`
  - optional bearer token for the web API

## Data Ownership

- The CLI owns board writes
- The web server is a read-only consumer
- Direct manual edits should be avoided unless repairing the board

## Recovery

If `board.json` is invalid JSON, the CLI resets it to an empty board during storage initialization. Use version control or backups if you need stronger recovery guarantees.
