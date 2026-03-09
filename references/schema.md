# Clawban Task Schema

ClickUp-compatible task format for bidirectional sync.

## Task Object

```json
{
  "id": "CLAW-001",
  "source": "clawban",
  "source_id": null,
  "name": "Task title",
  "description": "Detailed description",
  "status": {
    "status": "to do",
    "type": "open"
  },
  "priority": {
    "id": 3,
    "priority": "normal"
  },
  "assignees": ["cta"],
  "creator": "pa",
  "tags": ["infra", "security"],
  "parent": null,
  "due_date": null,
  "start_date": null,
  "date_created": "2026-03-09T17:00:00Z",
  "date_updated": "2026-03-09T17:00:00Z",
  "date_closed": null,
  "dependencies": [],
  "checklists": [],
  "custom_fields": [],
  "comments": [
    {
      "author": "cta",
      "text": "Started working on this",
      "at": "2026-03-09T17:30:00Z"
    }
  ]
}
```

## Field Reference

| Field | Type | ClickUp Equivalent | Notes |
|-------|------|-------------------|-------|
| id | string | id | `CLAW-NNN` for local, `CU-xxx` for imports |
| source | string | — | `"clawban"` or `"clickup"` |
| source_id | string/null | id | Original ClickUp ID for sync |
| name | string | name | Task title |
| description | string | text_content | Plain text, minimal formatting |
| status.status | string | status.status | ClickUp status names |
| status.type | string | status.type | open/unstarted/custom/done/closed |
| priority.id | int/null | priority.id | 1=urgent, 2=high, 3=normal, 4=low |
| priority.priority | string/null | priority.priority | "urgent"/"high"/"normal"/"low" |
| assignees | string[] | assignees[].id | Agent IDs |
| creator | string | creator.id | Agent ID or "zeugh" |
| tags | string[] | tags[].name | Simple string tags |
| parent | string/null | parent | Parent task ID for subtasks |
| due_date | string/null | due_date | ISO 8601 (ClickUp uses unix ms) |
| start_date | string/null | start_date | ISO 8601 |
| date_created | string | date_created | ISO 8601 |
| date_updated | string | date_updated | ISO 8601 |
| date_closed | string/null | date_closed | ISO 8601 |
| dependencies | string[] | dependencies | Task IDs |
| checklists | array | checklists | ClickUp-format checklists |
| custom_fields | array | custom_fields | ClickUp-format custom fields |
| comments | array | — | Local comments (not synced to ClickUp) |

## Status Type Mapping

| Status | Type |
|--------|------|
| to do | open |
| backlog | unstarted |
| blocked | unstarted |
| planning | custom |
| in progress | custom |
| update required | custom |
| on hold | custom |
| complete | done |
| review | done |
| cancelled | closed |

## Priority Mapping

| ClickUp ID | ClickUp Label | Clawban |
|-------------|--------------|---------|
| 1 | urgent | urgent |
| 2 | high | high |
| 3 | normal | normal |
| 4 | low | low |
| null | none | none |

## ClickUp Sync

When importing from ClickUp:
- `source` = `"clickup"`
- `source_id` = original ClickUp task ID
- `id` = `"CU-"` + original ID
- Dates converted from unix ms to ISO 8601
- Assignees mapped: ClickUp user ID 84844111 → "zeugh"

When pushing to ClickUp:
- Only tasks with `source: "clickup"` can sync back
- Uses `source_id` for the API call
- Converts dates back to unix ms
- Status name passed directly (already compatible)
