#!/bin/bash
# checkpoint.sh - Checkpoint management

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Base directory
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Checkpoint directory
CHECKPOINT_DIR="$AGENT_DIR/state/checkpoints"

# Show usage
usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  create          Create a new checkpoint"
    echo "  list            List all checkpoints"
    echo "  restore <id>    Restore from checkpoint"
    echo "  delete <id>     Delete a checkpoint"
    echo "  auto            Auto-checkpoint (runs every 5 tasks)"
    echo ""
    echo "Examples:"
    echo "  $0 create"
    echo "  $0 list"
    echo "  $0 restore checkpoint-1705310400"
    exit 1
}

# Create a checkpoint
create_checkpoint() {
    local TIMESTAMP=$(date +%s)
    local CHECKPOINT_ID="checkpoint-$TIMESTAMP"
    local CHECKPOINT_FILE="$CHECKPOINT_DIR/$CHECKPOINT_ID.json"

    mkdir -p "$CHECKPOINT_DIR"

    echo "Creating checkpoint: $CHECKPOINT_ID"

    # Gather all state
    cat > "$CHECKPOINT_FILE" <<EOF
{
  "id": "$CHECKPOINT_ID",
  "timestamp": "$TIMESTAMP",
  "datetime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "orchestrator": $(cat "$AGENT_DIR/state/orchestrator.json" 2>/dev/null || echo '{}'),
  "pending": $(cat "$AGENT_DIR/state/tasks-pending.json" 2>/dev/null || echo '{"tasks":[]}'),
  "inProgress": $(cat "$AGENT_DIR/state/tasks-in-progress.json" 2>/dev/null || echo '{"tasks":[]}'),
  "completed": $(cat "$AGENT_DIR/state/tasks-completed.json" 2>/dev/null || echo '{"tasks":[]}'),
  "failed": $(cat "$AGENT_DIR/state/tasks-failed.json" 2>/dev/null || echo '{"tasks":[]}'),
  "agents": $(cat "$AGENT_DIR/state/agents.json" 2>/dev/null || echo '{}'),
  "memory": $(cat "$AGENT_DIR/state/memory.json" 2>/dev/null || echo '{}')
}
EOF

    echo -e "${GREEN}✓ Checkpoint created${NC}"
    echo "  File: $CHECKPOINT_FILE"
}

# List checkpoints
list_checkpoints() {
    echo "================================"
    echo "Checkpoints"
    echo "================================"
    echo ""

    if [ ! -d "$CHECKPOINT_DIR" ] || [ -z "$(ls -A $CHECKPOINT_DIR 2>/dev/null)" ]; then
        echo "No checkpoints found."
        return
    fi

    for file in "$CHECKPOINT_DIR"/checkpoint-*.json; do
        if [ -f "$file" ]; then
            local ID=$(jq -r '.id' "$file")
            local DATETIME=$(jq -r '.datetime' "$file")
            local COMPLETED=$(jq -r '.completed.tasks | length' "$file")
            local FAILED=$(jq -r '.failed.tasks | length' "$file")

            echo "  $ID"
            echo "    Time: $DATETIME"
            echo "    Completed: $COMPLETED, Failed: $FAILED"
            echo ""
        fi
    done
}

# Restore from checkpoint
restore_checkpoint() {
    local CHECKPOINT_ID="$1"
    local CHECKPOINT_FILE="$CHECKPOINT_DIR/$CHECKPOINT_ID.json"

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        echo -e "${RED}Checkpoint not found: $CHECKPOINT_ID${NC}"
        echo "Run '$0 list' to see available checkpoints."
        exit 1
    fi

    echo "Restoring from checkpoint: $CHECKPOINT_ID"
    echo ""

    # Restore orchestrator state
    jq '.orchestrator' "$CHECKPOINT_FILE" > "$AGENT_DIR/state/orchestrator.json"

    # Restore task queues
    jq '.pending' "$CHECKPOINT_FILE" > "$AGENT_DIR/state/tasks-pending.json"
    jq '.inProgress' "$CHECKPOINT_FILE" > "$AGENT_DIR/state/tasks-in-progress.json"
    jq '.completed' "$CHECKPOINT_FILE" > "$AGENT_DIR/state/tasks-completed.json"
    jq '.failed' "$CHECKPOINT_FILE" > "$AGENT_DIR/state/tasks-failed.json"

    # Restore agent states
    jq '.agents' "$CHECKPOINT_FILE" > "$AGENT_DIR/state/agents.json"

    # Restore memory
    jq '.memory' "$CHECKPOINT_FILE" > "$AGENT_DIR/state/memory.json"

    echo -e "${GREEN}✓ Checkpoint restored${NC}"
    echo ""
    echo "State has been restored to:"
    local DATETIME=$(jq -r '.datetime' "$CHECKPOINT_FILE")
    echo "  $DATETIME"
}

# Delete a checkpoint
delete_checkpoint() {
    local CHECKPOINT_ID="$1"
    local CHECKPOINT_FILE="$CHECKPOINT_DIR/$CHECKPOINT_ID.json"

    if [ ! -f "$CHECKPOINT_FILE" ]; then
        echo -e "${RED}Checkpoint not found: $CHECKPOINT_ID${NC}"
        exit 1
    fi

    rm "$CHECKPOINT_FILE"
    echo -e "${GREEN}✓ Checkpoint deleted: $CHECKPOINT_ID${NC}"
}

# Auto-checkpoint (every N tasks)
auto_checkpoint() {
    local INTERVAL=5  # Checkpoint every 5 tasks

    # Get current completed count
    local COMPLETED=$(jq '.completed.tasks | length' "$AGENT_DIR/state/tasks-completed.json" 2>/dev/null || echo "0")

    # Get last checkpoint count
    local LAST_COUNT=0
    if [ -f "$AGENT_DIR/state/.last-checkpoint" ]; then
        LAST_COUNT=$(cat "$AGENT_DIR/state/.last-checkpoint")
    fi

    # Check if we've crossed the interval
    local DIFF=$((COMPLETED - LAST_COUNT))

    if [ "$DIFF" -ge "$INTERVAL" ]; then
        create_checkpoint
        echo "$COMPLETED" > "$AGENT_DIR/state/.last-checkpoint"
    else
        local REMAINING=$((INTERVAL - DIFF))
        echo "Next checkpoint in $REMAINING tasks"
    fi
}

# Main
case "${1:-}" in
    create)
        create_checkpoint
        ;;
    list)
        list_checkpoints
        ;;
    restore)
        if [ -z "$2" ]; then
            echo "Usage: $0 restore <checkpoint-id>"
            exit 1
        fi
        restore_checkpoint "$2"
        ;;
    delete)
        if [ -z "$2" ]; then
            echo "Usage: $0 delete <checkpoint-id>"
            exit 1
        fi
        delete_checkpoint "$2"
        ;;
    auto)
        auto_checkpoint
        ;;
    *)
        usage
        ;;
esac
