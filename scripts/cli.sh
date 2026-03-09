#!/bin/bash
# Clawban CLI — Shared Kanban for Multi-Agent Coordination
# Usage: ./cli.sh <command> [args]
set -e

# Portable paths
SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLAWBAN_HOME="${CLAWBAN_HOME:-$SKILL_ROOT}"
BOARD="${CLAWBAN_BOARD:-$CLAWBAN_HOME/board.json}"
ACTIVITY="${CLAWBAN_ACTIVITY:-$CLAWBAN_HOME/activity.jsonl}"

# Ensure files exist
ensure_storage() {
  if [ ! -f "$BOARD" ]; then
    echo '{"version":1,"next_id":1,"tasks":[]}' > "$BOARD"
  fi
  if [ ! -f "$ACTIVITY" ]; then
    touch "$ACTIVITY"
  fi
  
  # Validate board.json
  if ! python3 -c "import json; json.load(open('$BOARD'))" 2>/dev/null; then
    echo "❌ Invalid board.json - resetting to empty" >&2
    echo '{"version":1,"next_id":1,"tasks":[]}' > "$BOARD"
  fi
}

ensure_storage

log_activity() {
  local agent="$1" action="$2" task_id="$3" detail="$4"
  echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"agent\":\"$agent\",\"action\":\"$action\",\"task_id\":\"$task_id\",\"detail\":\"$detail\"}" >> "$ACTIVITY"
}

PRIORITY_MAP='{"1":"urgent","2":"high","3":"normal","4":"low"}'
STATUS_TYPES='{"to do":"open","backlog":"unstarted","blocked":"unstarted","planning":"custom","in progress":"custom","update required":"custom","on hold":"custom","complete":"done","review":"done","cancelled":"closed"}'

case "${1:-help}" in

  add)
    shift
    TITLE=""
    ASSIGN=""
    PRIORITY=""
    CREATOR=""
    STATUS="to do"
    TAGS=""
    DESC=""
    PARENT=""
    DUE=""

    while [ $# -gt 0 ]; do
      case "$1" in
        --assign) ASSIGN="$2"; shift 2 ;;
        --priority) PRIORITY="$2"; shift 2 ;;
        --creator) CREATOR="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --tags) TAGS="$2"; shift 2 ;;
        --description) DESC="$2"; shift 2 ;;
        --parent) PARENT="$2"; shift 2 ;;
        --due) DUE="$2"; shift 2 ;;
        *) [ -z "$TITLE" ] && TITLE="$1" || TITLE="$TITLE $1"; shift ;;
      esac
    done

    if [ -z "$TITLE" ]; then
      echo "Usage: cli.sh add \"Task title\" --assign <agent> [--priority 1-4] [--creator <agent>] [--status <status>] [--tags tag1,tag2] [--description \"...\"] [--parent CLAW-N] [--due 2026-03-15]"
      exit 1
    fi

    python3 << PYEOF
import json, sys
from datetime import datetime, timezone

board = json.load(open("$BOARD"))
task_id = f"CLAW-{board['next_id']:03d}"
board['next_id'] += 1

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

status_types = $STATUS_TYPES
priority_map = $PRIORITY_MAP

status = "$STATUS".lower()
stype = status_types.get(status, "custom")

pri_id = int("$PRIORITY") if "$PRIORITY" and "$PRIORITY".isdigit() else None
pri_label = priority_map.get(str(pri_id), None) if pri_id else None

assignees = [a.strip() for a in "$ASSIGN".split(",") if a.strip()] if "$ASSIGN" else []
tags = [t.strip() for t in "$TAGS".split(",") if t.strip()] if "$TAGS" else []

task = {
    "id": task_id,
    "source": "clawban",
    "source_id": None,
    "name": """$TITLE""",
    "description": """$DESC""",
    "status": {"status": status, "type": stype},
    "priority": {"id": pri_id, "priority": pri_label} if pri_id else {"id": None, "priority": None},
    "assignees": assignees,
    "creator": "$CREATOR" or "unknown",
    "tags": tags,
    "parent": "$PARENT" or None,
    "due_date": "$DUE" or None,
    "start_date": None,
    "date_created": now,
    "date_updated": now,
    "date_closed": None,
    "dependencies": [],
    "checklists": [],
    "custom_fields": [],
    "comments": []
}

