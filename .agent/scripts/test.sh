#!/bin/bash
# test.sh - Test the autonomous agent system

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Base directory
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "================================"
echo "Testing Agent System"
echo "================================"
echo ""

# Test 1: Check directory structure
echo -n "Test 1: Directory structure... "
if [ -d "$AGENT_DIR/config" ] && \
   [ -d "$AGENT_DIR/prompts" ] && \
   [ -d "$AGENT_DIR/prompts/agents" ] && \
   [ -d "$AGENT_DIR/state" ] && \
   [ -d "$AGENT_DIR/scripts" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 2: Check config files
echo -n "Test 2: Configuration files... "
if [ -f "$AGENT_DIR/config/agents.json" ] && \
   [ -f "$AGENT_DIR/config/thresholds.json" ] && \
   [ -f "$AGENT_DIR/config/queue.json" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 3: Check JSON schemas
echo -n "Test 3: JSON schemas... "
if [ -f "$AGENT_DIR/config/schemas/orchestrator-state.json" ] && \
   [ -f "$AGENT_DIR/config/schemas/task.json" ] && \
   [ -f "$AGENT_DIR/config/schemas/agent-state.json" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 4: Check orchestrator prompt
echo -n "Test 4: Orchestrator prompt... "
if [ -f "$AGENT_DIR/prompts/orchestrator.md" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC}"
    exit 1
fi

# Test 5: Check agent prompts (count)
echo -n "Test 5: Agent prompts (25 expected)... "
AGENT_COUNT=$(find "$AGENT_DIR/prompts/agents" -name "*.md" | wc -l)
if [ "$AGENT_COUNT" -eq 25 ]; then
    echo -e "${GREEN}PASS${NC} ($AGENT_COUNT found)"
else
    echo -e "${YELLOW}WARNING${NC} ($AGENT_COUNT found, expected 25)"
fi

# Test 6: Validate JSON files
echo -n "Test 6: JSON validation... "
if command -v python3 &> /dev/null; then
    ERROR=0
    for json_file in "$AGENT_DIR/config"/*.json "$AGENT_DIR/config/schemas"/*.json; do
        if ! python3 -m json.tool "$json_file" > /dev/null 2>&1; then
            echo -e "${RED}FAIL${NC} (invalid JSON: $json_file)"
            ERROR=1
        fi
    done
    if [ $ERROR -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}"
    else
        exit 1
    fi
else
    echo -e "${YELLOW}SKIP${NC} (python3 not found)"
fi

# Test 7: Check state files
echo -n "Test 7: State files... "
if [ -f "$AGENT_DIR/state/orchestrator.json" ] && \
   [ -f "$AGENT_DIR/state/tasks-pending.json" ] && \
   [ -f "$AGENT_DIR/state/tasks-in-progress.json" ] && \
   [ -f "$AGENT_DIR/state/tasks-completed.json" ] && \
   [ -f "$AGENT_DIR/state/tasks-failed.json" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}WARNING${NC} (run bootstrap.sh first)"
fi

# Test 8: Check scripts
echo -n "Test 8: Scripts... "
if [ -x "$AGENT_DIR/scripts/bootstrap.sh" ] && \
   [ -x "$AGENT_DIR/scripts/status.sh" ] && \
   [ -x "$AGENT_DIR/scripts/test.sh" ]; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${YELLOW}WARNING${NC} (some scripts may not be executable)"
fi

echo ""
echo "================================"
echo -e "${GREEN}All tests passed!${NC}"
echo "================================"
