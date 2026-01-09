# CLAUDE.md - Autonomous AI Development Agent

> Bu dosya, Claude AI'nin bu çalışma alanında nasıl davranacağını tanımlar.
> **Sürüm 1.0** - Otonom AI Geliştirme Orchestrator
> **Son Güncelleme:** 2026-01-09

---

## 🔴 KESİN KURAL: TÜRKÇE KONUŞMA VE RAPORLAMA (ZORUNLU)

**Her konuşma, rapor ve çıktı TÜRKÇE olmalıdır.**

### Bu Ne Demek?

| ❌ YANLIŞ | ✅ DOĞRU |
|----------|---------|
| "I'll analyze the project" | "Projeyi analiz edeceğim" |
| "Here's the result:" | "İşte sonuç:" |
| "Task completed successfully" | "Görev başarıyla tamamlandı" |
| "Error occurred" | "Hata oluştu" |
| "Waiting for user input" | "Kullanıcı girişi bekleniyor" |

### 🌐 Dil Yönetimi

**Kullanıcı Türkçe yazdığında:**
1. ✅ Yanıt TÜRKÇE olmalı
2. ✅ Raporlar TÜRKÇE olmalı
3. ✅ Hata mesajları TÜRKÇE olmalı
4. ✅ Kod yorumları TÜRKÇE olmalı
5. ❌ Code değişkenleri İNGILIZCE kalmalı (standard)

**Örnek:**
```typescript
// ✅ DOĞRU - Türkçe yorum, İngilizce değişken
const userCount = getUsers().length; // Kullanıcı sayısını al

// ❌ YANLIŞ - Türkçe değişken
const kullanicisayisi = getUsers().length;
```

> 🔴 **TÜRKÇE raporlama = ZORUNLU. İstisna yok.**

---

## 🎯 SİSTEM HAKKINDA

Bu çalışma alanında **Otonom AI Geliştirme Sistemi** kurulu:

### Bileşenler

| Bileşen | Konum | Açıklama |
|---------|-------|----------|
| **Skill Orchestrator** | `.claude/skills/autonomous-dev.mdc` | Ana koordinatör |
| **Agent System** | `.agent/prompts/agents/` | 25 specialized agent |
| **Circuit Breaker** | `.agent/state/circuits.json` | Hata koruması |
| **Queue System** | `.agent/queue/tasks-*.json` | Task yönetimi |
| **MCP Tools** | GitHub + Web research | Araştırma araçları |

### Sistem Kapasitesi

```
┌─────────────────────────────────────────┐
│ 25 SPECIALIZED AGENT                    │
├─────────────────────────────────────────┤
│ Core (3): orchestrator, planner, analyst│
│ Development (8): frontend, backend...   │
│ Research (4): researcher, competitive...│
│ Quality (5): reviewer-code, security... │
│ Support (5): testing, fixer, debugger...│
└─────────────────────────────────────────┘
```

---

## 🔴 KESİN KURAL: SIMPLE vs COMPLEX ANALİZİ (ZORUNLU)

**Her prompt önce analiz edilmeli.**

### Task Karar Ağacı

```
USER PROMPT
    │
    ▼
ANALİZ: Simple mi? Complex mi?
    │
    ├─→ SIMPLE (Basit)
    │   • Tek dosya değişikliği
    │   • Araştırma gerektirmez
    │   • DOĞRUDAN TOOLS KULLAN
    │   └─→ Grep, Read, Edit, Write
    │
    └─→ COMPLEX (Karmaşık)
        • Multi-step işlem
        • Araştırma gerektirir
        • AGENT DELEGATION
        └─→ Agent prompt + MCP tools
```

### Simple Task Örnekleri

| Prompt | Tip | Aksiyon |
|--------|------|---------|
| "Header'daki 'About' yazısını değiştir" | Simple | Grep → Read → Edit |
| "Console.log'ları sil" | Simple | Grep → Edit |
| "Button rengini mavi yap" | Simple | Grep → Read → Edit |
| "Yeni component oluştur: Button.tsx" | Simple | Write |

**✅ DOĞRU:** Direct tools kullan, agent çağırma.
**❌ YANLIŞ:** Simple task için agent kullan (overhead).

### Complex Task Örnekleri

| Prompt | Tip | Agent'lar |
|--------|------|-----------|
| "User authentication system oluştur" | Complex | backend, database, security, frontend |
| "React hooks araştır" | Complex | researcher + MCP |
| "Performance optimization yap" | Complex | performance + architect |
| "E-ticaret sitesi geliştir" | Complex | 10+ agent |