board['tasks'].append(task)
json.dump(board, open("$BOARD", "w"), indent=2)
print(f"✅ Created {task_id}: {task['name']}")
print(f"   Status: {status} | Priority: {pri_label or 'none'} | Assigned: {', '.join(assignees) or 'unassigned'}")
PYEOF

    log_activity "${CREATOR:-unknown}" "created" "$(python3 -c "import json; b=json.load(open('$BOARD')); print(b['tasks'][-1]['id'])")" "$TITLE"
    ;;

  list)
    shift
    STATUS_FILTER="${1:-}"
    python3 << PYEOF
import json

board = json.load(open("$BOARD"))
tasks = board['tasks']
sf = "$STATUS_FILTER".lower()

done_types = {"done", "closed"}
if sf:
    tasks = [t for t in tasks if t['status']['status'].lower() == sf]
else:
    tasks = [t for t in tasks if t['status']['type'] not in done_types]

if not tasks:
    print("📋 No tasks found.")
else:
    print(f"📋 Clawban — {len(tasks)} task(s)")
    print()
    for t in tasks:
        pri = t.get('priority',{}).get('priority','')
        pri_icon = {'urgent':'🔴','high':'🟠','normal':'🟡','low':'🔵'}.get(pri, '⚪')
        assignees = ', '.join(t.get('assignees',[])) or 'unassigned'
        status = t['status']['status']
        print(f"  {pri_icon} {t['id']}  [{status}]  {t['name']}")
        print(f"     → {assignees}")
PYEOF
    ;;

  my)
    shift
    AGENT="${1:?Usage: cli.sh my <agent_id>}"
    python3 << PYEOF
import json

board = json.load(open("$BOARD"))
done_types = {"done", "closed"}
tasks = [t for t in board['tasks'] if "$AGENT" in t.get('assignees',[]) and t['status']['type'] not in done_types]

if not tasks:
    print(f"📋 No open tasks for $AGENT")
else:
    print(f"📋 Tasks for $AGENT — {len(tasks)} task(s)")
    print()
    def pri_sort(t):
        p = t.get('priority',{}).get('id')
        return p if p else 99
    tasks.sort(key=pri_sort)
    for t in tasks:
        pri = t.get('priority',{}).get('priority','')
        pri_icon = {'urgent':'🔴','high':'🟠','normal':'🟡','low':'🔵'}.get(pri, '⚪')
        status = t['status']['status']
        print(f"  {pri_icon} {t['id']}  [{status}]  {t['name']}")
        if t.get('comments'):
            last = t['comments'][-1]
            print(f"     💬 {last['author']}: {last['text'][:60]}")
PYEOF
    ;;

  view)
    shift
    TASK_ID="${1:?Usage: cli.sh view <task_id>}"
    python3 << PYEOF
import json

board = json.load(open("$BOARD"))
task = next((t for t in board['tasks'] if t['id'] == "$TASK_ID"), None)
if not task:
    print(f"❌ Task $TASK_ID not found")
    exit(1)

pri = task.get('priority',{}).get('priority','none')
print(f"{'='*50}")
print(f"  {task['id']}: {task['name']}")
print(f"{'='*50}")
print(f"  Status:    {task['status']['status']}")
print(f"  Priority:  {pri}")
print(f"  Assigned:  {', '.join(task.get('assignees',[])) or 'unassigned'}")
print(f"  Creator:   {task.get('creator','?')}")
print(f"  Tags:      {', '.join(task.get('tags',[])) or 'none'}")
print(f"  Created:   {task.get('date_created','?')}")
print(f"  Updated:   {task.get('date_updated','?')}")
if task.get('due_date'):
    print(f"  Due:       {task['due_date']}")
if task.get('parent'):
    print(f"  Parent:    {task['parent']}")
if task.get('source') == 'clickup':
    print(f"  ClickUp:   {task.get('source_id','?')}")
