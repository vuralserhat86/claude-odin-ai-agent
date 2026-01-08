#!/bin/bash
# monitor.sh - Real-time system monitoring

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Base directory
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# State files
ORCHESTRATOR_STATE="$AGENT_DIR/state/orchestrator.json"
PENDING="$AGENT_DIR/state/tasks-pending.json"
IN_PROGRESS="$AGENT_DIR/state/tasks-in-progress.json"
COMPLETED="$AGENT_DIR/state/tasks-completed.json"
FAILED="$AGENT_DIR/state/tasks-failed.json"

# Clear screen and show header
show_header() {
    clear
    echo "================================"
    echo "   Agent System Monitor"
    echo "================================"
    echo ""
}

# Show orchestrator status
show_orchestrator() {
    if [ ! -f "$ORCHESTRATOR_STATE" ]; then
        echo -e "${RED}Orchestrator not initialized${NC}"
        echo "Run ./scripts/bootstrap.sh first"
        return
    fi

    SESSION=$(jq -r '.sessionId' "$ORCHESTRATOR_STATE" 2>/dev/null)
    PHASE=$(jq -r '.phase' "$ORCHESTRATOR_STATE" 2>/dev/null)
    TASKS_CREATED=$(jq -r '.metrics.tasksCreated' "$ORCHESTRATOR_STATE" 2>/dev/null)
    TASKS_COMPLETED=$(jq -r '.metrics.tasksCompleted' "$ORCHESTRATOR_STATE" 2>/dev/null)

    echo -e "${CYAN}Orchestrator:${NC}"
    echo "  Session: $SESSION"
    echo "  Phase: $PHASE"
    echo "  Tasks: $TASKS_COMPLETED/$TASKS_CREATED completed"
    echo ""
}

# Show queue status
show_queues() {
    echo -e "${CYAN}Task Queues:${NC}"

    if [ -f "$PENDING" ]; then
        PENDING_COUNT=$(jq '.tasks | length' "$PENDING" 2>/dev/null || echo "0")
        printf "  ${YELLOW}Pending:${NC}     %3d tasks\n" "$PENDING_COUNT"
    else
        printf "  ${YELLOW}Pending:${NC}     ---\n"
    fi

    if [ -f "$IN_PROGRESS" ]; then
        IN_PROGRESS_COUNT=$(jq '.tasks | length' "$IN_PROGRESS" 2>/dev/null || echo "0")
        printf "  ${BLUE}In Progress:${NC} %3d tasks\n" "$IN_PROGRESS_COUNT"
    else
        printf "  ${BLUE}In Progress:${NC} ---\n"
    fi

    if [ -f "$COMPLETED" ]; then
        COMPLETED_COUNT=$(jq '.tasks | length' "$COMPLETED" 2>/dev/null || echo "0")
        printf "  ${GREEN}Completed:${NC}   %3d tasks\n" "$COMPLETED_COUNT"
    else
        printf "  ${GREEN}Completed:${NC}   ---\n"
    fi

    if [ -f "$FAILED" ]; then
        FAILED_COUNT=$(jq '.tasks | length' "$FAILED" 2>/dev/null || echo "0")
        printf "  ${RED}Failed:${NC}      %3d tasks\n" "$FAILED_COUNT"
    else
        printf "  ${RED}Failed:${NC}      ---\n"
    fi

    echo ""
}

# Show active agents
show_active_agents() {
    echo -e "${CYAN}Active Agents:${NC}"

    if [ -f "$IN_PROGRESS" ]; then
        ACTIVE_TASKS=$(jq -r '.tasks[] | "\(.agent): \(.title)"' "$IN_PROGRESS" 2>/dev/null")

        if [ -z "$ACTIVE_TASKS" ]; then
            echo "  No active agents"
        else
            echo "$ACTIVE_TASKS" | while read -r line; do
                echo "  • $line"
            done
        fi
    else
        echo "  No active agents"
    fi

    echo ""
}

# Show recent tasks
show_recent_tasks() {
    echo -e "${CYAN}Recent Tasks:${NC}"

    if [ -f "$COMPLETED" ]; then
        RECENT=$(jq -r '.tasks[-5:] | reverse[] | "  ✓ \(.title) (\(.completedAt))"' "$COMPLETED" 2>/dev/null)

        if [ -z "$RECENT" ]; then
            echo "  No completed tasks yet"
        else
            echo "$RECENT"
        fi
    else
        echo "  No completed tasks yet"
    fi

    echo ""
}

# Main monitoring loop
main() {
    local REFRESH_RATE=2

    # Check for watch mode flag
    if [ "$1" = "--watch" ] || [ "$1" = "-w" ]; then
        while true; do
            show_header
            show_orchestrator
            show_queues
            show_active_agents
            show_recent_tasks
            echo "Refreshing every ${REFRESH_RATE}s (Ctrl+C to exit)..."
            sleep "$REFRESH_RATE"
        done
    else
        # Single shot
        show_header
        show_orchestrator
        show_queues
        show_active_agents
        show_recent_tasks
    fi
}

main "$@"
