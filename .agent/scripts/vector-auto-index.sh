#!/bin/bash
# =============================================================================
# Odin AI Agent System - Auto Vector Index
# =============================================================================
# Task tamamlandığında otomatik olarak vektör indeksine ekler
#
# Kullanım:
#   ./vector-auto-index.sh watch      - Sürekli izleme modu
#   ./vector-auto-index.sh index      - Tek seferlik indeksleme
#   ./vector-auto-index.sh install    - Git hook kurulumu
#
# Version: 1.0.0
# =============================================================================

set -euo pipefail

# Renkler
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Dizinler
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VECTOR_CLI="${SCRIPT_DIR}/vector-cli.sh"
QUEUE_DIR=".agent/queue"
STATE_DIR=".agent/state"

# =============================================================================
// YARDIMCI FONKSİYONLAR
// =============================================================================

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

# =============================================================================
// İZLEME FONKSİYONLARI
// =============================================================================

get_file_checksum() {
    local file="$1"
    if [[ -f "$file" ]]; then
        md5sum "$file" 2>/dev/null | cut -d' ' -f1 || echo "unknown"
    else
        echo "none"
    fi
}

check_dependencies() {
    if ! command -v inotifywait &> /dev/null; then
        print_warning "inotifywait bulunamadı (inotify-tools package)"
        print_info "Polling modu kullanılacak (daha yavaş)"
        return 1
    fi
    return 0
}

# =============================================================================
// KOMUTLAR
// =============================================================================

cmd_index() {
    """Tek seferlik indeksleme"""
    print_info "Vektör indeksi güncelleniyor..."

    if [[ -f "$VECTOR_CLI" ]]; then
        bash "$VECTOR_CLI" index-all
    else
        print_error "vector-cli.sh bulunamadı"
        return 1
    fi
}

cmd_watch() {
    """Sürekli izleme modu"""

    print_info "Auto-index başlatılıyor..."
    print_info "Queue dizini izleniyor: $QUEUE_DIR"

    # İlk indeksleme
    cmd_index

    # Dosya checksum'ları
    declare -A last_checksum

    # İlk checksum'ları al
    for queue_file in "$QUEUE_DIR"/tasks-*.json; do
        if [[ -f "$queue_file" ]]; then
            filename=$(basename "$queue_file")
            last_checksum[$filename]=$(get_file_checksum "$queue_file")
        fi
    done

    # İzleme döngüsü
    if check_dependencies; then
        # inotifywait kullan (daha hızlı)
        print_info "inotifywait modu aktif"

        while true; do
            # Değişiklikleri bekle
            changes=$(inotifywait -q -e modify,create,delete --format '%w%f' "$QUEUE_DIR"/tasks-*.json 2>/dev/null || true)

            if [[ -n "$changes" ]]; then
                print_info "Değişiklik tespit edildi: $changes"

                # Kısa bir bekle (tüm değişikliklerin tamamlanması için)
                sleep 2

                # Yeniden indeksle
                cmd_index

                # Checksum'ları güncelle
                for queue_file in "$QUEUE_DIR"/tasks-*.json; do
                    if [[ -f "$queue_file" ]]; then
                        filename=$(basename "$queue_file")
                        last_checksum[$filename]=$(get_file_checksum "$queue_file")
                    fi
                done
            fi

            sleep 5
        done
    else
        # Polling modu (fallback)
        print_warning "Polling modu aktif (her 10 saniyede kontrol)"

        while true; do
            sleep 10

            # Değişiklik kontrolü
            for queue_file in "$QUEUE_DIR"/tasks-*.json; do
                if [[ -f "$queue_file" ]]; then
                    filename=$(basename "$queue_file")
                    current_checksum=$(get_file_checksum "$queue_file")

                    if [[ "${last_checksum[$filename]}" != "$current_checksum" ]]; then
                        print_info "Değişiklik tespit edildi: $filename"

                        # Yeniden indeksle
                        cmd_index

                        # Checksum güncelle
                        last_checksum[$filename]="$current_checksum"
                    fi
                fi
            done
        done
    fi
}

