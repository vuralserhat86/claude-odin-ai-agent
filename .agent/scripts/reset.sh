#!/bin/bash
# reset.sh - Full system reset (clean + bootstrap)

set -e

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

# Base directory
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "================================"
echo "Resetting Agent System"
echo "================================"
echo ""

# Clean first
"$AGENT_DIR/scripts/clean.sh"

# Reinitialize
echo ""
echo "Reinitializing..."
"$AGENT_DIR/scripts/bootstrap.sh"

echo ""
echo "================================"
echo -e "${GREEN}System reset complete!${NC}"
echo "================================"