**✅ DOĞRU:** Agent delegation, Circuit Breaker kontrolü.
**❌ YANLIŞ:** Direct tools kullan (yetersiz).

---

## 🔴 KESİN KURAL: CIRCUIT BREAKER KONTROLÜ (ZORUNLU)

**Agent execution öncesi mutlaka kontrol et.**

### Kontrol Akışı

```bash
# Agent çalışmadan önce:
jq ".circuits.{agent-type}.state" .agent/state/circuits.json

┌─────────────────────────────────────────┐
│ DURUM: CLOSED ✅                        │
│ → Agent'i çalıştır                     │
│ → Başarısızlık sayacı tut              │
│ → 3 hata → Circuit trip (OPEN)        │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ DURUM: OPEN 🔴                         │
│ → Agent'i atla                        │
│ → Alternatif agent kullan             │
│ → Veya DLQ'ya gönder                  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ DURUM: HALF_OPEN 🟡                    │
│ → 1 test task dene                    │
│ → Başarılı → CLOSED                   │
│ → Başarısız → OPEN                    │
└─────────────────────────────────────────┘
```

### Agent-Specific Thresholds

| Agent | Max Hata | Timeout | Neden |
|-------|----------|---------|-------|
| orchestrator | 5 | 600s | Ana koordinatör |
| database | 2 | 180s | Hızlı timeout |
| security | 2 | 240s | Kritik işlemler |
| fixer | 4 | 360s | D fazla deneme |
| diğerleri | 3 | 300s | Varsayılan |

> 🔴 **Circuit OPEN = Agent bloke. Alternatif bul veya DLQ.**

---

## 🔴 KESİN KURAL: MCP TOOLS KULLANIMI (ZORUNLU)

**Agent araştırma yaparken MCP tools kullan.**

### Araştırma Workflow

```markdown
Agent research yapacak:

1. GitHub Code Search
   Tool: mcp__github__search_code
   Query: "{tech stack} {feature} example"
   Amaç: Gerçek kod örnekleri bul

2. Web Search
   Tool: mcp__duckduckgo__search
   Query: "best practices {tech stack} {feature}"
   Amaç: Best practices araştır

3. Web Content Reader
   Tool: mcp__web_reader__webReader
   URL: {documentation URL}
   Amaç: Dokümantasyon oku

4. Synthesize
   • Bulguları birleştir
   • Yaklaşım öner
   • Kod üret
```

### MCP Tools

| Tool | Kullanım | Örnek Query |
|------|----------|-------------|
| `mcp__github__search_code` | Kod örneği bul | "React hooks useState pattern" |
| `mcp__github__search_repositories` | Repo bul | "JWT authentication Node.js" |
| `mcp__github__get_file_contents` | GitHub dosyası oku | Implementation example |
| `mcp__duckduckgo__search` | Web ara | "best practices React 2024" |
| `mcp__web_reader__webReader` | Web içeriği oku | Documentation URL |

> 🔴 **Araştırma yapmazsan → Eksiz bilgi → Kötü kod.**

---

## 🔴 KESİN KURAL: AGENT PROMPT OKUMA (ZORUNLU)

**Agent çalıştırmadan önce prompt dosyasını oku.**

### Agent Prompt Yapısı

```markdown
Agent type: {agent-type}
Location: .agent/prompts/agents/{agent-type}.md

İçerik:
├── Capabilities (Yetenekler)
├── Tasks (Görev tanımı)
├── Code Quality Standards
├── Tools to Use
├── Output Format
└── Common Patterns
```

### Okuma Zorunluluğu

```
❌ YANLIŞ:
"Frontend agent çalıştıracağım"
→ Direkt kod yazmaya başla

✅ DOĞRU:
"Frontend agent çalıştıracağım"
→ 1. Read .agent/prompts/agents/frontend.md
→ 2. Capabilities anla
→ 3. Code quality standards oku
→ 4. Output formatı öğren
→ 5. Sonra kod yaz
```

### Agent Kategorileri

| Kategori | Agent Sayısı | Agent'lar |
|----------|--------------|-----------|
| **Core** | 3 | orchestrator, planner, analyst |
| **Development** | 8 | frontend, backend, mobile, database, api-design, security, performance, architect |
| **Research** | 4 | researcher, competitive, documentation, config |
| **Quality** | 5 | reviewer-code, reviewer-security, reviewer-performance, reviewer-business, reviewer-ui |
| **Support** | 5 | testing, fixer, deps, build, debugger |

