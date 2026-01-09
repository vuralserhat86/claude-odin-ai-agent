#!/usr/bin/env python3
"""
Odin AI Agent System - JSON Validator
LLM çıktılarının JSON formatına uygunluğunu validate eder.

Hibr Recovery Strategy:
  - Retry 1-2: Otomatik retry (LLM'a hatayı göster)
  - Retry 3-5: DLQ'ya al (manuel müdahale)
  - Retry 5+: Kullanıcıya sor (critical)

Version: 1.0.0
"""

import json
import sys
from pathlib import Path
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, Tuple
import uuid

# Schema'ları import et
try:
    from schemas import (
        validate_json,
        ValidationResult,
        TaskState,
        DLQTask,
        TaskQueue,
        DLQueue
    )
except ImportError:
    print("❌ schemas.py bulunamadı. Lütfen aynı dizinde olduğundan emin olun.")
    sys.exit(1)


# ============================================================================
# KONFİGÜRASYON
# ============================================================================

# Retry limitleri
AUTO_RETRY_LIMIT = 2          # İlk 2 hata: otomatik retry
DLQ_RETRY_LIMIT = 5           # 3-5 arası: DLQ
USER_INTERVENTION_LIMIT = 5   # 5+: Kullanıcı müdahalesi

# State dosya yolları
STATE_DIR = Path(".agent/state")
QUEUE_DIR = Path(".agent/queue")

# State tracking dosyası
RETRY_STATE_FILE = Path(".agent/state/validation-retries.json")


# ============================================================================
# RETRY STATE MANAGEMENT
# ============================================================================

class RetryManager:
    """Retry sayacı ve state yönetimi"""

    def __init__(self, state_file: Path = RETRY_STATE_FILE):
        self.state_file = state_file
        self.state = self._load_state()

    def _load_state(self) -> Dict[str, Dict[str, Any]]:
        """Retry state'i dosyadan yükle"""
        if self.state_file.exists():
            try:
                return json.loads(self.state_file.read_text(encoding="utf-8"))
            except Exception:
                return {}
        return {}

    def _save_state(self):
        """Retry state'i dosyaya kaydet"""
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        self.state_file.write_text(
            json.dumps(self.state, indent=2, ensure_ascii=False),
            encoding="utf-8"
        )

    def get_retry_count(self, file_path: str) -> int:
        """Dosya için retry sayısını al"""
        key = str(file_path)
        return self.state.get(key, {}).get("retry_count", 0)

    def increment_retry(self, file_path: str, error: str):
        """Retry sayısını artır"""
        key = str(file_path)

        if key not in self.state:
            self.state[key] = {
                "retry_count": 0,
                "first_error": error,
                "first_error_time": datetime.utcnow().isoformat() + "Z",
                "errors": []
            }

        self.state[key]["retry_count"] += 1
        self.state[key]["last_error"] = error
        self.state[key]["last_error_time"] = datetime.utcnow().isoformat() + "Z"
        self.state[key]["errors"].append({
            "attempt": self.state[key]["retry_count"],
            "error": error,
            "time": datetime.utcnow().isoformat() + "Z"
        })

        self._save_state()

    def reset_retry(self, file_path: str):
        """Başarılı olduktan sonra retry sayacını sıfırla"""
        key = str(file_path)
        if key in self.state:
            del self.state[key]
            self._save_state()

    def get_failure_history(self, file_path: str) -> Optional[Dict[str, Any]]:
        """Dosya için hata geçmişini al"""
        key = str(file_path)
        return self.state.get(key)


# Global retry manager
retry_manager = RetryManager()


# ============================================================================
# VALIDASYON FONKSİYONLARI
# ============================================================================

