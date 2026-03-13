#!/bin/bash

echo "🦞 Clawban Quick Start"
echo "====================="
echo ""

# Check if config exists
if [ ! -f "config.json" ]; then
  echo "📝 Creating config.json from example..."
  if [ -f "config.example.json" ]; then
    cp config.example.json config.json
    echo "✅ config.json created"
    echo ""
    echo "⚠️  Please edit config.json to configure your agents:"
    echo "   nano config.json"
    echo ""
    echo "   Or continue with example configuration (3 agents)"
    read -p "Press Enter to continue..."
  else
    echo "❌ config.example.json not found"
    exit 1
  fi
fi

# Check if board.json exists
if [ ! -f "board.json" ]; then
  echo "📋 Creating empty board..."
  cat > board.json << 'EOF'
{
  "nextId": 1,
  "tasks": []
}
EOF
  echo "✅ board.json created"
fi

# Check if activity.jsonl exists
if [ ! -f "activity.jsonl" ]; then
  echo "📊 Creating activity log..."
  touch activity.jsonl
  echo "✅ activity.jsonl created"
fi

# Check Node.js
if ! command -v node &> /dev/null; then
  echo "❌ Node.js not found"
  echo "   Install Node.js from https://nodejs.org"
  exit 1
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "🚀 Starting dashboard..."
echo ""

# Start server
cd web
node server-simple.js