> 🔴 **Prompt okumadan agent çalıştırma = Yetersiz sonuç.**

---

## 🔄 HATA YÖNETİMİ: DLQ VE RETRY

**Hatalı task'lar otomatik yönetilir.**

### Retry Akışı

```
Task Başarısız
    │
    ▼
Retry 1 (60s bekle)
    │
    ▼
Retry 2 (120s bekle)
    │
    ▼
Retry 3 (240s bekle)
    │
    ▼
Tüm retry'lar başarısız
    │
    ▼
DLQ (Dead Letter Queue)
    │
    ▼
Manuel müdahale gerekli
```

### DLQ Komutları

```bash
# DLQ durumunu gör
bash .agent/scripts/queue.sh dlq

# Detaylı incele
bash .agent/scripts/queue.sh dlq-review

# Task'ı pending'e geri al (retry)
bash .agent/scripts/queue.sh dlq-retry <task-id>

# Task'ı atla (completed olarak işaretle)
bash .agent/scripts/queue.sh dlq-skip <task-id>

# Task'ı sil
bash .agent/scripts/queue.sh dlq-delete <task-id>
```

### DLQ Schema

```json
{
  "id": "task-uuid",
  "reason": "Max retries exceeded (3)",
  "lastError": {
    "type": "ValidationError",
    "message": "Component already exists",
    "suggestedFix": "Delete or skip"
  },
  "attemptHistory": [
    { "attempt": 1, "agent": "frontend-001", "error": "..." },
    { "attempt": 2, "agent": "frontend-001", "error": "..." },
    { "attempt": 3, "agent": "frontend-002", "error": "..." }
  ],
  "requiresManualReview": true,
  "suggestedActions": ["Check file exists", "Delete or skip"]
}
```

---

## 🔴 KESİN KURAL: JSON VALIDASYONU (ZORUNLU)

**LLM çıktıları doğrudan dosyaya yazılmamalı, önce validate edilmeli.**

### Validasyon Katmanı

```python
# ❌ YANLIŞ - Doğrudan yazma
LLM Output → JSON dosyaya yaz → { unutursa → Sistem çöker

# ✅ DOĞRU - Validasyonlu yazma
LLM Output → Pydantic Validation → Valid JSON → State'e yaz
```

### Validasyon Akışı

```
┌─────────────────────────────────────────────────────────────────┐
│                    JSON VALIDATION LAYER                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  LLM Output                                                      │
│     │                                                            │
│     ▼                                                            │
│  validate.py (Pydantic Schema Validation)                       │
│     │                                                            │
│     ├─ Circuit State Schema                                     │
│     ├─ Task Queue Schema                                        │
│     ├─ DLQ Schema                                               │
│     └─ Orchestrator State Schema                                │
│     │                                                            │
│     ▼                                                            │
│  Validation Result                                              │
│     │                                                            │
│     ├─ ✅ Valid → Dosyaya yaz                                    │
│     └─ ❌ Invalid → Recovery Strategy                            │
│                                                                  │
│  Recovery Strategy:                                             │
│  • Retry 0-1:   Otomatik retry (LLM'a hata gösterilir)           │
│  • Retry 2-4:   DLQ'ya al (manuel müdahale gerekli)              │
│  • Retry 5+:    Kullanıcı müdahalesi zorunlu                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Kritik State Dosyaları (Validasyon Zorunlu)

| Dosya | Schema | Açıklama |
|-------|--------|----------|
| `.agent/state/circuits.json` | CircuitState | Circuit Breaker durumları |
| `.agent/queue/tasks-pending.json` | TaskQueue | Bekleyen task'lar |
| `.agent/queue/tasks-in-progress.json` | TaskQueue | Sürmekte olan task'lar |
| `.agent/queue/tasks-completed.json` | TaskQueue | Tamamlanan task'lar |
| `.agent/queue/tasks-failed.json` | TaskQueue | Başarısız task'lar |
| `.agent/queue/tasks-dead-letter.json` | DLQueue | Dead Letter Queue |

### Validasyon Komutları

```bash
# Tüm state dosyalarını validate et
bash .agent/scripts/validate-cli.sh validate-state

# Tek bir dosya validate et
bash .agent/scripts/validate-cli.sh validate .agent/state/circuits.json

