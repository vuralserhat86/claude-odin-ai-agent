#!/usr/bin/env python3
"""
Odin AI Agent System - Pydantic Schemas
JSON Schema Validation için tek kaynak of truth (Single source of truth)

Version: 1.0.0
"""

from pydantic import BaseModel, Field, field_validator
from typing import Literal, Optional, Dict, List, Any
from datetime import datetime
import json


# ============================================================================
# CIRCUIT BREAKER SCHEMAS
# ============================================================================

class CircuitState(BaseModel):
    """Tekil Circuit Breaker State Schema"""
    state: Literal["CLOSED", "OPEN", "HALF_OPEN"] = Field(
        description="Circuit durumu: CLOSED (normal), OPEN (bloke), HALF_OPEN (test)"
    )
    failCount: int = Field(
        ge=0,
        description="Ardışık başarısızlık sayısı"
    )
    lastFailureTime: Optional[str] = Field(
        default=None,
        description="Son başarısızlık zamanı (ISO 8601)"
    )
    lastSuccessTime: Optional[str] = Field(
        default=None,
        description="Son başarılı işlem zamanı (ISO 8601)"
    )
    nextRetryTime: Optional[str] = Field(
        default=None,
        description="Sonraki retry denemesi (ISO 8601)"
    )
    totalFailures: int = Field(
        ge=0,
        description="Toplam başarısızlık sayısı"
    )
    totalSuccesses: int = Field(
        ge=0,
        description="Toplam başarılı işlem sayısı"
    )

    @field_validator('state')
    @classmethod
    def validate_state(cls, v: str) -> str:
        """State değeri sadece geçerli değerler olabilir"""
        valid_states = {"CLOSED", "OPEN", "HALF_OPEN"}
        if v not in valid_states:
            raise ValueError(f"Geçersiz state: {v}. Geçerli değerler: {valid_states}")
        return v

    class Config:
        json_schema_extra = {
            "example": {
                "state": "CLOSED",
                "failCount": 0,
                "lastFailureTime": None,
                "lastSuccessTime": None,
                "nextRetryTime": None,
                "totalFailures": 0,
                "totalSuccesses": 0
            }
        }


class CircuitsRoot(BaseModel):
    """Tüm Circuit Breaker'lar için root schema"""
    version: str = Field(default="1.0.0")
    lastUpdated: str = Field(description="Son güncelleme zamanı (ISO 8601)")
    circuits: Dict[str, CircuitState] = Field(description="Agent tipine göre circuit'lar")


# ============================================================================
# TASK SCHEMAS
# ============================================================================

class TaskPayload(BaseModel):
    """Task payload içeriği - esnek structure"""
    description: str = Field(description="Task açıklaması")
    requirements: List[str] = Field(default_factory=list, description="Gereksinimler listesi")
    context: Dict[str, Any] = Field(default_factory=dict, description="Ek bağlam bilgisi")
    dependencies: List[str] = Field(default_factory=list, description="Bağımlı task ID'leri")


class TaskState(BaseModel):
    """Task State Schema - Tekil task"""
    id: str = Field(description="Benzersiz task ID (UUID)")
    type: str = Field(description="Task tipi (frontend, backend, etc.)")
    agent: str = Field(description="Atanan agent tipi")
    status: Literal["pending", "in-progress", "completed", "failed", "dead-letter"] = Field(
        description="Task durumu"
    )
    priority: int = Field(
        default=5,
        ge=1,
        le=10,
        description="Öncelik (1=kritik, 10=düşük)"
    )
    createdAt: str = Field(description="Oluşturma zamanı (ISO 8601)")
    updatedAt: Optional[str] = Field(default=None, description="Son güncelleme (ISO 8601)")
    attempts: int = Field(
        default=0,
        ge=0,
        description="Deneme sayısı"
    )
    maxAttempts: int = Field(
        default=3,
        ge=1,
        description="Maksimum deneme sayısı"
    )
    payload: TaskPayload = Field(description="Task içeriği")

    # Opsiyonel field'lar (error, result, etc.)
    error: Optional[Dict[str, Any]] = Field(default=None, description="Son hata bilgisi")
    result: Optional[Dict[str, Any]] = Field(default=None, description="Sonuç bilgisi")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Ek metadata")

    @field_validator('status')
    @classmethod
    def validate_status(cls, v: str) -> str:
        """Status değeri sadece geçerli değerler olabilir"""
        valid_statuses = {"pending", "in-progress", "completed", "failed", "dead-letter"}
        if v not in valid_statuses:
            raise ValueError(f"Geçersiz status: {v}. Geçerli değerler: {valid_statuses}")
        return v

    @field_validator('attempts')
    @classmethod
    def validate_attempts_not_exceed_max(cls, v: int, info) -> int:
        """Deneme sayısı maksimumu aşmamalı"""
        if 'maxAttempts' in info.data and v > info.data['maxAttempts']:
            raise ValueError(f"attempts ({v}) maxAttempts ({info.data['maxAttempts']}) değerini aşamaz")
        return v

    class Config:
        json_schema_extra = {
            "example": {
                "id": "task-001",
                "type": "feature",
                "agent": "frontend",
                "status": "pending",
                "priority": 5,
                "createdAt": "2025-01-08T10:00:00Z",
                "updatedAt": "2025-01-08T10:00:00Z",
                "attempts": 0,
                "maxAttempts": 3,
                "payload": {
                    "description": "Login form component oluştur",
                    "requirements": ["React", "TypeScript"],
                    "context": {},
                    "dependencies": []
                },
                "error": None,
                "result": None,
                "metadata": {}
            }
        }


