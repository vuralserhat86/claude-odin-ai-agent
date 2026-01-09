#!/bin/bash
# =============================================================================
# Odin AI Agent System - Validation CLI Wrapper
# =============================================================================
# JSON validation işlemleri için bash wrapper script
#
# Kullanım:
#   ./validate-cli.sh <command> [args]
#
# Komutlar:
#   validate <file_or_dir>     - JSON dosya veya dizin validate et
#   validate-state             - Tüm state dosyalarını validate et
#   retry-status               - Aktif retry durumlarını göster
#   retry-reset <file>         - Dosyanın retry sayacını sıfırla
#   export-schemas [dir]       - JSON Schema export
#   test                       - Validation testleri çalıştır
#   help                       - Yardım menüsünü göster
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
VALIDATE_PY="${SCRIPT_DIR}/validate.py"
SCHEMAS_PY="${SCRIPT_DIR}/schemas.py"

# Python komutu bul (cross-platform)
PYTHON_CMD=""

# Önce PYTHON ortalık değişkenini kontrol et
if [[ -n "$PYTHON" ]]; then
    PYTHON_CMD="$PYTHON"
# Diğer yaygın yolları dene
elif [[ -f "/c/Users/mSv/AppData/Local/Programs/Python/Python313/python.exe" ]]; then
    PYTHON_CMD="/c/Users/mSv/AppData/Local/Programs/Python/Python313/python.exe"
elif [[ -f "/c/Python313/python.exe" ]]; then
    PYTHON_CMD="/c/Python313/python.exe"
elif [[ -f "/c/Python/python.exe" ]]; then
    PYTHON_CMD="/c/Python/python.exe"
elif [[ -f "/usr/bin/python3" ]]; then
    PYTHON_CMD="/usr/bin/python3"
elif [[ -f "/usr/local/bin/python3" ]]; then
    PYTHON_CMD="/usr/local/bin/python3"
elif command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
fi

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
    # PYTHON_CMD zaten global olarak ayarlandı
    if [[ -z "$PYTHON_CMD" ]]; then
        print_error "Python bulunamadı. Lütfen Python 3.8+ yükleyin."
        exit 1
    fi
}

check_files() {
    if [[ ! -f "$VALIDATE_PY" ]]; then
        print_error "validate.py bulunamadı: $VALIDATE_PY"
        exit 1
    fi

    if [[ ! -f "$SCHEMAS_PY" ]]; then
        print_error "schemas.py bulunamadı: $SCHEMAS_PY"
        exit 1
    fi
}

# =============================================================================
# KOMUTLAR
# =============================================================================

cmd_validate() {
    local target="$1"

    if [[ -z "$target" ]]; then
        print_error "Kullanım: validate-cli.sh validate <file_or_dir>"
        return 1
    fi

    check_python
    check_files

    $PYTHON_CMD "$VALIDATE_PY" validate "$target"
}

cmd_validate_state() {
    check_python
    check_files

    print_info "State dosyaları validate ediliyor..."
    echo ""

    $PYTHON_CMD "$VALIDATE_PY" validate-state
}

cmd_retry_status() {
    check_python
    check_files

    $PYTHON_CMD "$VALIDATE_PY" retry-status
}

cmd_retry_reset() {
    local file_path="$1"

    if [[ -z "$file_path" ]]; then
        print_error "Kullanım: validate-cli.sh retry-reset <file_path>"
        return 1
    fi

    check_python
    check_files

    $PYTHON_CMD "$VALIDATE_PY" retry-reset "$file_path"
}

cmd_export_schemas() {
    local output_dir="${1:-.agent/config/schemas-generated}"

    check_python
    check_files

    $PYTHON_CMD "$VALIDATE_PY" export-schemas "$output_dir"
}

cmd_test() {
    check_python
    check_files

    print_info "Schema testleri çalıştırılıyor..."
    echo ""

    # Schema testleri
    $PYTHON_CMD "$SCHEMAS_PY" test

    echo ""
    print_info "Validation testleri..."
    echo ""

    # Boş queue test
    local test_queue=".agent/queue/tasks-pending.json"
    if [[ -f "$test_queue" ]]; then
        $PYTHON_CMD "$VALIDATE_PY" validate "$test_queue"
    else
        print_warning "Test queue dosyası bulunamadı: $test_queue"
    fi
}

cmd_validate_all() {
    """Tüm kritik state dosyalarını validate et"""
    check_python
    check_files

    print_info "Tüm state dosyaları validate ediliyor..."
    echo ""

    local exit_code=0

    # Circuits
    if [[ -f ".agent/state/circuits.json" ]]; then
        $PYTHON_CMD "$VALIDATE_PY" validate .agent/state/circuits.json || exit_code=1
    fi

    # Task queues
    for queue_file in .agent/queue/tasks-*.json; do
        if [[ -f "$queue_file" ]]; then
            $PYTHON_CMD "$VALIDATE_PY" validate "$queue_file" || exit_code=1
        fi
    done

    echo ""
    if [[ $exit_code -eq 0 ]]; then
        print_success "Tüm state dosyaları geçerli"
    else
        print_error "Bazı state dosyaları geçersiz"
    fi

    return $exit_code
}

cmd_help() {
    cat << EOF
${GREEN}Odin AI Agent System - Validation CLI${NC}

${YELLOW}Kullanım:${NC}
  $0 <command> [args]

${YELLOW}Komutlar:${NC}
  ${GREEN}validate <file_or_dir>${NC}     JSON dosya veya dizin validate et
  ${GREEN}validate-state${NC}             Tüm state dosyalarını validate et
  ${GREEN}validate-all${NC}               Tüm kritik state dosyalarını validate et
  ${GREEN}retry-status${NC}               Aktif retry durumlarını göster
  ${GREEN}retry-reset <file>${NC}         Dosyanın retry sayacını sıfırla
  ${GREEN}export-schemas [dir]${NC}       JSON Schema export
  ${GREEN}test${NC}                       Validation testleri çalıştır
  ${GREEN}help${NC}                       Bu yardım menüsünü göster

${YELLOW}Örnekler:${NC}
  $0 validate-state
  $0 validate .agent/state/circuits.json
  $0 validate .agent/queue/
  $0 validate-all
  $0 retry-status
  $0 export-schemas

${YELLOW}Recovery Strategy:${NC}
  ${BLUE}•${NC} Retry 0-1:   Otomatik retry (LLM'a hata gösterilir)
  ${BLUE}•${NC} Retry 2-4:   DLQ'ya al (manuel müdahale gerekli)
  ${BLUE}•${NC} Retry 5+:    Kullanıcı müdahalesi zorunlu

${YELLOW}Dosyalar:${NC}
  validate.py   - Ana validation script'i
  schemas.py    - Pydantic schema tanımları

EOF
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local command="${1:-help}"

    case "$command" in
        validate)
            cmd_validate "${2:-}"
            ;;
        validate-state)
            cmd_validate_state
            ;;
        validate-all)
            cmd_validate_all
            ;;
        retry-status)
            cmd_retry_status
            ;;
        retry-reset)
            cmd_retry_reset "${2:-}"
            ;;
        export-schemas)
            cmd_export_schemas "${2:-}"
            ;;
        test)
            cmd_test
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
