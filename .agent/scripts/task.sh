#!/bin/bash
# task.sh - Task management utility

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Base directory
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# State files
PENDING="$AGENT_DIR/state/tasks-pending.json"
IN_PROGRESS="$AGENT_DIR/state/tasks-in-progress.json"
COMPLETED="$AGENT_DIR/state/tasks-completed.json"
FAILED="$AGENT_DIR/state/tasks-failed.json"
DEAD_LETTER="$AGENT_DIR/state/tasks-dead-letter.json"

# Show usage
usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  add <json>      Add a new task to pending queue"
    echo "  list <queue>    List tasks in a queue"
    echo "  show <id>       Show task details"
    echo "  move <id> <to>  Move task to another queue"
    echo "  delete <id>     Delete a task"
    echo ""
    echo "Queues: pending, in-progress, completed, failed, dead-letter"
    echo ""
    echo "Examples:"
    echo '  $0 add '"'"'{"title":"Create login form","type":"development"}'"'"
    echo "  $0 list pending"
    echo "  $0 show task-001"
    echo "  $0 move task-001 completed"
    exit 1
}

# Add a new task
add_task() {
    local JSON="$1"

    # Validate JSON
    if ! echo "$JSON" | jq . > /dev/null 2>&1; then
        echo -e "${RED}Error: Invalid JSON${NC}"
        exit 1
    fi

    # Add required fields if missing
    TASK=$(echo "$JSON" | jq '{
        id: (.id // "task-" + (now | tostring | split(".")[0] + tostring)),
        title: .title,
        type: (.type // "development"),
        priority: (.priority // "medium"),
        status: "pending",
        dependencies: (.dependencies // []),
        context: (.context // {}),
        attempts: 0,
        createdAt: (now | tostring + "Z" | sub("\\.[0-9]+"; "") | sub("T"; "T") + "Z")
    }')

    # Add to pending queue
    jq ".tasks += [$TASK]" "$PENDING" > "$PENDING.tmp"
    mv "$PENDING.tmp" "$PENDING"

    TASK_ID=$(echo "$TASK" | jq -r '.id')
    echo -e "${GREEN}✓ Task added: $TASK_ID${NC}"
}

# List tasks in a queue
list_tasks() {
    local QUEUE="$1"
    local FILE=""

    case $QUEUE in
        pending) FILE="$PENDING" ;;
        in-progress|in_progress) FILE="$IN_PROGRESS" ;;
        completed) FILE="$COMPLETED" ;;
        failed) FILE="$FAILED" ;;
        dead-letter|dead_letter) FILE="$DEAD_LETTER" ;;
        *)
            echo -e "${RED}Unknown queue: $QUEUE${NC}"
            echo "Available: pending, in-progress, completed, failed, dead-letter"
            exit 1
            ;;
    esac

    if [ ! -f "$FILE" ]; then
        echo "Queue file not found. Run bootstrap.sh first."
        exit 1
    fi

    echo "================================"
    echo "Tasks in $QUEUE queue"
    echo "================================"
    echo ""

    COUNT=$(jq '.tasks | length' "$FILE")

    if [ "$COUNT" -eq 0 ]; then
        echo "No tasks."
        return
    fi

    jq -r '.tasks[] | "\(.id): \(.title)\n  Type: \(.type)\n  Priority: \(.priority)\n  Status: \(.status)\n"' "$FILE"
}

# Show task details
show_task() {
    local TASK_ID="$1"
    local FOUND=""

    # Search all queues
    for FILE in "$PENDING" "$IN_PROGRESS" "$COMPLETED" "$FAILED" "$DEAD_LETTER"; do
        if [ -f "$FILE" ]; then
            TASK=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\")" "$FILE" 2>/dev/null)
            if [ -n "$TASK" ]; then
                FOUND="$TASK"
                break
            fi
        fi
    done

    if [ -z "$FOUND" ]; then
        echo -e "${RED}Task not found: $TASK_ID${NC}"
        exit 1
    fi

    echo "================================"
    echo "Task Details: $TASK_ID"
    echo "================================"
    echo ""
    echo "$FOUND" | jq '.'
}

