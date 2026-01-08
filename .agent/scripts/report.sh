#!/bin/bash
# report.sh - Generate execution reports

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Base directory
AGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# State files
ORCHESTRATOR_STATE="$AGENT_DIR/state/orchestrator.json"
COMPLETED="$AGENT_DIR/state/tasks-completed.json"
FAILED="$AGENT_DIR/state/tasks-failed.json"

# Generate report
generate_report() {
    local OUTPUT="${1:-}"

    echo "================================"
    echo "   Agent System Report"
    echo "================================"
    echo ""

    # Session info
    if [ -f "$ORCHESTRATOR_STATE" ]; then
        SESSION=$(jq -r '.sessionId' "$ORCHESTRATOR_STATE")
        START_TIME=$(jq -r '.startTime' "$ORCHESTRATOR_STATE")
        END_TIME=$(jq -r '.endTime // "Running"' "$ORCHESTRATOR_STATE")
        PHASE=$(jq -r '.phase' "$ORCHESTRATOR_STATE")

        echo -e "${CYAN}Session:${NC} $SESSION"
        echo -e "${CYAN}Phase:${NC} $PHASE"
        echo -e "${CYAN}Start:${NC} $START_TIME"
        echo -e "${CYAN}End:${NC} $END_TIME"
        echo ""
    fi

    # Metrics
    if [ -f "$ORCHESTRATOR_STATE" ]; then
        TASKS_CREATED=$(jq -r '.metrics.tasksCreated' "$ORCHESTRATOR_STATE")
        TASKS_COMPLETED=$(jq -r '.metrics.tasksCompleted' "$ORCHESTRATOR_STATE")
        TASKS_FAILED=$(jq -r '.metrics.tasksFailed' "$ORCHESTRATOR_STATE")
        AGENTS_DEPLOYED=$(jq -r '.metrics.agentsDeployed' "$ORCHESTRATOR_STATE")

        echo -e "${CYAN}Metrics:${NC}"
        echo "  Tasks Created:    $TASKS_CREATED"
        echo "  Tasks Completed:  $TASKS_COMPLETED"
        echo "  Tasks Failed:     $TASKS_FAILED"
        echo "  Agents Deployed:  $AGENTS_DEPLOYED"
        echo ""
    fi

    # Success rate
    if [ -n "$TASKS_CREATED" ] && [ "$TASKS_CREATED" -gt 0 ]; then
        SUCCESS_RATE=$((TASKS_COMPLETED * 100 / TASKS_CREATED))
        echo -e "${CYAN}Success Rate:${NC} $SUCCESS_RATE%"
        echo ""

        if [ "$SUCCESS_RATE" -ge 80 ]; then
            echo -e "  ${GREEN}✓ Excellent${NC}"
        elif [ "$SUCCESS_RATE" -ge 60 ]; then
            echo -e "  ${YELLOW}⚠ Good${NC}"
        else
            echo -e "  ${YELLOW}⚠ Needs Improvement${NC}"
        fi
        echo ""
    fi

    # Completed tasks breakdown
    if [ -f "$COMPLETED" ]; then
        echo -e "${CYAN}Completed Tasks by Type:${NC}"

        jq -r '.tasks[] | .type' "$COMPLETED" 2>/dev/null | sort | uniq -c | while read -r count type; do
            printf "  %-20s %3d\n" "$type:" "$count"
        done
        echo ""
    fi

    # Failed tasks
    if [ -f "$FAILED" ]; then
        FAILED_COUNT=$(jq '.tasks | length' "$FAILED" 2>/dev/null || echo "0")

        if [ "$FAILED_COUNT" -gt 0 ]; then
            echo -e "${CYAN}Failed Tasks:${NC}"
            jq -r '.tasks[] | "  • \(.title) (attempts: \(.attempts))"' "$FAILED" 2>/dev/null
            echo ""
        fi
    fi

    # Agent utilization
    if [ -f "$ORCHESTRATOR_STATE" ]; then
        echo -e "${CYAN}Agent Utilization:${NC}"

        # Count tasks by agent
        if [ -f "$COMPLETED" ]; then
            jq -r '.tasks[] | .agent' "$COMPLETED" 2>/dev/null | sort | uniq -c | sort -rn | while read -r count agent; do
                printf "  %-20s %3d tasks\n" "$agent:" "$count"
            done
        fi
        echo ""
    fi

    # Quality metrics
    if [ -f "$COMPLETED" ]; then
        echo -e "${CYAN}Quality Metrics:${NC}"

        # Average review scores
        AVG_CODE=$(jq -r '[.tasks[] | .review.codeScore // 0] | add / length' "$COMPLETED" 2>/dev/null || echo "N/A")
        AVG_SECURITY=$(jq -r '[.tasks[] | .review.securityScore // 0] | add / length' "$COMPLETED" 2>/dev/null || echo "N/A")
        AVG_PERF=$(jq -r '[.tasks[] | .review.performanceScore // 0] | add / length' "$COMPLETED" 2>/dev/null || echo "N/A")

        echo "  Code Quality:     $AVG_CODE"
        echo "  Security:         $AVG_SECURITY"
        echo "  Performance:      $AVG_PERF"
        echo ""
    fi
}

# Generate JSON report
generate_json_report() {
    local OUTPUT="${1:-report.json}"

    cat > "$OUTPUT" <<EOF
{
  "generatedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "session": $(jq '.sessionId // "unknown"' "$ORCHESTRATOR_STATE" 2>/dev/null || echo '"unknown"'),
  "metrics": $(jq '.metrics // {}' "$ORCHESTRATOR_STATE" 2>/dev/null || echo '{}'),
  "completedTasks": $(cat "$COMPLETED" 2>/dev/null || echo '{"tasks":[]}'),
  "failedTasks": $(cat "$FAILED" 2>/dev/null || echo '{"tasks":[]}')
}
EOF

    echo -e "${GREEN}✓ JSON report saved to: $OUTPUT${NC}"
}

# Main
case "${2:-}" in
    --json|-j)
        generate_json_report "${1:-report.json}"
        ;;
    *)
        generate_report
        ;;
esac