class TaskQueue(BaseModel):
    """Task Queue Schema - Task listesi container"""
    tasks: List[TaskState] = Field(default_factory=list, description="Task listesi")
    metadata: Dict[str, Any] = Field(
        default_factory=lambda: {
            "version": "1.0.0",
            "lastUpdated": datetime.utcnow().isoformat() + "Z",
            "description": "Task queue"
        },
        description="Queue metadata"
    )


# ============================================================================
# DLQ (DEAD LETTER QUEUE) SCHEMA
# ============================================================================

class DLQTask(TaskState):
    """DLQ için task schema - ek field'larla"""
    failureReason: str = Field(description="DLQ'ya alma sebebi")
    suggestedFix: Optional[str] = Field(default=None, description="Önerilen çözüm")
    attemptHistory: List[Dict[str, Any]] = Field(
        default_factory=list,
        description="Deneme geçmişi"
    )
    requiresManualReview: bool = Field(default=True, description="Manuel müdahale gerekli mi?")
    dlqTimestamp: str = Field(description="DLQ'ya alma zamanı (ISO 8601)")


class DLQueue(BaseModel):
    """Dead Letter Queue Schema"""
    tasks: List[DLQTask] = Field(default_factory=list, description="DLQ task'ları")
    metadata: Dict[str, Any] = Field(
        default_factory=lambda: {
            "version": "1.0.0",
            "lastUpdated": datetime.utcnow().isoformat() + "Z",
            "description": "Tasks that failed after all retries"
        },
        description="DLQ metadata"
    )


# ============================================================================
# ORCHESTRATOR STATE SCHEMA
# ============================================================================

class OrchestratorState(BaseModel):
    """Ana Orchestrator State Schema"""
    version: str = Field(default="1.0.0")
    lastUpdated: str = Field(description="Son güncelleme (ISO 8601)")
    currentSession: Optional[str] = Field(default=None, description="Mevcut session ID")
    activeTasks: int = Field(ge=0, description="Aktif task sayısı")
    completedTasks: int = Field(ge=0, description="Tamamlanan task sayısı")
    failedTasks: int = Field(ge=0, description="Başarısız task sayısı")
    systemHealth: Literal["healthy", "degraded", "critical"] = Field(
        default="healthy",
        description="Sistem sağlık durumu"
    )
    lastActivity: Optional[str] = Field(default=None, description="Son aktivite (ISO 8601)")
    metadata: Dict[str, Any] = Field(default_factory=dict, description="Ek metadata")


# ============================================================================
# VALIDATION FONKSİYONLARI
# ============================================================================

class ValidationResult:
    """Validasyon sonucu container'ı"""
    def __init__(self, is_valid: bool, error: Optional[str] = None, data: Optional[Any] = None):
        self.is_valid = is_valid
        self.error = error
        self.data = data

    def __repr__(self) -> str:
        if self.is_valid:
            return f"ValidationResult(is_valid=True)"
        return f"ValidationResult(is_valid=False, error='{self.error}')"


def validate_circuit_state(data: Dict[str, Any]) -> ValidationResult:
    """
    Circuit state JSON validasyonu

    Args:
        data: JSON verisi (dict)

    Returns:
        ValidationResult objesi
    """
    try:
        validated = CircuitsRoot(**data)
        return ValidationResult(is_valid=True, data=validated)
    except Exception as e:
        return ValidationResult(is_valid=False, error=str(e))


def validate_task_queue(data: Dict[str, Any]) -> ValidationResult:
    """
    Task queue JSON validasyonu

    Args:
        data: JSON verisi (dict)

    Returns:
        ValidationResult objesi
    """
    try:
        validated = TaskQueue(**data)
        return ValidationResult(is_valid=True, data=validated)
    except Exception as e:
        return ValidationResult(is_valid=False, error=str(e))


