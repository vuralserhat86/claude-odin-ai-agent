#!/bin/bash
# queue.sh - Task queue management with DLQ support

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Base directory
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QUEUE_DIR="$AGENT_DIR/queue"

# Queue files
PENDING="$QUEUE_DIR/tasks-pending.json"
IN_PROGRESS="$QUEUE_DIR/tasks-in-progress.json"
COMPLETED="$QUEUE_DIR/tasks-completed.json"
FAILED="$QUEUE_DIR/tasks-failed.json"
DEAD_LETTER="$QUEUE_DIR/tasks-dead-letter.json"

# Show queue status
show_status() {
    echo "================================"
    echo "Task Queue Status"
    echo "================================"
    echo ""

    pending=$(jq '.tasks | length' "$PENDING" 2>/dev/null || echo "0")
    in_progress=$(jq '.tasks | length' "$IN_PROGRESS" 2>/dev/null || echo "0")
    completed=$(jq '.tasks | length' "$COMPLETED" 2>/dev/null || echo "0")
    failed=$(jq '.tasks | length' "$FAILED" 2>/dev/null || echo "0")
    dead_letter=$(jq '.tasks | length' "$DEAD_LETTER" 2>/dev/null || echo "0")

    echo -e "${BLUE}Pending:${NC}     $pending"
    echo -e "${BLUE}In Progress:${NC} $in_progress"
    echo -e "${GREEN}Completed:${NC}   $completed"
    echo -e "${YELLOW}Failed:${NC}      $failed"
    echo -e "${RED}Dead Letter:${NC}  $dead_letter 🔥"
    echo ""
}

# List tasks in a queue
list_queue() {
    local queue=$1
    local file=""

    case $queue in
        pending) file="$PENDING" ;;
        in-progress) file="$IN_PROGRESS" ;;
        completed) file="$COMPLETED" ;;
        failed) file="$FAILED" ;;
        dead-letter) file="$DEAD_LETTER" ;;
        *)
            echo "Unknown queue: $queue"
            echo "Available: pending, in-progress, completed, failed, dead-letter"
            exit 1
            ;;
    esac

    echo "================================"
    echo "Tasks in $queue queue"
    echo "================================"
    echo ""

    local count=$(jq '.tasks | length' "$file" 2>/dev/null || echo "0")
    echo "Total: $count task(s)"
    echo ""

    if [ "$count" -gt 0 ]; then
        jq -r '.tasks[] | "- \(.id): \(.title // .description // "No title") (Priority: \(.priority // "N/A"))"' "$file" 2>/dev/null
    else
        echo "No tasks in this queue."
    fi
    echo ""
}

