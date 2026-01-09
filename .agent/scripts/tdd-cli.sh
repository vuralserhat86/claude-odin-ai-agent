#!/bin/bash
# =============================================================================
# Odin AI Agent System - Autonomous TDD CLI Wrapper
# =============================================================================
# Otonom Test Döngüsü (TDD) için bash wrapper script
#
# Kullanım:
#   ./tdd-cli.sh <command> [args]
#
# Komutlar:
#   detect <project_path>       Test framework tespiti
#   test <project_path>        Testleri çalıştır
#   cycle <project_path>        TDD döngüsünü çalıştır
#   report <project_path>       Test raporu oluştur
#   help                       Yardım menüsü
#
# Version: 1.0.0
# =============================================================================

set -euo pipefail

# Renkler
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Script dizini
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TDD_PY="${SCRIPT_DIR}/autonomous_tdd.py"

# =============================================================================
# YARDIMCI FONKSİYONLAR
# =============================================================================

print_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

print_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

check_python() {
    if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
        print_error "Python bulunamadı. Lütfen Python 3.8+ yükleyin."
        exit 1
    fi

    # Python 3 veya python3 kullan
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
    else
        PYTHON_CMD="python"
    fi
}

check_file() {
    if [[ ! -f "$TDD_PY" ]]; then
        print_error "autonomous_tdd.py bulunamadı: $TDD_PY"
        exit 1
    fi
}

# =============================================================================
# KOMUTLAR
# =============================================================================

cmd_detect() {
    local project_path="${1:-.}"

    check_file
    check_python

    print_info "Test framework tespit ediliyor: $project_path"

    $PYTHON_CMD "$TDD_PY" detect "$project_path"
}

cmd_test() {
    local project_path="${1:-.}"
    local framework="${2:-}"

    check_file
    check_python

    print_info "Testler çalıştırılıyor: $project_path"

    if [[ -n "$framework" ]]; then
        $PYTHON_CMD "$TDD_PY" test "$project_path" "$framework"
    else
        $PYTHON_CMD "$TDD_PY" test "$project_path"
    fi
}

cmd_cycle() {
    local project_path="${1:-.}"
    local max_attempts="${2:-3}"

    check_file
    check_python

    print_info "TDD döngüsü başlatılıyor: $project_path"
    print_info "Maksimum deneme: $max_attempts"

    $PYTHON_CMD "$TDD_PY" cycle "$project_path" "$max_attempts"
}

cmd_report() {
    local project_path="${1:-.}"

    print_info "Test raporu oluşturuluyor: $project_path"

    # Testleri çalıştır
    check_file
    check_python

    local result
    result=$($PYTHON_CMD "$TDD_PY" test "$project_path" 2>&1)
    local exit_code=$?

    echo ""
    echo "=========================================="
    echo "      TEST REPORT"
    echo "=========================================="
    echo ""
    echo "Project: $project_path"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}Status: PASSED${NC}"
        echo ""
        echo "$result"
    else
        echo -e "${RED}Status: FAILED${NC}"
        echo ""
        echo "$result"
    fi

    echo ""
    echo "=========================================="

    return $exit_code
}

cmd_watch() {
    local project_path="${1:-.}"

    check_file
    check_python

    print_info "Süreç izleniyor (CTRL+C ile çıkış)..."
    print_info "Proje: $project_path"
    echo ""

    # İlk test
    cmd_test "$project_path"

    echo ""
    print_info "Dosya değişiklikleri izleniyor..."

    # inotifywait veya fallback kullan
    if command -v inotifywait &> /dev/null; then
        # inotifywait modu (daha hızlı)
        inotifywait -r -e modify,create,delete \
            "$project_path/src" \
            "$project_path/test" \
            "$project_path/tests" \
            --format '%w%f' \
            | while read file; do
                echo ""
                print_info "Değişiklik tespit edildi: $file"
                sleep 2  # Tüm değişikliklerin tamamlanması için bekle

                cmd_test "$project_path"
                echo ""
                print_info "Dosya değişiklikleri izleniyor..."
            done
    else
        # Polling modu (fallback)
        print_warning "inotifywait bulunamadı, polling modu kullanılıyor"

        local last_checksum=""

        while true; do
            # Checksum hesapla
            local current_checksum=$(find "$project_path/src" "$project_path/test" "$project_path/tests" \
                -type f -name "*.js" -o -name "*.ts" -o -name "*.py" -o -name "*.go" 2>/dev/null \
                | xargs md5sum 2>/dev/null | md5sum | cut -d' ' -f1)

            if [[ "$current_checksum" != "$last_checksum" ]]; then
                echo ""
                print_info "Değişiklik tespit edildi"
                sleep 2

                cmd_test "$project_path"
                echo ""
                print_info "Dosya değişiklikleri izleniyor..."

                last_checksum="$current_checksum"
            fi

            sleep 5
        done
    fi
}

cmd_help() {
    cat << EOF
${GREEN}Odin AI Agent System - Autonomous TDD (Test-Driven Development)${NC}

${YELLOW}Kullanım:${NC}
  $0 <command> [args]

${YELLOW}Komutlar:${NC}
  ${GREEN}detect <path>${NC}         Test framework tespiti
  ${GREEN}test <path> [fw]${NC}       Testleri çalıştır (framework belirtebilirsin)
  ${GREEN}cycle <path> [max]${NC}     TDD döngüsünü çalıştır (max retry)
  ${GREEN}report <path>${NC}         Detaylı test raporu
  ${GREEN}watch <path>${NC}          Sürekli test izleme (auto-retest)
  ${GREEN}help${NC}                  Bu yardım menüsü

${YELLOW}Örnekler:${NC}
  # Framework tespiti
  $0 detect .

  # Test çalıştır
  $0 test .
  $0 test . jest

  # TDD döngüsü (max 5 deneme)
  $0 cycle . 5

  # Detaylı rapor
  $0 report .

  # Sürekli izleme (her dosya değişikliğinde)
  $0 watch .

${YELLOW}Desteklenen Framework'ler:${NC}
  • JavaScript/TypeScript: Jest, Vitest, Mocha
  • Python: Pytest
  • Go: go test
  • Rust: cargo test

${YELLOW}TDD Prensipleri:${NC}
  1. ÖNCE TEST YAZ - Kod yazmadan önce test case'leri oluştur
  2. KOD YAZ - Test'i geçecek minimal implementation
  3. TEST ÇALIŞTIR - Sandbox içinde güvenli test
  4. DÜZELT - Başarısız olursa kodu düzelt
  5. TEKRARLA - Test geçene kadar (max 3 retry)

EOF
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local command="${1:-help}"

    case "$command" in
        detect)
            cmd_detect "${2:-.}"
            ;;
        test)
            cmd_test "${2:-.}" "${3:-}"
            ;;
        cycle)
            cmd_cycle "${2:-.}" "${3:-3}"
            ;;
        report)
            cmd_report "${2:-.}"
            ;;
        watch)
            cmd_watch "${2:-.}"
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            print_error "Bilinmeyen komut: $command"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