# Tüm kritik dosyaları validate et
bash .agent/scripts/validate-cli.sh validate-all

# Retry durumlarını gör
bash .agent/scripts/validate-cli.sh retry-status

# Retry sayacını sıfırla
bash .agent/scripts/validate-cli.sh retry-reset <dosya_yolu>

# JSON Schema export
bash .agent/scripts/validate-cli.sh export-schemas

# Validasyon testleri
bash .agent/scripts/validate-cli.sh test
```

### Python ile Direkt Kullanım

```bash
# State dosyalarını validate et
python .agent/scripts/validate.py validate-state

# Tekil dosya validate et
python .agent/scripts/validate.py validate .agent/queue/tasks-pending.json

# Dizin validate et
python .agent/scripts/validate.py validate .agent/queue/

# Retry durumu
python .agent/scripts/validate.py retry-status

# Retry sıfırla
python .agent/scripts/validate.py retry-reset .agent/queue/tasks-pending.json

# Schema export
python .agent/scripts/validate.py export-schemas .agent/config/schemas-generated
```

### Schema Test

```bash
# Pydantic schema'larını test et
python .agent/scripts/schemas.py test

# Beklenen çıktı:
# 🧪 Schema testleri çalıştırılıyor...
# Circuit State: ✅ PASS
# Task Queue: ✅ PASS
# ✅ Tüm testler başarılı!
```

### Recovery Strategy Detayları

```markdown
Validasyon başarısız olduğunda:

1. Retry 0-1 (İlk 2 deneme):
   - Otomatik retry
   - LLM'a hatayı göster
   - "Bu JSON hatası var: {error}. Lütfen düzelt."

2. Retry 2-4 (3-5. deneme):
   - DLQ'ya taşı
   - Manuel müdahale gerekli
   - Task dead-letter queue'ye eklenir

3. Retry 5+ (6. deneme ve sonrası):
   - Kullanıcı müdahalesi zorunlu
   - Sistem durdurulur
   - Kullanıcıya manuel düzeltme bildirimi
```

### Validasyon Örnekleri

```python
# ✅ DOĞRU - Validasyonlu yazma
from scripts.validate import safe_write_json

data = {
    "version": "1.0.0",
    "lastUpdated": "2025-01-08T10:00:00Z",
    "circuits": {
        "frontend": {
            "state": "CLOSED",
            "failCount": 0,
            # ...
        }
    }
}

success, message = safe_write_json(
    ".agent/state/circuits.json",
    data,
    source="orchestrator"
)

if not success:
    print(f"❌ Validasyon başarısız: {message}")
    # Recovery strategy devreye girer
```

```bash
# ❌ YANLIŞ - Doğrudan yazma (validasyonsuz)
echo '{"state": "CLOSED", "failCount": 0}' > .agent/state/circuits.json
# → JSON bozulabilir, sistem çökebilir

# ✅ DOĞRU - Validasyonlu yazma
python .agent/scripts/validate.py validate .agent/state/circuits.json
# → Validasyondan geçerse yazılır
```

> 🔴 **Validasyon olmadan state dosyası yazma = Sistem çökme riski.**

---

## 🔴 KESİN KURAL: VEKTÖR HAFIZA KULLANIMI (ÖNERİLEN)

**Büyük projelerde ve uzun süreli geliştirmede vektör hafıza kullan.**

### Nedir?

Vektör tabanlı hafıza sistemi (RAG), tamamlanan task'ları semantik olarak arar. Yeni bir task geldiğinde, daha önce yapılmış benzer task'ları bulur.

### Neden Gerekli?

```
┌─────────────────────────────────────────────────────────────────┐
│  MEVCUT SİSTEM (Proje büyüdükçe)                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1000+ task tamamlanmış                                          │
│       │                                                          │
│       ▼                                                          │
│  Yeni task: "User profile page"                                │
│       │                                                          │
│       ▼                                                          │
│  Problem:                                                       │
│  • 1000 task'ı context'e yüklemek yavaş                        │
│  • Eski decision'lar unutuluyor                                │
│  • Token limit aşılıyor                                        │
│  • Tutarlılık kaybı                                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  RAG SİSTEMİ (Proje büyüse bile)                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1000+ task vektöre indekslenmiş                                │
│       │                                                          │
│       ▼                                                          │
│  Yeni task: "User profile page"                                │
│       │                                                          │
│       ▼                                                          │
│  Vektör arama: "En benzer 5 task"                              │
│       │                                                          │
│       ▼                                                          │
│  Sonuç:                                                         │
│  • Sadece 5 task context'e geliyor                              │
│  • Tam alakalı task'lar                                       │
│  • Eski decision'lar hatırlanıyor                             │
│  • Tutarlı kod üretimi                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Kullanım Zorunluluğu