def validate_dlq(data: Dict[str, Any]) -> ValidationResult:
    """
    Dead Letter Queue JSON validasyonu

    Args:
        data: JSON verisi (dict)

    Returns:
        ValidationResult objesi
    """
    try:
        validated = DLQueue(**data)
        return ValidationResult(is_valid=True, data=validated)
    except Exception as e:
        return ValidationResult(is_valid=False, error=str(e))


def validate_orchestrator_state(data: Dict[str, Any]) -> ValidationResult:
    """
    Orchestrator state JSON validasyonu

    Args:
        data: JSON verisi (dict)

    Returns:
        ValidationResult objesi
    """
    try:
        validated = OrchestratorState(**data)
        return ValidationResult(is_valid=True, data=validated)
    except Exception as e:
        return ValidationResult(is_valid=False, error=str(e))


# ============================================================================
# AUTO-DETECT VALIDATION
# ============================================================================

def validate_json(data: Dict[str, Any], file_path: str) -> ValidationResult:
    """
    Dosya yoluna göre otomatik schema seçimi ve validasyon

    Args:
        data: JSON verisi (dict)
        file_path: Dosya yolu (schema detection için)

    Returns:
        ValidationResult objesi
    """
    file_path_lower = file_path.lower()

    # Circuit state
    if "circuits.json" in file_path_lower:
        return validate_circuit_state(data)

    # Task queues
    elif "tasks-pending.json" in file_path_lower:
        return validate_task_queue(data)
    elif "tasks-in-progress.json" in file_path_lower:
        return validate_task_queue(data)
    elif "tasks-completed.json" in file_path_lower:
        return validate_task_queue(data)
    elif "tasks-failed.json" in file_path_lower:
        return validate_task_queue(data)
    elif "tasks-dead-letter.json" in file_path_lower:
        return validate_dlq(data)

    # Orchestrator state
    elif "orchestrator" in file_path_lower and "state" in file_path_lower:
        return validate_orchestrator_state(data)

    # Bilinmeyen dosya tipi
    else:
        return ValidationResult(
            is_valid=False,
            error=f"Bilinmeyen dosya tipi: {file_path}. Validasyon için tanımlı değil."
        )


# ============================================================================
# EXPORT UTILS
# ============================================================================

def export_schemas(output_dir: str = ".agent/config/schemas-generated"):
    """
    Pydantic şemalarından JSON Schema export

    CLI tool ile uyumluluk için kullanılabilir.

    Args:
        output_dir: Çıktı dizini
    """
    from pathlib import Path

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    schemas = {
        "circuit-state.json": CircuitsRoot.model_json_schema(),
        "task-queue.json": TaskQueue.model_json_schema(),
        "dlq.json": DLQueue.model_json_schema(),
        "orchestrator-state.json": OrchestratorState.model_json_schema(),
    }

    exported = []
    for filename, schema in schemas.items():
        file_path = output_path / filename
        file_path.write_text(json.dumps(schema, indent=2, ensure_ascii=False))
        exported.append(str(file_path))

    return exported


# ============================================================================
# CLI ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    import sys

    # Export modu
    if len(sys.argv) > 1 and sys.argv[1] == "export":
        output_dir = sys.argv[2] if len(sys.argv) > 2 else ".agent/config/schemas-generated"
        exported = export_schemas(output_dir)
        print(f"✅ {len(exported)} schema export edildi: {output_dir}")
        for f in exported:
            print(f"   - {f}")
        sys.exit(0)

    # Test modu
    elif len(sys.argv) > 1 and sys.argv[1] == "test":
        print("🧪 Schema testleri çalıştırılıyor...\n")

        # Circuit state test
        test_circuit = {
            "version": "1.0.0",
            "lastUpdated": "2025-01-08T10:00:00Z",
            "circuits": {
                "frontend": {
                    "state": "CLOSED",
                    "failCount": 0,
                    "lastFailureTime": None,
                    "lastSuccessTime": None,
                    "nextRetryTime": None,
                    "totalFailures": 0,
                    "totalSuccesses": 0
                }
            }
        }
        result = validate_circuit_state(test_circuit)
        print(f"Circuit State: {'✅ PASS' if result.is_valid else '❌ FAIL'}")

        # Task queue test
        test_task_queue = {
            "tasks": [],
            "metadata": {
                "version": "1.0.0",
                "lastUpdated": "2025-01-08T10:00:00Z"
            }
        }
        result = validate_task_queue(test_task_queue)
        print(f"Task Queue: {'✅ PASS' if result.is_valid else '❌ FAIL'}")

        print("\n✅ Tüm testler başarılı!")
        sys.exit(0)

    else:
        print("Kullanım:")
        print("  python schemas.py export [output_dir]  - JSON Schema export")
        print("  python schemas.py test                  - Schema testleri")
        sys.exit(1)
