#!/bin/bash

# Autonomous AI Development Agent - Bootstrap Script
# Initializes the .agent/ directory structure and all required files

set -e

AGENT_ROOT=".agent"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     Autonomous AI Development Agent - Bootstrap           ║"
echo "║                                                            ║"
echo "║  Initializing .agent/ directory structure...            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Create directory structure
echo "📁 Creating directories..."
mkdir -p "$AGENT_ROOT/state/agents"
mkdir -p "$AGENT_ROOT/state/checkpoints"
mkdir -p "$AGENT_ROOT/queue"
mkdir -p "$AGENT_ROOT/config/schemas"
mkdir -p "$AGENT_ROOT/prompts/agents"
mkdir -p "$AGENT_ROOT/prompts/skills"
mkdir -p "$AGENT_ROOT/logs/agents"
mkdir -p "$AGENT_ROOT/logs/errors"
mkdir -p "$AGENT_ROOT/memory"
mkdir -p "$AGENT_ROOT/scripts"
mkdir -p "$AGENT_ROOT/workspace"
echo "   ✓ Directories created"

# Initialize orchestrator state
echo "📊 Initializing orchestrator state..."
cat > "$AGENT_ROOT/state/orchestrator.json" << EOF
{
  "version": "1.0.0",
  "sessionId": "$(uuidgen 2>/dev/null || echo 'init-$TIMESTAMP')",
  "startTime": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "currentPhase": "idle",
  "userPrompt": "",
  "analysis": {},
  "agents": {
    "active": [],
    "idle": [],
    "failed": [],
    "totalSpawned": 0
  },
  "metrics": {
    "tasksCompleted": 0,
    "tasksFailed": 0,
    "tasksPending": 0,
    "durationSeconds": 0
  },
  "lastCheckpoint": null
}
EOF
echo "   ✓ Orchestrator state initialized"

# Initialize circuit breaker state
echo "🔌 Initializing circuit breaker state..."
cat > "$AGENT_ROOT/state/circuits.json" << EOF
{
  "version": "1.0.0",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "circuits": {}
}
EOF
echo "   ✓ Circuit breaker state initialized"

# Initialize task queues
echo "📋 Initializing task queues..."
for queue in pending in-progress completed failed dead-letter; do
  cat > "$AGENT_ROOT/queue/tasks-$queue.json" << EOF
{
  "tasks": [],
  "metadata": {
    "version": "1.0.0",
    "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "description": "Tasks $(echo $queue | sed 's/-/ /g')"
  }
}
EOF
done
echo "   ✓ Task queues initialized (5 files)"
echo "     - tasks-pending.json"
echo "     - tasks-in-progress.json"
echo "     - tasks-completed.json"
echo "     - tasks-failed.json"
echo "     - tasks-dead-letter.json (🔥 DLQ)"

# Initialize metrics
cat > "$AGENT_ROOT/state/metrics.json" << EOF
{
  "version": "1.0.0",
  "sessionStart": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "tasks": {
    "total": 0,
    "completed": 0,
    "failed": 0,
    "pending": 0,
    "inProgress": 0,
    "deadLetter": 0
  },
  "agents": {
    "spawned": 0,
    "active": 0,
    "idle": 0,
    "failed": 0
  },
  "performance": {
    "avgTaskDuration": 0,
    "totalDuration": 0,
    "retryRate": 0
  }
}
EOF

# Initialize memory
cat > "$AGENT_ROOT/memory/patterns.json" << EOF
{
  "version": "1.0.0",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "patterns": []
}
EOF

cat > "$AGENT_ROOT/memory/mistakes.json" << EOF
{
  "version": "1.0.0",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "mistakes": []
}
EOF

cat > "$AGENT_ROOT/memory/solutions.json" << EOF
{
  "version": "1.0.0",
  "lastUpdated": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "solutions": []
}
EOF

echo "   ✓ Memory system initialized"

# Initialize logs
cat > "$AGENT_ROOT/logs/main.log" << EOF
# Autonomous AI Development Agent - Main Log
# Started: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

EOF

echo "   ✓ Log files initialized"

# Create workspace placeholder
echo "" > "$AGENT_ROOT/workspace/.gitkeep"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                     ✓ BOOTSTRAP COMPLETE                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📂 Agent Root: $AGENT_ROOT"
echo "📊 State: $AGENT_ROOT/state/"
echo "📋 Queue: $AGENT_ROOT/queue/"
echo "📝 Logs: $AGENT_ROOT/logs/"
echo "💾 Memory: $AGENT_ROOT/memory/"
echo ""
echo "🔥 Dead Letter Queue (DLQ):"
echo "   Tasks that fail after max retries are moved to DLQ."
echo "   Review: $AGENT_ROOT/queue/tasks-dead-letter.json"
echo "   Recover: Move task back to pending after fixing the issue."
echo ""
echo "🚀 Ready to start! Use the autonomous-dev skill with Claude Code."
echo ""
echo "Quick Status:"
echo "  ./agent/scripts/status.sh"
echo ""