def validate_file(file_path: str) -> ValidationResult:
    """
    Dosyayı oku ve validate et

    Args:
        file_path: JSON dosya yolu

    Returns:
        ValidationResult objesi
    """
    path = Path(file_path)

    # Dosya var mı?
    if not path.exists():
        return ValidationResult(
            is_valid=False,
            error=f"Dosya bulunamadı: {file_path}"
        )

    # Dosyayı oku
    try:
        content = path.read_text(encoding="utf-8")
        data = json.loads(content)
    except json.JSONDecodeError as e:
        return ValidationResult(
            is_valid=False,
            error=f"JSON syntax hatası: {str(e)}"
        )
    except Exception as e:
        return ValidationResult(
            is_valid=False,
            error=f"Dosya okuma hatası: {str(e)}"
        )

    # Validate et
    return validate_json(data, file_path)


# ============================================================================
# RECOVERY STRATEGY
# ============================================================================

def handle_validation_failure(
    file_path: str,
    error: str,
    current_data: Optional[Dict[str, Any]] = None
) -> Tuple[bool, str, Optional[Dict[str, Any]]]:
    """
    Validasyon başarısız olduğunda recovery strategy uygula

    Args:
        file_path: Başarısız dosya yolu
        error: Validasyon hatası
        current_data: Mevcut (hatalı) veri

    Returns:
        (success, action_taken, suggested_data)
    """

    retry_count = retry_manager.get_retry_count(file_path)
    retry_manager.increment_retry(file_path, error)

    # STRATEJI 1: Otomatik Retry (0-1)
    if retry_count < AUTO_RETRY_LIMIT:
        return False, f"auto-retry-{retry_count + 1}", None

    # STRATEJI 2: DLQ'ya al (2-4)
    elif retry_count < DLQ_RETRY_LIMIT:
        # Eğer task queue ise, task'ı DLQ'ya taşı
        if "tasks-" in file_path and "dead-letter" not in file_path:
            dlq_data = create_dlq_entry(file_path, current_data, error, retry_count)
            return False, "moved-to-dlq", dlq_data

        return False, "requires-dlq-review", None

    # STRATEJI 3: Kullanıcı müdahalesi (5+)
    else:
        return False, "requires-user-intervention", None


def create_dlq_entry(
    file_path: str,
    current_data: Optional[Dict[str, Any]],
    error: str,
    retry_count: int
) -> Optional[Dict[str, Any]]:
    """
    DLQ girişi oluştur

    Args:
        file_path: Başarısız dosya
        current_data: Hatalı veri
        error: Hata mesajı
        retry_count: Retry sayısı

    Returns:
        DLQ entry dict
    """

    # Eğer task varsa, onu DLQ task'ına çevir
    if current_data and "tasks" in current_data:
        tasks = current_data.get("tasks", [])

        if tasks:
            # İlk failed task'ı al
            failed_task = tasks[0]

            # DLQ task'a çevir
            dlq_task = DLQTask(
                id=failed_task.get("id", str(uuid.uuid4())),
                type=failed_task.get("type", "unknown"),
                agent=failed_task.get("agent", "unknown"),
                status="dead-letter",
                priority=failed_task.get("priority", 5),
                createdAt=failed_task.get("createdAt", datetime.utcnow().isoformat() + "Z"),
                attempts=retry_count + 1,
                maxAttempts=failed_task.get("maxAttempts", 3),
                payload=failed_task.get("payload", {}),
                failureReason=f"Validation failed after {retry_count + 1} attempts",
                suggestedFix=error,
                attemptHistory=retry_manager.get_failure_history(file_path).get("errors", []),
                requiresManualReview=True,
                dlqTimestamp=datetime.utcnow().isoformat() + "Z",
                error={"message": error, "type": "ValidationError"}
            ).model_dump()

            return dlq_task

    return None