| Proje Durumu | RAG Gerekli? |
|---------------|--------------|
| Küçük (<50 task) | ❌ Hayır |
| Orta (50-200 task) | 🟡 Opsiyonel |
| Büyük (200+ task) | 🔴 Evet |

### İlk Kurulum

```bash
# 1. Dependency yükle
pip install sentence-transformers

# 2. İlk indeksleme
bash .agent/scripts/vector-cli.sh index

# 3. Test et
bash .agent/scripts/vector-cli.sh search "authentication"
```

### Günlük Kullanım

```bash
# Semantik arama (benzer task bul)
bash .agent/scripts/vector-cli.sh search "React form" 5

# İstatistikler
bash .agent/scripts/vector-cli.sh stats

# Otomatik indeksleme (Git hook)
bash .agent/scripts/vector-auto-index.sh install hook
```

### RAG Entegrasyonlu Task Workflow

```
Yeni Task Geldi
    │
    ▼
1. Vektör arama yap (ilgili 5 task bul)
   bash .agent/scripts/vector-cli.sh search "<task açıklaması>"
    │
    ▼
2. Bulunan task'ları context'e ekle
   "Önceki benzer task'lar: ... Bu pattern'ları takip et."
    │
    ▼
3. Agent'ı çalıştır
   Task prompt + Context → Agent execution
    │
    ▼
4. Task tamamlandı
   Otomatik vektör indeksine ekle
```

### Faydalar

- ✅ Proje büyüse bile hız sabit kalır
- ✅ Token kullanımı %90 azalır
- ✅ Eski decision'lar unutulmaz
- ✅ Tutarlı kod üretimi
- ✅ Context overflow yok

> 🔴 **Büyük projelerde RAG olmadan = Unutkanlık ve tutarsızlık.**

---

## 🔴 KESİN KURAL: OTONOM TDD SİSTEMİ (ZORUNLU)

**Testing agent çalıştırdığında TDD metodolojisini uygula.**

### TDD Prensipleri

```
┌─────────────────────────────────────────┐
│  1. TEST YAZ (Red)                      │
│     • Kod yazmadan ÖNCE test yaz        │
│     • Test başarısız olmalı (❌)         │
├─────────────────────────────────────────┤
│  2. KOD YAZ (Green)                     │
│     • Test'i geçecek minimal kod        │
│     • Test geçmeli (✅)                  │
├─────────────────────────────────────────┤
│  3. REFACTOR                            │
│     • Kodu temizle                      │
│     • Test hâlâ geçmeli (✅)             │
└─────────────────────────────────────────┘
```

### TDD Komutları

```bash
# Framework tespiti
bash .agent/scripts/tdd-cli.sh detect <project_path>

# Testleri çalıştır
bash .agent/scripts/tdd-cli.sh test <project_path>

# TDD döngüsü (max 3 deneme + auto-fix)
bash .agent/scripts/tdd-cli.sh cycle <project_path>

# Detaylı test raporu
bash .agent/scripts/tdd-cli.sh report <project_path>

# Sürekli izleme (watch mode)
bash .agent/scripts/tdd-cli.sh watch <project_path>
```

### Quality Gates

**Konum:** `.agent/config/quality-gates.yaml`

| Kriter | Değer | Açıklama |
|--------|-------|----------|
| **Coverage** | ≥80% | Kod kapsama oranı |
| **Critical Hata** | 0 | Sıfır kritik hata |
| **High Hata** | 0 | Sıfır yüksek öncelikli hata |
| **Medium Hata** | ≤3 | Maksimum 3 orta hata |
| **Low Hata** | ≤10 | Maksimum 10 düşük hata |

### Auto-Fix Workflow

