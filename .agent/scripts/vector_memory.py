#!/usr/bin/env python3
"""
Odin AI Agent System - Vector Memory (RAG)
Vektör Tabanlı Hafıza Sistemi - Tamamlanan task'ları semantik arama

Bu sistem, tamamlanan task'ları vektörleştirir ve yeni task'lar geldiğinde
semantik olarak en alakalı eski task'ları bulur.

Version: 1.0.0
Author: Odin AI System
"""

import json
import sqlite3
import sys
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
import numpy as np
from datetime import datetime

# ============================================================================
# EMBEDDING MODEL
# ============================================================================

try:
    from sentence_transformers import SentenceTransformer
    MODEL_AVAILABLE = True
except ImportError:
    MODEL_AVAILABLE = False
    MODEL_INSTALL_MSG = """
⚠️ sentence_transformers yüklü değil.

Kurulum için:
    pip install sentence-transformers

Veya:
    pip install sentence-transformers[onnx]  # Daha hafif versiyon

Detaylı bilgi: https://www.sbert.net/
"""


# ============================================================================
# VECTOR MEMORY CLASS
# ============================================================================

class VectorMemory:
    """
    Vektör Tabanlı Hafıza Sistemi

    Tamamlanan task'ları vektörleştirir ve semantik arama yapar.
    SQLite + Sentence-Transformers kullanır.
    """

    def __init__(
        self,
        db_path: str = ".agent/state/vector-memory.db",
        model_name: str = "all-MiniLM-L6-v2"
    ):
        """
        VectorMemory başlat

        Args:
            db_path: SQLite DB dosya yolu
            model_name: Sentence-transformers model adı
                      - all-MiniLM-L6-v2: Hafif, hızlı (384 boyut)
                      - all-mpnet-base-v2: Daha准确 (768 boyut)
        """
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(parents=True, exist_ok=True)

        # Embedding modelini yükle
        if MODEL_AVAILABLE:
            try:
                self.model = SentenceTransformer(model_name)
                self.embedding_dim = self.model.get_sentence_embedding_dimension()
                self.model_name = model_name
            except Exception as e:
                print(f"❌ Model yükleme hatası: {e}")
                self.model = None
                self.embedding_dim = 0
        else:
            self.model = None
            self.embedding_dim = 0
            print(MODEL_INSTALL_MSG)

        # DB'yi başlat
        self._init_db()

    def _init_db(self):
        """SQLite vektör DB'yi oluştur"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        # Task tablosu
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                description TEXT NOT NULL,
                agent TEXT,
                type TEXT,
                status TEXT,
                priority INTEGER,
                created_at TEXT,
                completed_at TEXT,
                payload_json TEXT,
                result_json TEXT,
                embedding BLOB,
                metadata_json TEXT,
                indexed_at TEXT
            )
        """)

        # Index'ler
        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_agent
            ON tasks(agent)
        """)

        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_status
            ON tasks(status)
        """)

        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_type
            ON tasks(type)
        """)

        cursor.execute("""
            CREATE INDEX IF NOT EXISTS idx_completed_at
            ON tasks(completed_at)
        """)

        # Metadata tablosu (sistem bilgileri)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS metadata (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at TEXT
            )
        """)

        # Schema version
        self._set_metadata(conn, 'schema_version', '1.0.0')
        self._set_metadata(conn, 'model_name', getattr(self, 'model_name', 'none'))

        conn.commit()
        conn.close()

    def _set_metadata(self, conn, key: str, value: str):
        """Metadata kaydet"""
        cursor = conn.cursor()
        cursor.execute("""
            INSERT OR REPLACE INTO metadata (key, value, updated_at)
            VALUES (?, ?, ?)
        """, (key, value, datetime.utcnow().isoformat() + "Z"))

    def _get_metadata(self, conn, key: str) -> Optional[str]:
        """Metadata oku"""
        cursor = conn.cursor()
        cursor.execute("SELECT value FROM metadata WHERE key = ?", (key,))
        row = cursor.fetchone()
        return row[0] if row else None

    # ========================================================================
    # EKLEME
    # ========================================================================

    def add_task(self, task: Dict[str, Any]) -> bool:
        """
        Task'ı vektör DB'ye ekle

        Args:
            task: Task objesi (tasks-completed.json formatında)

        Returns:
            Başarılı mı?
        """
        if not self.model:
            print("❌ Embedding model yok, task eklenemiyor")
            return False

        task_id = task.get('id')
        if not task_id:
            print("❌ Task ID gerekli")
            return False

        # Embedding text'i oluştur
        text_to_embed = self._create_embedding_text(task)

        # Embedding yap
        try:
            embedding = self.model.encode(text_to_embed, convert_to_numpy=True)
        except Exception as e:
            print(f"❌ Embedding hatası: {e}")
            return False

        # SQLite'a kaydet
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        try:
            cursor.execute("""
                INSERT OR REPLACE INTO tasks
                (id, description, agent, type, status, priority, created_at, completed_at,
                 payload_json, result_json, embedding, metadata_json, indexed_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                task_id,
                task.get('description', ''),
                task.get('agent', ''),
                task.get('type', ''),
                task.get('status', ''),
                task.get('priority', 5),
                task.get('createdAt', ''),
                task.get('completedAt', ''),
                json.dumps(task.get('payload', {}), ensure_ascii=False),
                json.dumps(task.get('result', {}), ensure_ascii=False),
                embedding.tobytes(),  # Numpy array → bytes
                json.dumps(task.get('metadata', {}), ensure_ascii=False),
                datetime.utcnow().isoformat() + "Z"
            ))

            conn.commit()
            return True

        except Exception as e:
            print(f"❌ Task ekleme hatası: {e}")
            return False

        finally:
            conn.close()

    def add_tasks(self, tasks: List[Dict[str, Any]]) -> Tuple[int, int]:
        """
        Birden fazla task'ı toplu ekle

        Args:
            tasks: Task listesi

        Returns:
            (Başarılı sayısı, Başarısız sayısı)
        """
        success_count = 0
        fail_count = 0

        for task in tasks:
            if self.add_task(task):
                success_count += 1
            else:
                fail_count += 1

        return success_count, fail_count

    def _create_embedding_text(self, task: Dict[str, Any]) -> str:
        """
        Task'tan embedding text'i oluştur

        Semantik arama için en alakalı bilgileri birleştirir.
        """
        parts = []

        # Description (en önemli)
        if 'description' in task:
            parts.append(task['description'])

        # Payload description
        payload = task.get('payload', {})
        if isinstance(payload, dict):
            if 'description' in payload:
                parts.append(payload['description'])

            # Requirements
            if 'requirements' in payload and isinstance(payload['requirements'], list):
                parts.extend(payload['requirements'])

            # Context
            if 'context' in payload and isinstance(payload['context'], dict):
                for key, value in payload['context'].items():
                    parts.append(f"{key}: {value}")

        # Agent type
        if 'agent' in task:
            parts.append(f"Agent: {task['agent']}")

        # Task type
        if 'type' in task:
            parts.append(f"Type: {task['type']}")

        return ". ".join(parts)

    # ========================================================================
    # ARAMA
    # ========================================================================

    def search(
        self,
        query: str,
        top_k: int = 5,
        agent_filter: Optional[str] = None,
        type_filter: Optional[str] = None,
        min_similarity: float = 0.0
    ) -> List[Dict[str, Any]]:
        """
        Semantik arama

        Args:
            query: Arama metni
            top_k: Kaç sonuç döndürülecek?
            agent_filter: Sadece belirli agent'ları ara
            type_filter: Sadece belirli task type'ları ara
            min_similarity: Minimum benzerlik skoru (0-1)

        Returns:
            İlgili task'lar (benzerlik sıralı)
        """
        if not self.model:
            print("❌ Embedding model yok, arama yapılamıyor")
            return []

        # Query embedding
        try:
            query_embedding = self.model.encode(query, convert_to_numpy=True)
        except Exception as e:
            print(f"❌ Query embedding hatası: {e}")
            return []

        # SQL sorgusu oluştur
        sql = "SELECT id, description, agent, type, status, priority, created_at, completed_at, payload_json, result_json, metadata_json, embedding FROM tasks WHERE status = 'completed'"
        params = []

        if agent_filter:
            sql += " AND agent = ?"
            params.append(agent_filter)

        if type_filter:
            sql += " AND type = ?"
            params.append(type_filter)

        # DB'den oku
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        try:
            cursor.execute(sql, params)
            rows = cursor.fetchall()
        except Exception as e:
            print(f"❌ DB okuma hatası: {e}")
            conn.close()
            return []

        conn.close()

        # Benzerlik hesapla
        results = []
        for row in rows:
            (task_id, description, agent, type_, status, priority,
             created_at, completed_at, payload_json, result_json,
             metadata_json, embedding_bytes) = row

            # Embedding bytes → numpy array
            try:
                stored_embedding = np.frombuffer(embedding_bytes, dtype=np.float32)
            except Exception:
                continue

            # Cosine similarity
            similarity = self._cosine_similarity(query_embedding, stored_embedding)

            if similarity >= min_similarity:
                results.append({
                    'id': task_id,
                    'description': description,
                    'agent': agent,
                    'type': type_,
                    'status': status,
                    'priority': priority,
                    'similarity': float(similarity),
                    'created_at': created_at,
                    'completed_at': completed_at,
                    'payload': json.loads(payload_json) if payload_json else {},
                    'result': json.loads(result_json) if result_json else {},
                    'metadata': json.loads(metadata_json) if metadata_json else {}
                })

        # Sırala ve top_k döndür
        results.sort(key=lambda x: x['similarity'], reverse=True)
        return results[:top_k]

    def _cosine_similarity(self, a: np.ndarray, b: np.ndarray) -> float:
        """Cosine similarity hesapla"""
        try:
            return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
        except Exception:
            return 0.0

    # ========================================================================
    # INDEKSLEME
    # ========================================================================

    def index_completed_tasks(
        self,
        tasks_file: str = ".agent/queue/tasks-completed.json"
    ) -> Tuple[int, int]:
        """
        Tamamlanmış task'ları vektör DB'ye indeksle

        Args:
            tasks_file: Task queue dosyası

        Returns:
            (Başarılı, Başarısız) sayısı
        """
        tasks_path = Path(tasks_file)

        if not tasks_path.exists():
            print(f"⚠️ {tasks_file} bulunamadı")
            return 0, 0

        # Task'ları oku
        try:
            with open(tasks_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except Exception as e:
            print(f"❌ Dosya okuma hatası: {e}")
            return 0, 0

        tasks = data.get('tasks', [])

        if not tasks:
            print("⚠️ İndekslenecek task yok")
            return 0, 0

        print(f"📊 {len(tasks)} task indeksleniyor...")

        success, fail = self.add_tasks(tasks)

        print(f"✅ {success}/{len(tasks)} task indekslendi")
        if fail > 0:
            print(f"⚠️ {fail} task başarısız")

        return success, fail

    def index_all_queues(self) -> Dict[str, Tuple[int, int]]:
        """
        Tüm queue dosyalarını indeksle

        Returns:
            Her queue için (success, fail) sayısı
        """
        queue_dir = Path(".agent/queue")
        results = {}

        queue_files = [
            ("tasks-completed.json", "completed"),
            ("tasks-in-progress.json", "in-progress"),
            ("tasks-failed.json", "failed"),
        ]

        for filename, queue_type in queue_files:
            file_path = queue_dir / filename
            if file_path.exists():
                print(f"\n📂 {filename} indeksleniyor...")
                success, fail = self.index_completed_tasks(str(file_path))
                results[queue_type] = (success, fail)

        return results

    # ========================================================================
    # ISTATISTIKLER
    # ========================================================================

    def get_stats(self) -> Dict[str, Any]:
        """DB istatistikleri"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        # Toplam task
        cursor.execute("SELECT COUNT(*) FROM tasks")
        total = cursor.fetchone()[0]

        # Duruma göre
        cursor.execute("SELECT status, COUNT(*) FROM tasks GROUP BY status")
        by_status = dict(cursor.fetchall())

        # Agent'lara göre
        cursor.execute("SELECT agent, COUNT(*) FROM tasks GROUP BY agent")
        by_agent = dict(cursor.fetchall())

        # Type'lara göre
        cursor.execute("SELECT type, COUNT(*) FROM tasks GROUP BY type")
        by_type = dict(cursor.fetchall())

        # En son indeksleme
        cursor.execute("SELECT MAX(indexed_at) FROM tasks")
        last_indexed = cursor.fetchone()[0]

        # Metadata
        schema_version = self._get_metadata(conn, 'schema_version')
        model_name = self._get_metadata(conn, 'model_name')

        conn.close()

        return {
            'total_tasks': total,
            'by_status': by_status,
            'by_agent': by_agent,
            'by_type': by_type,
            'last_indexed': last_indexed,
            'schema_version': schema_version,
            'model_name': model_name,
            'db_size_mb': self.db_path.stat().st_size / (1024 * 1024) if self.db_path.exists() else 0
        }

    # ========================================================================
    # BAKIM
    # ========================================================================

    def clear_all(self) -> bool:
        """Tüm task'ları sil"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("DELETE FROM tasks")
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            print(f"❌ Temizleme hatası: {e}")
            return False

    def delete_task(self, task_id: str) -> bool:
        """Tek task sil"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            print(f"❌ Silme hatası: {e}")
            return False

    def optimize_db(self) -> bool:
        """DB'yi optimize et (VACUUM)"""
        try:
            conn = sqlite3.connect(self.db_path)
            conn.execute("VACUUM")
            conn.close()
            return True
        except Exception as e:
            print(f"❌ Optimizasyon hatası: {e}")
            return False


# ============================================================================
# CLI
# ============================================================================

def print_success(msg: str):
    print(f"✅ {msg}")


def print_error(msg: str):
    print(f"❌ {msg}")


def print_warning(msg: str):
    print(f"⚠️  {msg}")


def print_info(msg: str):
    print(f"ℹ️  {msg}")


def cmd_index(args):
    """Task'ları indeksle"""
    if not MODEL_AVAILABLE:
        print_error("sentence_transformers yüklü değil.")
        print_info("Kurulum: pip install sentence-transformers")
        return 1

    vector_memory = VectorMemory()

    if len(args) > 0 and args[0] == "--all":
        # Tüm queue'ları indeksle
        results = vector_memory.index_all_queues()

        print("\n📊 İndeksleme Özeti:")
        for queue_type, (success, fail) in results.items():
            print(f"   {queue_type}: {success} başarı, {fail} başarısız")

        return 0

    else:
        # Sadece completed tasks
        tasks_file = args[0] if args else ".agent/queue/tasks-completed.json"
        success, fail = vector_memory.index_completed_tasks(tasks_file)

        if fail == 0:
            return 0
        else:
            return 1


def cmd_search(args):
    """Semantik arama"""
    if not MODEL_AVAILABLE:
        print_error("sentence_transformers yüklü değil.")
        return 1

    if len(args) < 1:
        print_error("Kullanım: python vector_memory.py search <query> [top_k]")
        return 1

    query = args[0]
    top_k = int(args[1]) if len(args) > 1 else 5

    vector_memory = VectorMemory()

    results = vector_memory.search(query, top_k=top_k)

    if not results:
        print_warning(f"'{query}' için sonuç bulunamadı")
        return 0

    print(f"\n🔍 '{query}' arama sonuçları ({len(results)}):\n")

    for i, result in enumerate(results, 1):
        similarity_pct = result['similarity'] * 100

        # Benzerlik rengi
        if similarity_pct >= 80:
            emoji = "🟢"
        elif similarity_pct >= 60:
            emoji = "🟡"
        else:
            emoji = "🔵"

        print(f"{i}. {emoji} [{result['agent']}] {result['description']}")
        print(f"   Benzerlik: {similarity_pct:.1f}%")
        print(f"   Tarih: {result['completed_at']}")
        print(f"   ID: {result['id']}")

        if result.get('payload'):
            payload = result['payload']
            if isinstance(payload, dict) and payload.get('requirements'):
                print(f"   Requirements: {', '.join(payload['requirements'])}")

        print()

    return 0


def cmd_stats(args):
    """İstatistikler"""
    vector_memory = VectorMemory()
    stats = vector_memory.get_stats()

    print("📊 Vektör DB İstatistikleri:")
    print()
    print(f"   Toplam task: {stats['total_tasks']}")
    print(f"   DB boyutu: {stats['db_size_mb']:.2f} MB")
    print(f"   Model: {stats['model_name']}")
    print(f"   Schema: {stats['schema_version']}")
    print()

    if stats['by_status']:
        print("   Duruma göre:")
        for status, count in stats['by_status'].items():
            print(f"     • {status}: {count}")
        print()

    if stats['by_agent']:
        print("   Agent'lara göre:")
        for agent, count in sorted(stats['by_agent'].items(), key=lambda x: x[1], reverse=True):
            print(f"     • {agent}: {count}")
        print()

    if stats['by_type']:
        print("   Type'lara göre:")
        for type_, count in sorted(stats['by_type'].items(), key=lambda x: x[1], reverse=True):
            print(f"     • {type_}: {count}")
        print()

    if stats['last_indexed']:
        print(f"   Son indeksleme: {stats['last_indexed']}")

    return 0


def cmd_clear(args):
    """Tüm veriyi sil"""
    vector_memory = VectorMemory()

    if len(args) > 0 and args[0] == "--confirm":
        if vector_memory.clear_all():
            print_success("Tüm veri silindi")
            return 0
        else:
            return 1
    else:
        print_warning("--confirm parametresi gerekli")
        print_info("Kullanım: python vector_memory.py clear --confirm")
        return 1


def cmd_optimize(args):
    """DB'yi optimize et"""
    vector_memory = VectorMemory()

    if vector_memory.optimize_db():
        print_success("DB optimize edildi")
        return 0
    else:
        return 1


def cmd_test(args):
    """Test çalıştır"""
    if not MODEL_AVAILABLE:
        print_error("sentence_transformers yüklü değil.")
        return 1

    print("🧪 RAG Sistemi Testi\n")

    vector_memory = VectorMemory()

    # Test task'ları
    test_tasks = [
        {
            'id': 'test-001',
            'description': 'JWT authentication endpoint implementation',
            'agent': 'backend',
            'type': 'feature',
            'status': 'completed',
            'priority': 5,
            'createdAt': '2025-01-08T10:00:00Z',
            'completedAt': '2025-01-08T12:00:00Z',
            'payload': {
                'description': 'Express.js ile JWT auth endpoint',
                'requirements': ['Node.js', 'Express', 'jsonwebtoken'],
                'context': {'auth_type': 'JWT'}
            },
            'metadata': {},
            'result': {'files': ['src/api/auth.ts']}
        },
        {
            'id': 'test-002',
            'description': 'User login form component',
            'agent': 'frontend',
            'type': 'feature',
            'status': 'completed',
            'priority': 5,
            'createdAt': '2025-01-08T11:00:00Z',
            'completedAt': '2025-01-08T13:00:00Z',
            'payload': {
                'description': 'React login form with validation',
                'requirements': ['React', 'TypeScript', 'Form validation'],
                'context': {'route': '/login'}
            },
            'metadata': {},
            'result': {'files': ['src/components/LoginForm.tsx']}
        },
        {
            'id': 'test-003',
            'description': 'Password hashing with bcrypt',
            'agent': 'security',
            'type': 'feature',
            'status': 'completed',
            'priority': 8,
            'createdAt': '2025-01-08T09:00:00Z',
            'completedAt': '2025-01-08T11:30:00Z',
            'payload': {
                'description': 'Bcrypt password hashing implementation',
                'requirements': ['bcrypt', 'Node.js', 'Security'],
                'context': {'rounds': 12}
            },
            'metadata': {},
            'result': {'files': ['src/utils/hash.ts']}
        }
    ]

    # 1. Test ekle
    print("1. Test task'ları ekleniyor...")
    success, fail = vector_memory.add_tasks(test_tasks)
    print(f"   ✅ {success}/{len(test_tasks)} eklendi")

    if fail > 0:
        print(f"   ⚠️ {fail} başarısız")

    # 2. İstatistikler
    print("\n2. İstatistikler:")
    stats = vector_memory.get_stats()
    print(f"   Toplam task: {stats['total_tasks']}")

    # 3. Semantik arama testleri
    print("\n3. Semantik Arama Testleri:")

    test_queries = [
        ("OAuth2 login system", "authentication ile ilgili task bul"),
        ("React form component", "frontend form task'ı bul"),
        ("Password security", "security ile ilgili task bul"),
    ]

    for query, description in test_queries:
        print(f"\n   Query: '{query}' ({description})")
        results = vector_memory.search(query, top_k=2)

        if results:
            for i, result in enumerate(results, 1):
                print(f"   {i}. {result['description']} ({result['similarity']:.2f})")
        else:
            print("   Sonuç bulunamadı")

    # 4. Temizle
    print("\n4. Test verileri temizleniyor...")
    for task in test_tasks:
        vector_memory.delete_task(task['id'])
    print("   ✅ Temizlendi")

    print("\n✅ Tüm testler başarılı!")
    return 0


def print_help():
    """Yardım menüsü"""
    print("""
Odin AI Agent System - Vector Memory (RAG)

Kullanım:
  python vector_memory.py <command> [args]

Komutlar:
  index [file]          Task'ları indeksle (varsayılan: tasks-completed.json)
  index --all           Tüm queue dosyalarını indeksle
  search <query> [k]    Semantik arama (varsayılan top_k: 5)
  stats                 İstatistikler
  clear --confirm       Tüm veriyi sil
  optimize              DB'yi optimize et
  test                  Test çalıştır
  help                  Bu yardım menüsü

Örnekler:
  # İlk indeksleme
  python vector_memory.py index

  # Semantik arama
  python vector_memory.py search "authentication system"
  python vector_memory.py search "React form" 3

  # İstatistikler
  python vector_memory.py stats

  # Test
  python vector_memory.py test

Dependency:
  pip install sentence-transformers
    """)


def main():
    """Ana entry point"""
    if len(sys.argv) < 2:
        print_help()
        return 1

    command = sys.argv[1]
    args = sys.argv[2:]

    commands = {
        'index': cmd_index,
        'search': cmd_search,
        'stats': cmd_stats,
        'clear': cmd_clear,
        'optimize': cmd_optimize,
        'test': cmd_test,
        'help': print_help,
    }

    if command not in commands:
        print_error(f"Bilinmeyen komut: {command}")
        print_help()
        return 1

    return commands[command](args)


if __name__ == '__main__':
    sys.exit(main())