print()
if task.get('description'):
    print(f"  Description:")
    print(f"  {task['description']}")
    print()
if task.get('comments'):
    print(f"  Comments ({len(task['comments'])}):")
    for c in task['comments']:
        print(f"    [{c['at']}] {c['author']}: {c['text']}")
PYEOF
    ;;

  status)
    shift
    TASK_ID="${1:?Usage: cli.sh status <task_id> <new_status>}"
    NEW_STATUS="${2:?Usage: cli.sh status <task_id> <new_status>}"
    AGENT="${3:-system}"

    python3 << PYEOF
import json
from datetime import datetime, timezone

board = json.load(open("$BOARD"))
status_types = $STATUS_TYPES

task = next((t for t in board['tasks'] if t['id'] == "$TASK_ID"), None)
if not task:
    print(f"❌ Task $TASK_ID not found")
    exit(1)

old_status = task['status']['status']
new_status = "$NEW_STATUS".lower()
stype = status_types.get(new_status, "custom")
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

task['status'] = {"status": new_status, "type": stype}
task['date_updated'] = now
if stype in ("done", "closed"):
    task['date_closed'] = now

json.dump(board, open("$BOARD", "w"), indent=2)
print(f"✅ {task['id']}: {old_status} → {new_status}")
PYEOF

    log_activity "$AGENT" "status_change" "$TASK_ID" "$NEW_STATUS"
    ;;

  comment)
    shift
    TASK_ID="${1:?Usage: cli.sh comment <task_id> \"comment text\" [agent]}"
    TEXT="${2:?Usage: cli.sh comment <task_id> \"comment text\" [agent]}"
    AGENT="${3:-system}"

    python3 << PYEOF
import json
from datetime import datetime, timezone

board = json.load(open("$BOARD"))
task = next((t for t in board['tasks'] if t['id'] == "$TASK_ID"), None)
if not task:
    print(f"❌ Task $TASK_ID not found")
    exit(1)

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
task['comments'].append({"author": "$AGENT", "text": """$TEXT""", "at": now})
task['date_updated'] = now

json.dump(board, open("$BOARD", "w"), indent=2)
print(f"💬 {task['id']}: comment added by $AGENT")
PYEOF

    log_activity "$AGENT" "commented" "$TASK_ID" "$TEXT"
    ;;

  assign)
    shift
    TASK_ID="${1:?Usage: cli.sh assign <task_id> <agent_id>}"
    NEW_AGENT="${2:?Usage: cli.sh assign <task_id> <agent_id>}"

    python3 << PYEOF
import json
from datetime import datetime, timezone

board = json.load(open("$BOARD"))
task = next((t for t in board['tasks'] if t['id'] == "$TASK_ID"), None)
if not task:
    print(f"❌ Task $TASK_ID not found")
    exit(1)

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
if "$NEW_AGENT" not in task['assignees']:
    task['assignees'] = ["$NEW_AGENT"]
task['date_updated'] = now

json.dump(board, open("$BOARD", "w"), indent=2)
print(f"✅ {task['id']}: assigned to $NEW_AGENT")
PYEOF

    log_activity "system" "assigned" "$TASK_ID" "$NEW_AGENT"
    ;;

  priority)
    shift
    TASK_ID="${1:?Usage: cli.sh priority <task_id> <1-4>}"
    PRI="${2:?Usage: cli.sh priority <task_id> <1-4>}"

    python3 << PYEOF
import json
from datetime import datetime, timezone

board = json.load(open("$BOARD"))
priority_map = $PRIORITY_MAP
task = next((t for t in board['tasks'] if t['id'] == "$TASK_ID"), None)
if not task:
    print(f"❌ Task $TASK_ID not found")
    exit(1)

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
pri_id = int("$PRI")
task['priority'] = {"id": pri_id, "priority": priority_map.get(str(pri_id), "normal")}
task['date_updated'] = now