```
Test Başarısız
    │
    ▼
Deneme 1 (60s bekle)
    │
    ▼
Kodu analiz et → Hata tespit
    │
    ▼
Kodu düzelt → Testi tekrar çalıştır
    │
    ├─→ BAŞARILI ✅ → Devam et
    │
    └─→ BAŞARISIZ ❌
        │
        ▼
Deneme 2 (120s bekle)
        │
        ├─→ BAŞARILI ✅ → Devam et
        │
        └─→ BAŞARISIZ ❌
            │
            ▼
Deneme 3 (240s bekle)
            │
            ├─→ BAŞARILI ✅ → Devam et
            │
            └─→ BAŞARISIZ ❌
                │
                ▼
DLQ'ya gönder → Manuel müdahale gerekli
```

### Supported Frameworks

| Dil | Framework'ler |
|-----|---------------|
| JavaScript/TypeScript | Jest, Vitest, Mocha |
| Python | Pytest |
| Go | go test |
| Rust | cargo test |

### Faydalar

- ✅ Test-First Development (TDD) prensibi
- ✅ Otomatik test framework tespiti
- ✅ Quality gates ile kalite kontrolü
- ✅ Auto-fix ile kendi kendini düzelten kod
- ✅ Coverage takibi

> 🔴 **TDD olmadan kod yazma = Kalitesiz kod ve bug'lar.**

---

## 📊 SİSTEM YÖNETİM KOMUTLARI

### Circuit Breaker Yönetimi

```bash
# Genel durum
bash .agent/scripts/circuit.sh status

# Tüm circuit'lar listesi (renkli)
bash .agent/scripts/circuit.sh list

# Spesifik agent circuit'i
bash .agent/scripts/circuit.sh agent frontend

# Circuit'i manuel aç (test için)
bash .agent/scripts/circuit.sh trip backend

# Circuit'i manuel kapat (kurtarma)
bash .agent/scripts/circuit.sh reset backend
```

### Queue Yönetimi

```bash
# Tüm queue durumları
bash .agent/scripts/queue.sh status

# Pending tasks
bash .agent/scripts/queue.sh pending

# In-progress tasks
bash .agent/scripts/queue.sh in-progress

# Completed tasks
bash .agent/scripts/queue.sh completed

# Failed tasks
bash .agent/scripts/queue.sh failed

# DLQ tasks
bash .agent/scripts/queue.sh dlq
```

### Orchestrator Komutları

```bash
# Proje analizi
bash .agent/scripts/orchestrate.sh analyze

# Kod içinde arama
bash .agent/scripts/orchestrate.sh search "function"

# Dosya bulma
bash .agent/scripts/orchestrate.sh find "*.tsx"

# Uzantıya göre listeleme
bash .agent/scripts/orchestrate.sh list tsx
```

### Dashboard

```bash
# Tek seferlik göster
bash .agent/scripts/dashboard.sh

# Auto-refresh modu (5 saniyede bir)
bash .agent/scripts/dashboard.sh --watch

# Interactive mod (menü ile yönetim)
bash .agent/scripts/dashboard.sh --loop
```

**Dashboard Özellikleri:**

| Özellik | Açıklama |
|---------|----------|
| **Circuit Breaker Status** | 26 circuit'in durumu (Closed/Open/Half-Open) |
| **Queue Status** | Pending, In-Progress, Completed, Failed sayıları |
| **Dead Letter Queue** | Başarısız task sayısı ve uyarı |
| **Blocked Agents** | Engellenmiş agent listesi |
| **Recent Activity** | Son 5 tamamlanan task |
| **System Health** | Sistem sağlık durumu |

**Interactive Komutlar:**

| Komut | Açıklama |
|-------|----------|
| **[R]** | Dashboard'u yenile |
| **[Q]** | Çıkış |
| **[C]** | Circuit Breaker detaylı liste |
| **[D]** | Dead Letter Queue görüntüle |
| **[H]** | Yardım menüsü |

---

## 🎯 ÖRNEK EXECUTION FLOWLARI

### Example 1: Simple Task

```
Kullanıcı: "Header'daki 'About' yazısını 'Hakkında' yap"
    ↓
Analiz: Simple task (tek dosya değişikliği)
    ↓
Grep("About") → Found: src/Header.tsx
    ↓
Read(src/Header.tsx) → Line 23: <About />
    ↓
Edit(src/Header.tsx, "About", "Hakkında")
    ↓
Sonuç: ✅ "Yazı değiştirildi: src/Header.tsx:23"
```

**Süre:** ~3 saniye
**Agent:** Yok (direct tools)

---

### Example 2: Complex Task

