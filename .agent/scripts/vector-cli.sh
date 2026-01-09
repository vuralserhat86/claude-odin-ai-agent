#!/bin/bash
# =============================================================================
# Odin AI Agent System - Vector Memory CLI Wrapper
# =============================================================================
# Vektör tabanlı hafıza sistemi için bash wrapper script
#
# Kullanım:
#   ./vector-cli.sh <command> [args]
#
# Komutlar:
#   index [file]              - Task'ları indeksle
#   index-all                 - Tüm queue'ları indeksle
#   search <query> [k]        - Semantik arama
#   stats                     - İstatistikler
#   clear --confirm           - Tüm veriyi sil
#   optimize                  - DB'yi optimize et
#   test                      - Test çalıştır
#   help                      - Yardım menüsü
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
VECTOR_PY="${SCRIPT_DIR}/vector_memory.py"

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

check_file() {
    if [[ ! -f "$VECTOR_PY" ]]; then
        print_error "vector_memory.py bulunamadı: $VECTOR_PY"
        exit 1
    fi
}

check_dependency() {
    # sentence-transformers kurulu mu?
    if ! $PYTHON_CMD -c "import sentence_transformers" 2>/dev/null; then
        print_warning "sentence_transformers yüklü değil."

        echo ""
        print_info "Kurulum için:"
        echo "   pip install sentence-transformers"
        echo ""
        print_info "Veya daha hafif versiyon:"
        echo "   pip install sentence-transformers[onnx]"
        echo ""

        read -p "Şimdi kurulum yapılmalı mı? (y/N): " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Kuruluyor..."
            pip install sentence-transformers

            if [[ $? -eq 0 ]]; then
                print_success "Kurulum başarılı"
            else
                print_error "Kurulum başarısız"
                exit 1
            fi
        else
            print_error "sentence_transformers gerekli"
            exit 1
        fi
    fi
}

# =============================================================================
# KOMUTLAR
# =============================================================================

cmd_index() {
    local tasks_file="${1:-.agent/queue/tasks-completed.json}"

    check_file
    check_dependency

    print_info "Task'lar indeksleniyor: $tasks_file"

    $PYTHON_CMD "$VECTOR_PY" index "$tasks_file"
}

cmd_index_all() {
    check_file
    check_dependency

    print_info "Tüm queue dosyaları indeksleniyor..."

    $PYTHON_CMD "$VECTOR_PY" index --all
}

cmd_search() {
    local query="$1"
    local top_k="${2:-5}"

    if [[ -z "$query" ]]; then
        print_error "Kullanım: vector-cli.sh search <query> [top_k]"
        return 1
    fi

    check_file
    check_dependency

    $PYTHON_CMD "$VECTOR_PY" search "$query" "$top_k"
}

cmd_stats() {
    check_file
    check_python
    check_dependency

    $PYTHON_CMD "$VECTOR_PY" stats
}

cmd_clear() {
    if [[ "${1:-}" != "--confirm" ]]; then
        print_error "--confirm parametresi gerekli"
        print_info "Kullanım: vector-cli.sh clear --confirm"
        return 1
    fi

    check_file

    print_warning "Tüm vektör verisi silinecek!"
    read -p "Devam etmek istediğinizden emin misiniz? (e/H): " -n 1 -r
    echo

    if [[ $REPLY =~ ^[Ee]$ ]]; then
        $PYTHON_CMD "$VECTOR_PY" clear --confirm
    else
        print_info "İptal edildi"
        return 0
    fi
}

cmd_optimize() {
    check_file

    print_info "Vektör DB optimize ediliyor..."

    $PYTHON_CMD "$VECTOR_PY" optimize
}

cmd_test() {
    check_file
    check_dependency

    print_info "RAG sistemi test ediliyor..."

    $PYTHON_CMD "$VECTOR_PY" test
}

cmd_help() {
    cat << EOF
${GREEN}Odin AI Agent System - Vector Memory (RAG)${NC}

${YELLOW}Kullanım:${NC}
  $0 <command> [args]

${YELLOW}Komutlar:${NC}
  ${GREEN}index [file]${NC}         Task'ları indeksle (varsayılan: tasks-completed.json)
  ${GREEN}index-all${NC}             Tüm queue dosyalarını indeksle
  ${GREEN}search <query> [k]${NC}    Semantik arama (varsayılan top_k: 5)
  ${GREEN}stats${NC}                 İstatistikler
  ${GREEN}clear --confirm${NC}       Tüm veriyi sil
  ${GREEN}optimize${NC}              DB'yi optimize et
  ${GREEN}test${NC}                  Test çalıştır
  ${GREEN}help${NC}                  Bu yardım menüsünü göster

${YELLOW}Örnekler:${NC}
  # İlk kurulum - İndeksleme
  $0 index

  # Tüm queue'ları indeksle
  $0 index-all

  # Semantik arama
  $0 search "authentication system"
  $0 search "React form component" 3

  # İstatistikler
  $0 stats

  # Test
  $0 test

${YELLOW}Dependency:${NC}
  pip install sentence-transformers

${YELLOW}Nedir?${NC}
  Vektör tabanlı hafıza sistemi, tamamlanan task'ları semantik olarak
  arar. Yeni bir task geldiğinde, daha önce yapılmış benzer task'ları
  bulur ve tutarlılık sağlar.

${YELLOW}Mimari:${NC}
  1. Task'lar vektörleştirilir (384 boyutlu embedding)
  2. SQLite vektör DB'ye kaydedilir
  3. Yeni task'larda semantik arama yapılır
  4. En alakalı 5-10 task context'e eklenir

${YELLOW}Faydalar:${NC}
  • Proje büyüse bile hız sabit kalır (O(log n) vs O(n))
  • Token kullanımı %90 azalır
  • Eski decision'lar unutulmaz
  • Tutarlı kod üretimi

EOF
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local command="${1:-help}"

    case "$command" in
        index)
            cmd_index "${2:-}"
            ;;
        index-all)
            cmd_index_all
            ;;
        search)
            cmd_search "${2:-}" "${3:-5}"
            ;;
        stats)
            cmd_stats
            ;;
        clear)
            cmd_clear "${2:-}"
            ;;
        optimize)
            cmd_optimize
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
