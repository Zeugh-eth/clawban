#!/bin/bash
# Clawban Installation Script

set -e

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🦞 Clawban Installation"
echo "Skill directory: $SKILL_ROOT"
echo ""

# 1. Initialize storage
echo "📦 Initializing storage..."
if [ ! -f "$SKILL_ROOT/board.json" ]; then
    echo '{"version":1,"next_id":1,"tasks":[]}' > "$SKILL_ROOT/board.json"
    echo "  ✅ Created board.json"
else
    echo "  ⏭️  board.json exists"
fi

if [ ! -f "$SKILL_ROOT/activity.jsonl" ]; then
    touch "$SKILL_ROOT/activity.jsonl"
    echo "  ✅ Created activity.jsonl"
else
    echo "  ⏭️  activity.jsonl exists"
fi

# 2. Make scripts executable
echo ""
echo "🔧 Making scripts executable..."
chmod +x "$SKILL_ROOT"/scripts/*.sh
chmod +x "$SKILL_ROOT/install.sh"
echo "  ✅ Scripts ready"

# 3. Show AGENTS.md integration
echo ""
echo "📋 Add this to your AGENTS.md:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat << 'AGENTS_SNIPPET'
## 🦞 Clawban — Inter-Agent Task Board

Check Clawban at session start:

```bash
CLI="path/to/clawban/scripts/cli.sh"
$CLI my <your_agent_id>
$CLI feed --last 10
```

Workflow: check tasks → scan feed → pick/continue → work → update → done

Creating tasks:
```bash
$CLI add "Task title" --assign <agent> --priority 1-4 --creator <your_id>
```

See: clawban/SKILL.md for full documentation
AGENTS_SNIPPET
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

#  4. Optional web server
echo ""
if [ "$1" = "--start-web" ] || [ "$1" = "-w" ]; then
    echo "🌐 Starting web server..."
    if ! which node >/dev/null 2>&1; then
        echo "  ❌ Node.js not found - install it to use the web interface"
        exit 1
    fi
    
    cd "$SKILL_ROOT/web"
    echo "  Starting on http://localhost:18793"
    nohup node server.js > /tmp/clawban-web.log 2>&1 &
    echo "  ✅ Server started (PID: $!)"
    echo "  View logs: tail -f /tmp/clawban-web.log"
else
    echo "ℹ️  Web server NOT started (optional)"
    echo "   To start: cd $SKILL_ROOT/web && node server.js"
    echo "   Or: ./install.sh --start-web"
fi

echo ""
echo "✨ Installation complete!"
echo ""
echo "Quick start:"
echo "  $SKILL_ROOT/scripts/cli.sh help"
echo "  $SKILL_ROOT/scripts/cli.sh add \"My first task\" --assign myagent"
echo ""