```
Kullanıcı: "User authentication system oluştur, JWT ile"
    ↓
Analiz: Complex task (multi-step)
    ↓
Planner: 8 sub-task'a böl
    ├─ backend: API endpoints (2)
    ├─ backend: JWT logic (1)
    ├─ database: User schema (1)
    ├─ database: Session storage (1)
    ├─ frontend: Login form (1)
    ├─ frontend: Register form (1)
    ├─ security: Password hashing (1)
    └─ security: Token validation (1)
    ↓
Circuit Check: Tüm agent'lar CLOSED ✅
    ↓
Parallel Execution (max 5):
    ├─ backend agent → MCP: GitHub search "JWT auth"
    ├─ database agent → MCP: Web search "PostgreSQL user schema"
    ├─ security agent → MCP: GitHub "bcrypt hashing"
    ├─ frontend agent → MCP: Web "React form validation"
    └─ architect agent → System design review
    ↓
Queue Update: pending → in-progress → completed
    ↓
Sonuç: ✅ "8 task tamamlandı, 12 dosya oluşturuldu"
```

**Süre:** ~5 dakika
**Agent'lar:** 5 (parallel)
**MCP Tools:** GitHub + Web search + Reader

---

### Example 3: Hata Yönetimi

```
Task: Create API endpoint
    ↓
Agent: backend
    ↓
Hata: Missing dependency 'zod'
    ↓
Retry 1 (60s) → Başarısız
    ↓
Retry 2 (120s) → Başarısız
    ↓
Retry 3 (240s) → Başarısız
    ↓
Circuit: backend.state → "OPEN"
    ↓
DLQ: tasks-dead-letter.json
    ↓
Kullanıcıya mesaj:
"⚠️ Task DLQ'ya taşındı. Manuel müdahale gerekli.
 Çalıştır: bash .agent/scripts/queue.sh dlq-review"
```

---

## 📝 ÇIKTI FORMATI

### Başarılı Execution

```markdown
## 📊 Sonuç

**Durum:** ✅ Başarılı
**Görev:** {açıklama}
**Agent'lar:** {sayı}
**Süre:** {zaman}

### Yapılan Değişiklikler
- {dosyalar}

### Detaylar
{spesifik değişiklikler}

### Sonraki Adımlar
{öneriler}
```

### Başarısız Execution

```markdown
## ❌ Hata

**Görev:** {açıklama}
**Hata:** {hata mesajı}

### Problem
{detaylı açıklama}

### Önerilen Çözüm
{çözüm önerisi}

### DLQ Durumu
Task: tasks-dead-letter.json
ID: {task-id}
Komut: bash .agent/scripts/queue.sh dlq-review
```

---

## ⚠️ ÖNEMLİ NOTLAR

1. **TÜRKÇE Raporlama Zorunlu** - Her çıktı Türkçe olmalı
2. **Simple vs Complex Analizi** - Her prompt önce analiz edilmeli
3. **Circuit Breaker Kontrol** - Agent execution öncesi kontrol
4. **JSON Validasyonu Zorunlu** - State dosyaları yazmadan önce validate et
5. **Vektör Hafıza Kullanımı (Önerilen)** - Büyük projelerde RAG kullan
6. **MCP Tools Kullanımı** - Araştırma için GitHub + Web
7. **Agent Prompt Okuma** - Agent çalıştırmadan önce prompt oku
8. **DLQ Yönetimi** - 3 retry'den sonra manuel müdahale
9. **Direct Tools** - Simple task'lar için agent yok
10. **Agent Delegation** - Complex task'lar için multi-agent

---

## 🔗 Hızlı Referans

| Task Tipi | Agent | Tools | Süre | Validasyon | RAG |
|-----------|-------|-------|------|------------|-----|
| Text change | Yok | Grep, Read, Edit | 2-5s | Hayır | Hayır |
| File create | Yok | Write | 5-10s | Hayır | Hayır |
| State write | Yok | validate.py + Write | 2-5s | **Evet** | Hayır |
| Research | researcher | MCP (GitHub, Web) | 30-60s | Hayır | Opsiyonel |
| Single agent | {type} | Agent prompt + MCP | 1-3m | State için evet | Opsiyonel |
| Multi-agent | 5+ | Parallel + MCP | 5-15m | State için evet | Opsiyonel |

**Not:** RAG (Vektör Hafıza) 200+ task'lı projelerde önerilir.

---

**Sürüm:** 1.1 - Autonomous AI Development Agent + RAG
**Son Güncelleme:** 2026-01-09
**Durum:** ✅ Production Ready
