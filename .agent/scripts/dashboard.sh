#!/bin/bash
# =============================================================================
# Odin AI Agent System - Static Dashboard
# =============================================================================
# Terminal tabanlı sistem dashboard'u
#
# Kullanım:
#   ./dashboard.sh              # Tek seferlik göster
#   ./dashboard.sh --watch      # Her 5 saniyede refresh
#
# Version: 1.0.0
# =============================================================================

# Script dizini
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Data dosyaları
CIRCUITS_FILE="$PROJECT_ROOT/.agent/state/circuits.json"
QUEUE_DIR="$PROJECT_ROOT/.agent/queue"
DLQ_FILE="$QUEUE_DIR/tasks-dead-letter.json"

# =============================================================================
# RENKLER
# =============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# =============================================================================
# VERİ OKUMA FONKSİYONLARI
# =============================================================================

get_circuit_total() {
    jq '.circuits | length' "$CIRCUITS_FILE" 2>/dev/null || echo "0"
}

get_circuit_closed() {
    jq '[.circuits[].state | select(. == "CLOSED")] | length' "$CIRCUITS_FILE" 2>/dev/null || echo "0"
}

get_circuit_open() {
    jq '[.circuits[].state | select(. == "OPEN")] | length' "$CIRCUITS_FILE" 2>/dev/null || echo "0"
}

get_circuit_half_open() {
    jq '[.circuits[].state | select(. == "HALF_OPEN")] | length' "$CIRCUITS_FILE" 2>/dev/null || echo "0"
}