json.dump(board, open("$BOARD", "w"), indent=2)
print(f"✅ {task['id']}: priority set to {task['priority']['priority']}")
PYEOF

    log_activity "system" "priority_change" "$TASK_ID" "$PRI"
    ;;

  pick)
    shift
    AGENT="${1:?Usage: cli.sh pick <agent_id>}"

    python3 << PYEOF
import json
from datetime import datetime, timezone

board = json.load(open("$BOARD"))
open_statuses = {"to do", "backlog", "planning"}
candidates = [t for t in board['tasks']
    if "$AGENT" in t.get('assignees',[])
    and t['status']['status'] in open_statuses]

if not candidates:
    print(f"📋 No ready tasks for $AGENT to pick")
    exit(0)

def pri_sort(t):
    p = t.get('priority',{}).get('id')
    return p if p else 99
candidates.sort(key=pri_sort)

task = candidates[0]
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
task['status'] = {"status": "in progress", "type": "custom"}
task['date_updated'] = now

json.dump(board, open("$BOARD", "w"), indent=2)
print(f"🎯 Picked: {task['id']}: {task['name']}")
print(f"   Priority: {task.get('priority',{}).get('priority','none')} | Status: in progress")
PYEOF

    log_activity "$AGENT" "picked" "$(python3 -c "
import json
board = json.load(open('$BOARD'))
for t in board['tasks']:
    if '$AGENT' in t.get('assignees',[]) and t['status']['status'] == 'in progress':
        print(t['id']); break
")" "auto-picked"
    ;;

  feed)
    shift
    LAST="${2:-20}"
    if [ "$1" = "--last" ]; then LAST="$2"; fi

    tail -n "${LAST}" "$ACTIVITY" 2>/dev/null | python3 -c "
import sys, json
lines = sys.stdin.readlines()
if not lines:
    print('📜 No activity yet')
else:
    print(f'📜 Activity feed (last {len(lines)} entries)')
    print()
    for line in lines:
        try:
            e = json.loads(line)
            print(f'  [{e[\"timestamp\"][:16]}] {e[\"agent\"]:>6} {e[\"action\"]:>15}  {e.get(\"task_id\",\"\")}  {e.get(\"detail\",\"\")[:50]}')
        except:
            pass
"
    ;;

  pull-clickup)
    shift
    CU_TASK_ID="${1:?Usage: cli.sh pull-clickup <clickup_task_id>}"
    
    if ! which curl >/dev/null 2>&1; then
      echo "❌ curl not found - required for ClickUp sync"
      exit 1
    fi
    
    CLICKUP_KEY="${CLICKUP_API_KEY:-$(python3 -c "import json,os; print(json.load(open(os.path.expanduser('~/.openclaw/openclaw.json'))).get('env',{}).get('vars',{}).get('CLICKUP_API_KEY',''))" 2>/dev/null)}"
    
    if [ -z "$CLICKUP_KEY" ]; then
      echo "❌ CLICKUP_API_KEY not set"
      exit 1
    fi

    TASK_JSON=$(curl -sf "https://api.clickup.com/api/v2/task/$CU_TASK_ID" -H "Authorization: $CLICKUP_KEY")

    python3 << PYEOF
import json
from datetime import datetime, timezone

board = json.load(open("$BOARD"))
cu = json.loads('''$TASK_JSON''')

existing = next((t for t in board['tasks'] if t.get('source_id') == cu['id']), None)
if existing:
    print(f"⚠️  Already imported as {existing['id']}")
    exit(0)

