#!/bin/bash
# circuit.sh - Circuit Breaker management script

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
CONFIG="$AGENT_DIR/config/circuit-breaker.json"
STATE="$AGENT_DIR/state/circuits.json"

# Show circuit breaker status
show_status() {
    echo "================================"
    echo "Circuit Breaker Status"
    echo "================================"
    echo ""

    # Get global config
    local enabled=$(jq -r '.global.enabled' "$CONFIG")
    local max_failures=$(jq -r '.global.maxFailures' "$CONFIG")
    local timeout=$(jq -r '.global.timeout' "$CONFIG")
    local reset_timeout=$(jq -r '.global.resetTimeout' "$CONFIG")

    echo "Global Configuration:"
    echo "   Enabled: $enabled"
    echo "   Max Failures: $max_failures"
    echo "   Task Timeout: ${timeout}s"
    echo "   Reset Timeout: ${reset_timeout}s"
    echo ""

    # Count circuits by state
    local closed=$(jq -r '.circuits | to_entries | map(select(.value.state == "CLOSED")) | length' "$STATE" 2>/dev/null || echo "0")
    local open=$(jq -r '.circuits | to_entries | map(select(.value.state == "OPEN")) | length' "$STATE" 2>/dev/null || echo "0")
    local half_open=$(jq -r '.circuits | to_entries | map(select(.value.state == "HALF_OPEN")) | length' "$STATE" 2>/dev/null || echo "0")

    echo "Circuit States:"
    echo -e "   ${GREEN}CLOSED:${NC}    $closed (normal operation)"
    echo -e "   ${RED}OPEN:${NC}       $open (tripped - blocking requests)"
    echo -e "   ${YELLOW}HALF_OPEN:${NC} $half_open (testing recovery)"
    echo ""
}

# Show specific agent circuit status
show_agent() {
    local agent_type=$1

    if [ -z "$agent_type" ]; then
        echo "Usage: $0 agent <agent-type>"
        echo ""
        echo "Available agent types:"
        jq -r '.thresholds.agents | keys[]' "$CONFIG" | sed 's/^/   /'
        exit 1
    fi

    local circuit=$(jq -r ".circuits.\"$agent_type\"" "$STATE" 2>/dev/null)

    if [ "$circuit" = "null" ] || [ -z "$circuit" ]; then
        echo "Error: Agent type '$agent_type' not found"
        exit 1
    fi

    local state=$(jq -r ".circuits.\"$agent_type\".state" "$STATE")
    local fail_count=$(jq -r ".circuits.\"$agent_type\".failCount" "$STATE")
    local max_failures=$(jq -r ".thresholds.agents.\"$agent_type\".maxFailures // .global.maxFailures" "$CONFIG")
    local last_failure=$(jq -r ".circuits.\"$agent_type\".lastFailureTime // \"Never\"" "$STATE")
    local next_retry=$(jq -r ".circuits.\"$agent_type\".nextRetryTime // \"N/A\"" "$STATE")
    local total_failures=$(jq -r ".circuits.\"$agent_type\".totalFailures // 0" "$STATE")
    local total_successes=$(jq -r ".circuits.\"$agent_type\".totalSuccesses // 0" "$STATE")

    echo "================================"
    echo "Circuit: $agent_type"
    echo "================================"
    echo ""

    case $state in
        CLOSED)
            echo -e "State: ${GREEN}CLOSED${NC} (normal operation)"
            ;;
        OPEN)
            echo -e "State: ${RED}OPEN${NC} (blocking requests)"
            ;;
        HALF_OPEN)
            echo -e "State: ${YELLOW}HALF_OPEN${NC} (testing recovery)"
            ;;
    esac

    echo ""
    echo "Fail Count: $fail_count / $max_failures"
    echo "Last Failure: $last_failure"
    echo "Next Retry: $next_retry"
    echo ""
    echo "Statistics:"
    echo "   Total Failures: $total_failures"
    echo "   Total Successes: $total_successes"
    if [ $total_successes -gt 0 ]; then
        local success_rate=$(echo "scale=1; ($total_successes * 100) / ($total_successes + $total_failures)" | bc)
        echo "   Success Rate: ${success_rate}%"
    fi
    echo ""
}

# List all circuits
list_all() {
    echo "================================"
    echo "All Circuits"
    echo "================================"
    echo ""

    jq -r '.circuits | to_entries[] |
"\(.key): \(.value.state) (Failures: \(.value.failCount))"' "$STATE" 2>/dev/null | sort | while read -r line; do
        if [[ $line == *"OPEN"* ]]; then
            echo -e "${RED}$line${NC}"
        elif [[ $line == *"HALF_OPEN"* ]]; then
            echo -e "${YELLOW}$line${NC}"
        else
            echo -e "${GREEN}$line${NC}"
        fi
    done
    echo ""
}

# Reset circuit to CLOSED
reset_circuit() {
    local agent_type=$1

    if [ -z "$agent_type" ]; then
        echo "Usage: $0 reset <agent-type>"
        exit 1
    fi

    echo "Resetting circuit: $agent_type..."

    jq "(.circuits.\"$agent_type\".state = \"CLOSED\" |
        .circuits.\"$agent_type\".failCount = 0 |
        .circuits.\"$agent_type\".nextRetryTime = null |
        .circuits.\"$agent_type\".lastFailureTime = null)" "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"

    echo "✓ Circuit $agent_type reset to CLOSED"
}

# Trip circuit (manually open)
trip_circuit() {
    local agent_type=$1

    if [ -z "$agent_type" ]; then
        echo "Usage: $0 trip <agent-type>"
        exit 1
    fi

    echo "Tripping circuit: $agent_type..."

    local now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local reset_timeout=$(jq -r '.global.resetTimeout' "$CONFIG")
    local next_retry=$(date -d "+$reset_timeout seconds" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u +"%Y-%m-%dT%H:%M:%SZ")

    jq "(.circuits.\"$agent_type\".state = \"OPEN\" |
        .circuits.\"$agent_type\".failCount = 3 |
        .circuits.\"$agent_type\".lastFailureTime = \"$now\" |
        .circuits.\"$agent_type\".nextRetryTime = \"$next_retry\")" "$STATE" > "$STATE.tmp" && mv "$STATE.tmp" "$STATE"

    echo "✓ Circuit $agent_type tripped to OPEN"
    echo "  Will retry after: $next_retry"
}

# Show help
show_help() {
    echo "Circuit Breaker Management Script"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  status              - Show overall circuit breaker status"
    echo "  list                - List all circuits with their states"
    echo "  agent <type>        - Show specific agent circuit status"
    echo "  reset <type>        - Reset circuit to CLOSED (manual recovery)"
    echo "  trip <type>         - Manually trip circuit to OPEN"
    echo "  help                - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 status           # Show overall status"
    echo "  $0 list             # List all circuits"
    echo "  $0 agent frontend   # Show frontend circuit status"
    echo "  $0 reset backend    # Reset backend circuit"
    echo ""
}

# Main command handling
case "${1:-status}" in
    status)
        show_status
        ;;
    list)
        list_all
        ;;
    agent)
        show_agent "$2"
        ;;
    reset)
        reset_circuit "$2"
        ;;
    trip)
        trip_circuit "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