# Move task to another queue
move_task() {
    local TASK_ID="$1"
    local TARGET_QUEUE="$2"
    local SOURCE_FILE=""
    local TARGET_FILE=""

    # Determine target file
    case $TARGET_QUEUE in
        pending) TARGET_FILE="$PENDING" ;;
        in-progress|in_progress) TARGET_FILE="$IN_PROGRESS" ;;
        completed) TARGET_FILE="$COMPLETED" ;;
        failed) TARGET_FILE="$FAILED" ;;
        dead-letter|dead_letter) TARGET_FILE="$DEAD_LETTER" ;;
        *)
            echo -e "${RED}Unknown queue: $TARGET_QUEUE${NC}"
            exit 1
            ;;
    esac

    # Find source queue
    for FILE in "$PENDING" "$IN_PROGRESS" "$COMPLETED" "$FAILED" "$DEAD_LETTER"; do
        if [ -f "$FILE" ]; then
            TASK=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\")" "$FILE" 2>/dev/null)
            if [ -n "$TASK" ]; then
                SOURCE_FILE="$FILE"
                break
            fi
        fi
    done

    if [ -z "$SOURCE_FILE" ]; then
        echo -e "${RED}Task not found: $TASK_ID${NC}"
        exit 1
    fi

    # Remove from source
    jq "(.tasks |= map(select(.id != \"$TASK_ID\"))) | (.updatedAt = now)" "$SOURCE_FILE" > "$SOURCE_FILE.tmp"
    mv "$SOURCE_FILE.tmp" "$SOURCE_FILE"

    # Add to target with updated status
    UPDATED_TASK=$(echo "$TASK" | jq ".status = \"$TARGET_QUEUE\" | .updatedAt = now")

    if [ "$TARGET_QUEUE" = "completed" ]; then
        UPDATED_TASK=$(echo "$UPDATED_TASK" | jq ".completedAt = now")
    fi

    jq ".tasks += [$UPDATED_TASK] | .updatedAt = now" "$TARGET_FILE" > "$TARGET_FILE.tmp"
    mv "$TARGET_FILE.tmp" "$TARGET_FILE"

    echo -e "${GREEN}✓ Task $TASK_ID moved to $TARGET_QUEUE${NC}"
}

# Delete a task
delete_task() {
    local TASK_ID="$1"
    local SOURCE_FILE=""

    # Find source queue
    for FILE in "$PENDING" "$IN_PROGRESS" "$COMPLETED" "$FAILED" "$DEAD_LETTER"; do
        if [ -f "$FILE" ]; then
            TASK=$(jq -r ".tasks[] | select(.id == \"$TASK_ID\")" "$FILE" 2>/dev/null)
            if [ -n "$TASK" ]; then
                SOURCE_FILE="$FILE"
                break
            fi
        fi
    done

    if [ -z "$SOURCE_FILE" ]; then
        echo -e "${RED}Task not found: $TASK_ID${NC}"
        exit 1
    fi

    # Remove from queue
    jq "(.tasks |= map(select(.id != \"$TASK_ID\"))) | (.updatedAt = now)" "$SOURCE_FILE" > "$SOURCE_FILE.tmp"
    mv "$SOURCE_FILE.tmp" "$SOURCE_FILE"

    echo -e "${GREEN}✓ Task $TASK_ID deleted${NC}"
}

# Main
case "${1:-}" in
    add)
        if [ -z "$2" ]; then
            echo "Usage: $0 add <json>"
            exit 1
        fi
        add_task "$2"
        ;;
    list)
        if [ -z "$2" ]; then
            echo "Usage: $0 list <queue>"
            exit 1
        fi
        list_tasks "$2"
        ;;
    show)
        if [ -z "$2" ]; then
            echo "Usage: $0 show <task-id>"
            exit 1
        fi
        show_task "$2"
        ;;
    move)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 move <task-id> <queue>"
            exit 1
        fi
        move_task "$2" "$3"
        ;;
    delete)
        if [ -z "$2" ]; then
            echo "Usage: $0 delete <task-id>"
            exit 1
        fi
        delete_task "$2"
        ;;
    *)
        usage
        ;;
esac