# Show DLQ details
show_dlq() {
    echo "================================"
    echo "Dead Letter Queue (DLQ) Details"
    echo "================================"
    echo ""

    local count=$(jq '.tasks | length' "$DEAD_LETTER" 2>/dev/null || echo "0")

    if [ "$count" -eq 0 ]; then
        echo -e "${GREEN}✓ No tasks in DLQ!${NC}"
        echo ""
        return
    fi

    echo -e "${RED}⚠ $count task(s) in DLQ${NC}"
    echo ""

    jq -r '.tasks[] |
"────────────────────────────────────
ID: \(.id)
Type: \(.type)
Title: \(.title // "N/A")
Moved to DLQ: \(.movedAt)
Reason: \(.reason)
Retries: \(.retries)/\(.maxRetries)
Last Error: \(.lastError.message // .lastError // "N/A")
────────────────────────────────────"' "$DEAD_LETTER" 2>/dev/null

    echo ""
    echo "Suggested actions:"
    echo "  $0 dlq-review    - Review all DLQ tasks"
    echo "  $0 dlq-retry <id>   - Move task back to pending"
    echo "  $0 dlq-skip <id>    - Mark as completed (skip)"
    echo "  $0 dlq-delete <id>  - Remove from DLQ"
    echo ""
}

# Review DLQ tasks interactively
dlq_review() {
    local count=$(jq '.tasks | length' "$DEAD_LETTER" 2>/dev/null || echo "0")

    if [ "$count" -eq 0 ]; then
        echo "✓ No tasks in DLQ to review."
        return
    fi

    echo "================================"
    echo "DLQ Tasks Review"
    echo "================================"
    echo ""
    echo "Tasks requiring manual attention:"
    echo ""

    jq -r '.tasks[] |
"\(.id) | \(.type) | \(.title // "No title") | \(.lastError.message // .lastError // "No error")"' "$DEAD_LETTER" 2>/dev/null | column -t -s '|'

    echo ""
    echo "Use: $0 dlq-retry <id> | dlq-skip <id> | dlq-delete <id>"
}

# Move task from DLQ to pending
dlq_retry() {
    local task_id=$1

    if [ -z "$task_id" ]; then
        echo "Usage: $0 dlq-retry <task-id>"
        exit 1
    fi

    # Find task in DLQ
    local task=$(jq ".tasks[] | select(.id == \"$task_id\")" "$DEAD_LETTER")

    if [ -z "$task" ]; then
        echo "Error: Task $task_id not found in DLQ"
        exit 1
    fi

    echo "Moving task $task_id from DLQ to pending..."

    # Remove from DLQ and add to pending
    jq "(.tasks |= map(select(.id != \"$task_id\")))" "$DEAD_LETTER" > "$DEAD_LETTER.tmp" && mv "$DEAD_LETTER.tmp" "$DEAD_LETTER"

    # Reset retry count and move to pending
    jq "(.tasks += [$task | .retries = 0 | .claimedBy = null | .claimedAt = null])" "$PENDING" > "$PENDING.tmp" && mv "$PENDING.tmp" "$PENDING"

    echo "✓ Task moved to pending queue. Will be retried."
}

# Mark DLQ task as completed (skip)
dlq_skip() {
    local task_id=$1

    if [ -z "$task_id" ]; then
        echo "Usage: $0 dlq-skip <task-id>"
        exit 1
    fi

    echo "Marking task $task_id as completed (skipped)..."

    # Find and remove from DLQ, add to completed
    local task=$(jq ".tasks[] | select(.id == \"$task_id\")" "$DEAD_LETTER")

    jq "(.tasks |= map(select(.id != \"$task_id\")))" "$DEAD_LETTER" > "$DEAD_LETTER.tmp" && mv "$DEAD_LETTER.tmp" "$DEAD_LETTER"

    # Add to completed with skipped status
    jq "(.tasks += [$task | .completedAt = \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\" | .completedBy = \"manual\" | .result = {success: true, skipped: true}])" "$COMPLETED" > "$COMPLETED.tmp" && mv "$COMPLETED.tmp" "$COMPLETED"

    echo "✓ Task marked as completed (skipped)."
}

# Delete task from DLQ
dlq_delete() {
    local task_id=$1

    if [ -z "$task_id" ]; then
        echo "Usage: $0 dlq-delete <task-id>"
        exit 1
    fi

    echo "⚠ Deleting task $task_id from DLQ..."
    echo "This action cannot be undone."
    read -p "Are you sure? (yes/no): " confirm

    if [ "$confirm" != "yes" ]; then
        echo "Cancelled."
        return
    fi

    jq "(.tasks |= map(select(.id != \"$task_id\")))" "$DEAD_LETTER" > "$DEAD_LETTER.tmp" && mv "$DEAD_LETTER.tmp" "$DEAD_LETTER"

    echo "✓ Task deleted from DLQ."
}

# Main command handling
case "${1:-status}" in
    status)
        show_status
        ;;
    list)
        list_queue "$2"
        ;;
    dlq)
        show_dlq
        ;;
    dlq-review)
        dlq_review
        ;;
    dlq-retry)
        dlq_retry "$2"
        ;;
    dlq-skip)
        dlq_skip "$2"
        ;;
    dlq-delete)
        dlq_delete "$2"
        ;;
    pending)
        jq '.tasks' "$PENDING" 2>/dev/null || echo "[]"
        ;;
    in-progress)
        jq '.tasks' "$IN_PROGRESS" 2>/dev/null || echo "[]"
        ;;
    completed)
        jq '.tasks' "$COMPLETED" 2>/dev/null || echo "[]"
        ;;
    failed)
        jq '.tasks' "$FAILED" 2>/dev/null || echo "[]"
        ;;
    dead-letter)
        jq '.tasks' "$DEAD_LETTER" 2>/dev/null || echo "[]"
        ;;
    *)
        echo "Usage: $0 [status|list <queue>|dlq|dlq-review|dlq-retry <id>|dlq-skip <id>|dlq-delete <id>]"
        echo ""
        echo "Commands:"
        echo "  status          - Show queue status"
        echo "  list <queue>    - List tasks in queue (pending|in-progress|completed|failed|dead-letter)"
        echo "  dlq             - Show DLQ details"
        echo "  dlq-review      - Review DLQ tasks"
        echo "  dlq-retry <id>  - Move DLQ task back to pending"
        echo "  dlq-skip <id>   - Mark DLQ task as completed (skip)"
        echo "  dlq-delete <id> - Delete DLQ task"
        exit 1
        ;;
esac