get_queue_pending() {
    if [[ -f "$QUEUE_DIR/tasks-pending.json" ]]; then
        jq '.tasks | length' "$QUEUE_DIR/tasks-pending.json" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

get_queue_in_progress() {
    if [[ -f "$QUEUE_DIR/tasks-in-progress.json" ]]; then
        jq '.tasks | length' "$QUEUE_DIR/tasks-in-progress.json" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

get_queue_completed() {
    if [[ -f "$QUEUE_DIR/tasks-completed.json" ]]; then
        jq '.tasks | length' "$QUEUE_DIR/tasks-completed.json" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

get_queue_failed() {
    if [[ -f "$QUEUE_DIR/tasks-failed.json" ]]; then
        jq '.tasks | length' "$QUEUE_DIR/tasks-failed.json" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

get_dlq_count() {
    if [[ -f "$DLQ_FILE" ]]; then
        jq '.tasks | length' "$DLQ_FILE" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

get_blocked_agents() {
    jq -r '.circuits[] | select(.state == "OPEN" or .state == "HALF_OPEN") |
           "\(.key // "unknown") \(.state) (\(.failCount // 0) failures)"' \
       "$CIRCUITS_FILE" 2>/dev/null | head -5
}

get_recent_completed() {
    if [[ -f "$QUEUE_DIR/tasks-completed.json" ]]; then
        jq -r '[.tasks[-5:][]
                | "\(.completedAt // "Unknown") \(.agent // "unknown") \(.type // "task"] |
                .[]' "$QUEUE_DIR/tasks-completed.json" 2>/dev/null | \
        awk '{
            gsub(/T/, " ", $1)
            gsub(/Z.*/, "", $1)
            split($1, parts, " ")
            printf "• %s %s %s\n", parts[2], $2, substr($0, index($0, $3))
        }'
    else
        echo "No recent activity"
    fi
}

# =============================================================================
# DASHBOARD RENDER
# =============================================================================

render_dashboard() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    local total closed open half_open
    total=$(get_circuit_total)
    closed=$(get_circuit_closed)
    open=$(get_circuit_open)
    half_open=$(get_circuit_half_open)

    local pending in_progress completed failed
    pending=$(get_queue_pending)
    in_progress=$(get_queue_in_progress)
    completed=$(get_queue_completed)
    failed=$(get_queue_failed)

    local dlq_count
    dlq_count=$(get_dlq_count)

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}${BOLD}                    ODIN SYSTEM DASHBOARD                       ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                    Version: 1.0.0    ${timestamp}        ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  CIRCUIT BREAKER STATUS                    QUEUE STATUS         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ┌─────────────────────────────────┐    ┌──────────────────┐  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  │ Total: ${BOLD}${total}${NC}                           │    │ Pending: ${pending}      │  ${CYAN}║${NC}"

    if (( total > 0 )); then
        local closed_pct open_pct half_pct
        closed_pct=$(( closed * 100 / total ))
        open_pct=$(( open * 100 / total ))
        half_pct=$(( half_open * 100 / total ))

        if (( closed > 0 )); then
            echo -e "${CYAN}║${NC}  │ Closed: ${GREEN}${closed}${NC} ✅ (${closed_pct}%)             │    │ In-Progress: ${in_progress}           │  ${CYAN}║${NC}"
        else
            echo -e "${CYAN}║${NC}  │ Closed: ${closed} (${closed_pct}%)             │    │ In-Progress: ${in_progress}           │  ${CYAN}║${NC}"
        fi

        if (( open > 0 )); then
            echo -e "${CYAN}║${NC}  │ Open: ${RED}${open}${NC} 🔴 (${open_pct}%)               │    │ Completed: ${GREEN}${completed}${NC}            │  ${CYAN}║${NC}"
        else
            echo -e "${CYAN}║${NC}  │ Open: ${open} (${open_pct}%)               │    │ Completed: ${completed}            │  ${CYAN}║${NC}"
        fi

        if (( half_open > 0 )); then
            echo -e "${CYAN}║${NC}  │ Half-Open: ${YELLOW}${half_open}${NC} 🟡 (${half_pct}%)            │    │ Failed: ${failed}               │  ${CYAN}║${NC}"
        else
            echo -e "${CYAN}║${NC}  │ Half-Open: ${half_open} (${half_pct}%)            │    │ Failed: ${failed}               │  ${CYAN}║${NC}"
        fi
    else
        echo -e "${CYAN}║${NC}  │ Total: ${total}                           │    │ In-Progress: ${in_progress}           │  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  │ Closed: ${closed}                         │    │ Completed: ${completed}            │  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  │ Open: ${open}                            │    │ Failed: ${failed}               │  ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  │ Half-Open: ${half_open}                      │    │                             │  ${CYAN}║${NC}"
    fi

    echo -e "${CYAN}║${NC}  └─────────────────────────────────┘    └──────────────────┘  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  DEAD LETTER QUEUE (Failed Tasks)                                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  ┌────────────────────────────────────────────────────────────┐${CYAN}║${NC}"

    if (( dlq_count > 0 )); then
        echo -e "${CYAN}║${NC}  │ Count: ${BOLD}${dlq_count}${NC} stuck tasks                                         ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  │                                                              ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  │ ${RED}⚠️  Tasks need manual intervention!${NC}                             ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  │ Run: bash .agent/scripts/queue.sh dlq-review                   ${CYAN}║${NC}"
    else
        echo -e "${CYAN}║${NC}  │ Count: ${BOLD}${dlq_count}${NC} stuck tasks                                         ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}  │ ${GREEN}✅ No failed tasks!${NC}                                              ${CYAN}║${NC}"
    fi

    echo -e "${CYAN}║${NC}  └────────────────────────────────────────────────────────────┘${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"

    # Blocked agents
    local blocked
    blocked=$(get_blocked_agents)

    if [[ -n "$blocked" ]]; then
        echo -e "${CYAN}║${NC}  BLOCKED AGENTS:                                                 ${CYAN}║${NC}"
        echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
        echo "$blocked" | while read -r agent; do
            if [[ -n "$agent" ]]; then
                printf "${CYAN}║${NC}  • ${RED}%s${NC}" "$agent"
                # Padding to 73 chars
                local len=${#agent}
                local padding=$((73 - len))
                printf "%${padding}s${CYAN}║${NC}\n" ""
            fi
        done
        echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    fi

    # Recent activity
    echo -e "${CYAN}║${NC}  RECENT ACTIVITY:                                                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"

    local recent
    recent=$(get_recent_completed)
    echo "$recent" | while read -r line; do
        if [[ -n "$line" ]]; then
            printf "${CYAN}║${NC}  %s" "$line"
            local len=${#line}
            local padding=$((73 - len))
            printf "%${padding}s${CYAN}║${NC}\n" ""
        fi
    done

    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}  SYSTEM HEALTH: ${GREEN}Normal${NC}                                               ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}                                                                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}[R]${NC}efresh   ${CYAN}[Q]${NC}uit   ${CYAN}[C]${NC}ircuits   ${CYAN}[D]${NC}LQ   ${CYAN}[H]${NC}elp"
    echo ""
}

# =============================================================================
# AUTO-REFRESH MOD
# =============================================================================

auto_refresh_mode() {
    local interval=${1:-5}

    echo -e "${GREEN}Auto-refresh modu aktif (${interval}s interval)${NC}"
    echo -e "${GRAY}Durdurmak için CTRL+C${NC}"
    echo ""

    trap 'echo ""; echo -e "${YELLOW}Dashboard durduruldu${NC}"; exit 0' INT

    while true; do
        render_dashboard
        sleep "$interval"
    done
}

# =============================================================================
# INTERACTIVE MOD
# =============================================================================

interactive_mode() {
    local key

    while true; do
        render_dashboard

        read -rsn1 -t 5 key 2>/dev/null || key=""

        case "$key" in
            r|R)
                continue
                ;;
            q|Q)
                echo ""
                echo -e "${GREEN}Dashboard kapatılıyor...${NC}"
                exit 0
                ;;
            c|C)
                echo ""
                bash "$SCRIPT_DIR/circuit.sh" list
                echo ""
                read -rsn1 -p "Devam etmek için bir tuşa basın..."
                ;;
            d|D)
                echo ""
                bash "$SCRIPT_DIR/queue.sh" dlq
                echo ""
                read -rsn1 -p "Devam etmek için bir tuşa basın..."
                ;;
            h|H)
                echo ""
                echo "=== DASHBOARD YARDIM ==="
                echo ""
                echo "[R] - Dashboard'u yenile"
                echo "[Q] - Dashboard'dan çık"
                echo "[C] - Circuit Breaker detaylı liste"
                echo "[D] - Dead Letter Queue görüntüle"
                echo "[H] - Bu yardım menüsü"
                echo ""
                read -rsn1 -p "Devam etmek için bir tuşa basın..."
                ;;
        esac
    done
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local mode="single"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --watch|-w)
                mode="auto"
                shift
                ;;
            --loop|-l)
                mode="interactive"
                shift
                ;;
            --help|-h)
                cat << EOF
${GREEN}Odin AI Agent System - Dashboard${NC}

${YELLOW}Kullanım:${NC}
  $0                    Tek seferlik göster
  $0 --watch            Auto-refresh modu (5s)
  $0 --loop             Interactive mod

${YELLOW}Komutlar:${NC}
  [R] Refresh           Dashboard'u yenile
  [Q] Quit              Çıkış
  [C] Circuits          Circuit Breaker detayları
  [D] DLQ               Dead Letter Queue görüntüle
  [H] Help              Yardım

EOF
                exit 0
                ;;
            *)
                echo -e "${RED}Bilinmeyen argüman: $1${NC}"
                exit 1
                ;;
        esac
    done

    case "$mode" in
        auto)
            auto_refresh_mode 5
            ;;
        interactive)
            interactive_mode
            ;;
        single)
            render_dashboard
            ;;
    esac
}

main "$@"