cmd_install_hook() {
    """Git hook kurulumu"""

    print_info "Git hook kurulumu..."

    local hooks_dir=".git/hooks"
    local hook_file="$hooks_dir/post-commit"
    local hook_script="#!/bin/bash\n# Auto vector index hook\ncd \$(git rev-parse --show-toplevel)\nbash .agent/scripts/vector-auto-index.sh index\n"

    # Hook dosyası oluştur
    if [[ -d "$hooks_dir" ]]; then
        echo -e "$hook_script" > "$hook_file"
        chmod +x "$hook_file"

        print_success "Git hook kuruldu: $hook_file"
        print_info "Her commit'ten sonra otomatik indekslenecek"
    else
        print_error ".git/hooks dizini bulunamadı"
        return 1
    fi
}

cmd_install_cron() {
    """Cron job kurulumu (Linux/macOS)"""

    print_info "Cron job kurulumu..."

    local script_dir="$(pwd)"
    local cron_cmd="cd $script_dir && bash .agent/scripts/vector-auto-index.sh index"

    # Cron'a ekle (her 5 dakikada bir)
    (crontab -l 2>/dev/null || true; echo "*/5 * * * * $cron_cmd") | crontab -

    print_success "Cron job kuruldu"
    print_info "Her 5 dakikada bir otomatik indekslenecek"
}

cmd_status() {
    """Durum göster"""

    echo "📊 Vektör DB Durumu:"
    echo ""

    # İstatistikler
    if [[ -f "$VECTOR_CLI" ]]; then
        bash "$VECTOR_CLI" stats
    fi

    # Son indeksleme zamanı
    local db_file="$STATE_DIR/vector-memory.db"
    if [[ -f "$db_file" ]]; then
        local modified=$(stat -c %y "$db_file" 2>/dev/null || stat -f "%Sm" "$db_file" 2>/dev/null)
        echo ""
        print_info "Son indeksleme: $modified"
    fi

    # Queue dosyaları durumu
    echo ""
    echo "📂 Queue Dosyaları:"
    for queue_file in "$QUEUE_DIR"/tasks-*.json; do
        if [[ -f "$queue_file" ]]; then
            local filename=$(basename "$queue_file")
            local count=$(jq '.tasks | length' "$queue_file" 2>/dev/null || echo "0")
            echo "   • $filename: $count task"
        fi
    done
}

cmd_help() {
    cat << EOF
${GREEN}Odin AI Agent System - Auto Vector Index${NC}

${YELLOW}Kullanım:${NC}
  $0 <command>

${YELLOW}Komutlar:${NC}
  ${GREEN}index${NC}                 Tek seferlik indeksleme
  ${GREEN}watch${NC}                 Sürekli izleme modu (değişiklik olduğunda otomatik indeksle)
  ${GREEN}install hook${NC}          Git hook kur (her commit'te çalıştır)
  ${GREEN}install cron${NC}          Cron job kur (her 5 dakikada çalıştır)
  ${GREEN}status${NC}                Durum göster
  ${GREEN}help${NC}                  Bu yardım menüsü

${YELLOW}Örnekler:${NC}
  # Tek seferlik indeksleme
  $0 index

  # Sürekli izleme (arka planda çalışır)
  $0 watch &

  # Git hook kur
  $0 install hook

  # Durum görüntüle
  $0 status

${YELLOW}Mimari:${NC}
  Bu script, queue dosyalarını izler ve değişiklik olduğunda
  otomatik olarak vektör indeksini günceller.

  • watch modu: Sürekli izleme (inotifywait veya polling)
  • Git hook: Her commit'te çalışır
  • Cron job: Periyodik çalıştırma

EOF
}

# =============================================================================
// MAIN
// =============================================================================

main() {
    local command="${1:-help}"

    case "$command" in
        index)
            cmd_index
            ;;
        watch)
            cmd_watch
            ;;
        install)
            local sub_command="${2:-hook}"
            case "$sub_command" in
                hook)
                    cmd_install_hook
                    ;;
                cron)
                    cmd_install_cron
                    ;;
                *)
                    print_error "Bilinmeyen install komutu: $sub_command"
                    echo "Kullanım: $0 install [hook|cron]"
                    exit 1
                    ;;
            esac
            ;;
        status)
            cmd_status
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
