#!/bin/bash
# clean.sh - Clean state files (reset the system)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Base directory
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "================================"
echo "Cleaning Agent System State"
echo "================================"
echo ""
echo -e "${YELLOW}This will reset all state files.${NC}"
echo "Tasks, memory, and logs will be cleared."
echo ""
read -p "Are you sure? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo "Cleaning state files..."

# Remove state files
rm -f "$AGENT_DIR/state/orchestrator.json"
rm -f "$AGENT_DIR/state/tasks-pending.json"
rm -f "$AGENT_DIR/state/tasks-in-progress.json"
rm -f "$AGENT_DIR/state/tasks-completed.json"
rm -f "$AGENT_DIR/state/tasks-failed.json"
rm -f "$AGENT_DIR/state/tasks-dead-letter.json"
rm -f "$AGENT_DIR/state/memory.json"
rm -f "$AGENT_DIR/state/agents.json"

# Remove logs
rm -rf "$AGENT_DIR/logs"/*
rm -f "$AGENT_DIR/logs"/*.log 2>/dev/null || true

echo -e "${GREEN}State cleaned.${NC}"
echo ""
echo "Run ./scripts/bootstrap.sh to reinitialize."