task_id = f"CU-{cu['id']}"
now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def ms_to_iso(ms):
    if not ms: return None
    return datetime.fromtimestamp(int(ms)/1000, tz=timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

assignees = []
for a in cu.get('assignees', []):
    if a.get('id') == 84844111:
        assignees.append('zeugh')
    else:
        assignees.append(str(a.get('username', a.get('id',''))))

pri = cu.get('priority')
pri_obj = {"id": int(pri['id']), "priority": pri['priority']} if pri else {"id": None, "priority": None}

status = cu.get('status', {})
status_types = $STATUS_TYPES

task = {
    "id": task_id,
    "source": "clickup",
    "source_id": cu['id'],
    "name": cu.get('name', ''),
    "description": cu.get('text_content', ''),
    "status": {"status": status.get('status','to do').lower().lstrip('[0123456789] '), "type": status_types.get(status.get('status','').lower(), 'custom')},
    "priority": pri_obj,
    "assignees": assignees,
    "creator": "clickup",
    "tags": [t.get('name','') for t in cu.get('tags', [])],
    "parent": f"CU-{cu['parent']}" if cu.get('parent') else None,
    "due_date": ms_to_iso(cu.get('due_date')),
    "start_date": ms_to_iso(cu.get('start_date')),
    "date_created": ms_to_iso(cu.get('date_created')) or now,
    "date_updated": ms_to_iso(cu.get('date_updated')) or now,
    "date_closed": ms_to_iso(cu.get('date_closed')),
    "dependencies": [],
    "checklists": [],
    "custom_fields": cu.get('custom_fields', []),
    "comments": []
}

board['tasks'].append(task)
json.dump(board, open("$BOARD", "w"), indent=2)
print(f"✅ Imported {task_id}: {task['name']}")
print(f"   Status: {task['status']['status']} | Assigned: {', '.join(assignees)}")
PYEOF

    log_activity "system" "imported_clickup" "CU-$CU_TASK_ID" "Imported from ClickUp"
    ;;

  push-clickup)
    shift
    TASK_ID="${1:?Usage: cli.sh push-clickup <task_id>}"
    
    if ! which curl >/dev/null 2>&1; then
      echo "❌ curl not found - required for ClickUp sync"
      exit 1
    fi
    
    CLICKUP_KEY="${CLICKUP_API_KEY:-$(python3 -c "import json,os; print(json.load(open(os.path.expanduser('~/.openclaw/openclaw.json'))).get('env',{}).get('vars',{}).get('CLICKUP_API_KEY',''))" 2>/dev/null)}"
    
    if [ -z "$CLICKUP_KEY" ]; then
      echo "❌ CLICKUP_API_KEY not set"
      exit 1
    fi

    python3 << PYEOF
import json

board = json.load(open("$BOARD"))
task = next((t for t in board['tasks'] if t['id'] == "$TASK_ID"), None)
if not task:
    print(f"❌ Task $TASK_ID not found")
    exit(1)
if task.get('source') != 'clickup':
    print(f"❌ Task {task['id']} is not from ClickUp (source: {task.get('source')})")
    exit(1)

import subprocess
result = subprocess.run([
    'curl', '-sf', '-X', 'PUT',
    f"https://api.clickup.com/api/v2/task/{task['source_id']}",
    '-H', f"Authorization: $CLICKUP_KEY",
    '-H', 'Content-Type: application/json',
    '-d', json.dumps({"status": task['status']['status']})
], capture_output=True, text=True)

if result.returncode == 0:
    print(f"✅ Synced {task['id']} → ClickUp ({task['source_id']}): {task['status']['status']}")
else:
    print(f"❌ Sync failed: {result.stderr}")
PYEOF

    log_activity "system" "pushed_clickup" "$TASK_ID" "Synced to ClickUp"
    ;;

  help|*)
    echo "🦞 Clawban — Multi-Agent Kanban Board"
    echo ""
    echo "Commands:"
    echo "  add <title> [--assign X] [--priority 1-4] [--creator X] [--status X] [--tags a,b] [--description X] [--parent X] [--due X]"
    echo "  list [status]          List open tasks (or filter by status)"
    echo "  my <agent>             Show tasks assigned to agent"
    echo "  view <task_id>         Show task detail"
    echo "  status <id> <status>   Update task status"
    echo "  comment <id> <text> [agent]  Add comment"
    echo "  assign <id> <agent>    Reassign task"
    echo "  priority <id> <1-4>    Set priority"
    echo "  pick <agent>           Pick highest-priority ready task"
    echo "  feed [--last N]        Show activity feed"
    echo "  pull-clickup <cu_id>   Import task from ClickUp"
    echo "  push-clickup <id>      Sync status back to ClickUp"
    echo "  help                   This help"
    echo ""
    echo "Storage: $BOARD"
    ;;

esac
