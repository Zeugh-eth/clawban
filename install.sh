#!/bin/bash
# Clawban Installation Script
set -euo pipefail

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "🦞 Clawban Installation"
echo "Skill directory: $SKILL_ROOT"
echo ""

if ! command -v python3 >/dev/null 2>&1; then
    echo "❌ python3 is required"
    exit 1
fi

# 1. Initialize storage
echo "📦 Initializing storage..."
python3 "$SKILL_ROOT/scripts/clawban.py" --json list >/dev/null
echo "  ✅ Storage ready"

# 2. Make scripts executable
echo ""
echo "🔧 Making scripts executable..."
chmod +x "$SKILL_ROOT"/scripts/*.sh
chmod +x "$SKILL_ROOT"/scripts/*.py
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
CLI="/root/.openclaw/shared-skills/clawban/scripts/cli.sh"
$CLI my <your_agent_id>
$CLI feed --last 10
```

Workflow: check tasks → scan feed → pick/continue → work → update → done

Creating tasks:
```bash
$CLI add "Task title" --assign <agent> --priority 1-4 --creator <your_id>
```

Automation:
```bash
$CLI --json list
```

See: `/root/.openclaw/shared-skills/clawban/SKILL.md`
AGENTS_SNIPPET
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

#  4. Optional web server
echo ""
if [ "${1:-}" = "--start-web" ] || [ "${1:-}" = "-w" ]; then
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
echo "  $SKILL_ROOT/scripts/cli.sh --help"
echo "  $SKILL_ROOT/scripts/cli.sh add \"My first task\" --assign myagent"
echo "  $SKILL_ROOT/scripts/cli.sh --json list"
echo ""