def add_to_dlq(dlq_task: Dict[str, Any]) -> bool:
    """
    Task'ı DLQ'ya ekle

    Args:
        dlq_task: DLQ task dict

    Returns:
        Başarılı mı?
    """

    dlq_file = QUEUE_DIR / "tasks-dead-letter.json"

    # DLQ dosyasını oku veya oluştur
    if dlq_file.exists():
        try:
            dlq_data = json.loads(dlq_file.read_text(encoding="utf-8"))
        except Exception:
            dlq_data = {"tasks": [], "metadata": {}}
    else:
        dlq_data = {"tasks": [], "metadata": {}}

    # Task'ı ekle
    dlq_data["tasks"].append(dlq_task)
    dlq_data["metadata"]["lastUpdated"] = datetime.utcnow().isoformat() + "Z"
    dlq_data["metadata"]["version"] = "1.0.0"

    # Yaz
    dlq_file.parent.mkdir(parents=True, exist_ok=True)
    dlq_file.write_text(json.dumps(dlq_data, indent=2, ensure_ascii=False), encoding="utf-8")

    return True


# ============================================================================
# WRITE WITH VALIDATION
# ============================================================================

def safe_write_json(file_path: str, data: Dict[str, Any], source: str = "unknown") -> Tuple[bool, str]:
    """
    JSON dosyasını validate ederek yaz

    Args:
        file_path: Dosya yolu
        data: Yazılacak veri
        source: Kaynak (LLM, script, etc.)

    Returns:
        (success, message)
    """

    # Önce validate et
    result = validate_json(data, file_path)

    if result.is_valid:
        # Valid: Dosyayı yaz
        path = Path(file_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(
            json.dumps(data, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8"
        )

        # Retry counter'ı sıfırla
        retry_manager.reset_retry(file_path)

        return True, f"✅ {file_path} başarıyla yazıldı"

    # Valid başarısız: Recovery strategy
    else:
        success, action, suggested_data = handle_validation_failure(
            file_path,
            result.error,
            data
        )

        if action.startswith("auto-retry"):
            return False, f"⚠️ {file_path} validation başarısız: {result.error}\n   → Retry {action.split('-')[-1]} öneriliyor"

        elif action == "moved-to-dlq":
            if suggested_data:
                add_to_dlq(suggested_data)
            return False, f"⚠️ {file_path} validation başarısız: {result.error}\n   → DLQ'ya taşındı"

        elif action == "requires-user-intervention":
            return False, f"🔴 {file_path} validation başarısız: {result.error}\n   → Kullanıcı müdahalesi gerekli (retry: {retry_manager.get_retry_count(file_path)})"

        else:
            return False, f"❌ {file_path} validation başarısız: {result.error}"


# ============================================================================
# CLI
# ============================================================================

def print_validation_result(file_path: str, result: ValidationResult, verbose: bool = False):
    """Validasyon sonucunu yazdır"""

    if result.is_valid:
        print(f"✅ {file_path}")
    else:
        print(f"❌ {file_path}")
        print(f"   Hata: {result.error}")

        if verbose:
            history = retry_manager.get_failure_history(file_path)
            if history:
                print(f"   Retry geçmişi: {history.get('retry_count', 0)} deneme")


def cmd_validate(args):
    """validate: Dosya veya dizin validate et"""

    if not args:
        print("Kullanım: python validate.py validate <file_or_dir>")
        return 1

    target = Path(args[0])

    if target.is_file():
        # Tek dosya
        result = validate_file(str(target))
        print_validation_result(str(target), result, verbose=True)
        return 0 if result.is_valid else 1

    elif target.is_dir():
        # Dizin: Tüm JSON dosyalarını validate et
        json_files = list(target.rglob("*.json"))
        json_files = [f for f in json_files if "schemas-generated" not in str(f)]

        if not json_files:
            print(f"⚠️ {target} dizininde JSON dosyası bulunamadı")
            return 0

        print(f"🔍 {len(json_files)} JSON dosyası validate ediliyor...\n")

        passed = 0
        failed = 0

        for json_file in json_files:
            result = validate_file(str(json_file))
            print_validation_result(str(json_file), result, verbose=False)

            if result.is_valid:
                passed += 1
            else:
                failed += 1

        print(f"\n📊 Sonuç: {passed} ✅, {failed} ❌")
        return 0 if failed == 0 else 1

    else:
        print(f"❌ Bulunamadı: {target}")
        return 1


def cmd_validate_state(args):
    """validate-state: State dosyalarını validate et"""

    state_files = [
        STATE_DIR / "circuits.json",
        QUEUE_DIR / "tasks-pending.json",
        QUEUE_DIR / "tasks-in-progress.json",
        QUEUE_DIR / "tasks-completed.json",
        QUEUE_DIR / "tasks-failed.json",
        QUEUE_DIR / "tasks-dead-letter.json",
    ]

    print("🔍 State dosyaları validate ediliyor...\n")

    all_passed = True

    for state_file in state_files:
        if state_file.exists():
            result = validate_file(str(state_file))
            print_validation_result(str(state_file), result, verbose=True)

            if not result.is_valid:
                all_passed = False
        else:
            print(f"⚠️ {state_file} (mevcut değil)")

    return 0 if all_passed else 1


def cmd_retry_status(args):
    """retry-status: Retry durumlarını göster"""

    state = retry_manager.state

    if not state:
        print("✅ Aktif retry yok")
        return 0

    print(f"📊 Retry Durumu ({len(state)} dosya):\n")

    for file_path, info in state.items():
        retry_count = info.get("retry_count", 0)
        last_error = info.get("last_error", "Unknown")

        status_emoji = "🔴" if retry_count >= USER_INTERVENTION_LIMIT else "⚠️"
        print(f"{status_emoji} {file_path}")
        print(f"   Retry: {retry_count}")
        print(f"   Son hata: {last_error[:80]}...")
        print()

    return 0


def cmd_retry_reset(args):
    """retry-reset: Retry sayacını sıfırla"""

    if not args:
        print("Kullanım: python validate.py retry-reset <file_path>")
        return 1

    file_path = args[0]
    retry_manager.reset_retry(file_path)

    print(f"✅ {file_path} retry sayacı sıfırlandı")
    return 0


def cmd_export_schemas(args):
    """export-schemas: JSON Schema export"""

    output_dir = args[0] if args else ".agent/config/schemas-generated"

    try:
        from schemas import export_schemas
        exported = export_schemas(output_dir)
        print(f"✅ {len(exported)} schema export edildi: {output_dir}")
        for f in exported:
            print(f"   - {f}")
        return 0
    except Exception as e:
        print(f"❌ Export hatası: {e}")
        return 1


def print_help():
    """Yardım menüsü"""
    print("""
Odin AI Agent System - JSON Validator

Kullanım:
  python validate.py <command> [args]

Komutlar:
  validate <file_or_dir>     JSON dosya veya dizin validate et
  validate-state             Tüm state dosyalarını validate et
  retry-status               Aktif retry durumlarını göster
  retry-reset <file>         Dosyanın retry sayacını sıfırla
  export-schemas [dir]       JSON Schema export (varsayılan: .agent/config/schemas-generated)
  help                       Bu yardım menüsünü göster

Örnekler:
  python validate.py validate-state
  python validate.py validate .agent/state/circuits.json
  python validate.py retry-status
  python validate.py export-schemas

Recovery Strategy:
  - Retry 0-1:   Otomatik retry (LLM'a hata gösterilir)
  - Retry 2-4:   DLQ'ya al (manuel müdahale gerekli)
  - Retry 5+:    Kullanıcı müdahalesi zorunlu
""")


# ============================================================================
# MAIN ENTRY POINT
# ============================================================================

def main():
    """Ana entry point"""

    if len(sys.argv) < 2:
        print_help()
        return 1

    command = sys.argv[1]
    args = sys.argv[2:]

    commands = {
        "validate": cmd_validate,
        "validate-state": cmd_validate_state,
        "retry-status": cmd_retry_status,
        "retry-reset": cmd_retry_reset,
        "export-schemas": cmd_export_schemas,
        "help": print_help,
    }

    if command not in commands:
        print(f"❌ Bilinmeyen komut: {command}")
        print_help()
        return 1

    return commands[command](args)


if __name__ == "__main__":
    sys.exit(main())
