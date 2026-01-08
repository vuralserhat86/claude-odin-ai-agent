#!/bin/bash

# Autonomous AI Development Agent - Status Script
# Shows current system status

AGENT_ROOT=".agent"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              Autonomous AI Development Agent                  ║"
echo "║                       System Status                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if bootstrapped
if [ ! -d "$AGENT_ROOT" ]; then
  echo "❌ Not initialized. Run: .agent/scripts/bootstrap.sh"
  exit 1
fi

# Read orchestrator state
ORCHESTRATOR_STATE="$AGENT_ROOT/state/orchestrator.json"
if [ -f "$ORCHESTRATOR_STATE" ]; then
  SESSION_ID=$(jq -r '.sessionId' "$ORCHESTRATOR_STATE")
  PHASE=$(jq -r '.currentPhase' "$ORCHESTRATOR_STATE")
  START_TIME=$(jq -r '.startTime' "$ORCHESTRATOR_STATE")
  DURATION=$(jq -r '.metrics.durationSeconds // "0"' "$ORCHESTRATOR_STATE")

  echo "📊 Orchestrator Status:"
  echo "   Session ID: $SESSION_ID"
  echo "   Phase: $PHASE"
  echo "   Started: $START_TIME"
  echo "   Duration: ${DURATION}s"
  echo ""

  # Agent status
  ACTIVE_COUNT=$(jq -r '.agents.active | length' "$ORCHESTRATOR_STATE")
  IDLE_COUNT=$(jq -r '.agents.idle | length' "$ORCHESTRATOR_STATE")
  FAILED_COUNT=$(jq -r '.agents.failed | length' "$ORCHESTRATOR_STATE")
  TOTAL_SPAWNED=$(jq -r '.agents.totalSpawned' "$ORCHESTRATOR_STATE")

  echo "🤖 Agents:"
  echo "   Active: $ACTIVE_COUNT"
  echo "   Idle: $IDLE_COUNT"
  echo "   Failed: $FAILED_COUNT"
  echo "   Total Spawned: $TOTAL_SPAWNED"
  echo ""

  # Task metrics
  TASKS_COMPLETED=$(jq -r '.metrics.tasksCompleted' "$ORCHESTRATOR_STATE")
  TASKS_FAILED=$(jq -r '.metrics.tasksFailed' "$ORCHESTRATOR_STATE")
  TASKS_PENDING=$(jq -r '.metrics.tasksPending' "$ORCHESTRATOR_STATE")

  echo "📋 Tasks:"
  echo "   Completed: $TASKS_COMPLETED"
  echo "   Failed: $TASKS_FAILED"
  echo "   Pending: $TASKS_PENDING"
  echo ""
fi

# Queue status
echo "📦 Queue Status:"
for queue in pending in-progress completed failed dead-letter; do
  QUEUE_FILE="$AGENT_ROOT/queue/tasks-$queue.json"
  if [ -f "$QUEUE_FILE" ]; then
    COUNT=$(jq -r '.tasks | length' "$QUEUE_FILE")
    if [ "$queue" = "dead-letter" ] && [ "$COUNT" -gt 0 ]; then
      printf "   %-15s %3d tasks 🔥\n" "$queue:" "$COUNT"
    else
      printf "   %-15s %3d tasks\n" "$queue:" "$COUNT"
    fi
  fi
done
echo ""

# Recent activity (from logs)
if [ -f "$AGENT_ROOT/logs/main.log" ]; then
  echo "📝 Recent Activity:"
  tail -5 "$AGENT_ROOT/logs/main.log" | sed 's/^/   /' | head -5
  echo ""
fi

echo "═══════════════════════════════════════════════════════════════"
