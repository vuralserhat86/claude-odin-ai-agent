#!/bin/bash
# agent.sh - Run an individual agent

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Base directory
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$AGENT_DIR/config/agents.json"

# Show usage
usage() {
    echo "Usage: $0 <agent-id> <task-json>"
    echo ""
    echo "Available agents:"
    jq -r '.agents[] | "  \(.id) - \(.name)"' "$CONFIG"
    echo ""
    echo "Example:"
    echo "  $0 frontend '{\"id\":\"task-1\",\"title\":\"Create login form\",\"type\":\"development\"}'"
    exit 1
}

# Check arguments
if [ $# -lt 2 ]; then
    usage
fi

AGENT_ID=$1
TASK_JSON=$2

# Find agent prompt file
AGENT_PROMPT=$(jq -r ".agents[] | select(.id == \"$AGENT_ID\") | .promptFile" "$CONFIG")

if [ -z "$AGENT_PROMPT" ] || [ ! -f "$AGENT_DIR/$AGENT_PROMPT" ]; then
    echo -e "${RED}Error: Agent '$AGENT_ID' not found${NC}"
    usage
fi

PROMPT_FILE="$AGENT_DIR/$AGENT_PROMPT"

echo "================================"
echo "Running Agent: $AGENT_ID"
echo "================================"
echo ""
echo "Prompt: $PROMPT_FILE"
echo "Task: $TASK_JSON"
echo ""

# In a real implementation, this would:
# 1. Load the agent prompt
# 2. Add the task context
# 3. Call the LLM API
# 4. Process and return results

echo -e "${YELLOW}This is a placeholder script.${NC}"
echo -e "${YELLOW}In production, this would call the LLM with the agent prompt and task.${NC}"
echo ""

# Show the agent prompt preview
echo "================================"
echo "Agent Prompt Preview (first 20 lines)"
echo "================================"
head -n 20 "$PROMPT_FILE"
echo "..."
echo ""

# Read task JSON
echo "================================"
echo "Task Details"
echo "================================"
echo "$TASK_JSON" | jq '.'
echo ""
