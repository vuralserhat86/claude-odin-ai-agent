# 📥 ODIN AI Agent System - Kurulum Rehberi

**Version:** 1.1.0
**Durum:** Production Ready
**Platform:** Claude Code (Windows, macOS, Linux)

---

## 🎯 Hızlı Kurulum (2 Dakika)

### 1. Özellikler

| Özellik | Açıklama |
|---------|----------|
| **25 Specialized Agent** | Frontend, Backend, Database, Security, Testing... |
| **Circuit Breaker** | Hatalı agent'ları otomatik engelle |
| **Dead Letter Queue** | Başarısız task'ları yönet |
| **MCP Tools** | 5 MCP server (GitHub, Z.ai search/reader/image) |
| **Auto Analysis** | Simple vs Complex task ayrımı |
| **Türkçe Raporlama** | Tam Türkçe konuşma ve kodlama |

---

## 🚀 Kurulum Yöntemleri

### Yöntem 1: Global Otomatik (Önerilen)

✅ **Avantajlar:** Tüm projelerde otomatik çalışır
⏱️ **Süre:** 2 dakika

#### Adım 1: Repoyu Klonla

```bash
git clone https://github.com/KULLANICI/odin-ai-agent.git
cd odin-ai-agent
```

#### Adım 2: Global Klasöre Kopyala

**Windows:**
```bash
# Agent sistemini kopyala
xcopy /E /I .agent C:\Users\KULLANICI\.claude\.agent\
xcopy /E /I .claude\skills C:\Users\KULLANICI\.claude\skills\

# CLAUDE.md'yi kopyala
copy CLAUDE.md C:\Users\KULLANICI\.claude\CLAUDE.md
```

**macOS/Linux:**
```bash
# Agent sistemini kopyala
cp -r .agent ~/.claude/.agent
cp -r .claude/skills ~/.claude/skills

# CLAUDE.md'yi kopyala
cp CLAUDE.md ~/.claude/CLAUDE.md
```

#### Adım 3: Session Hooks Yapılandır

**Windows:** `%USERPROFILE%\.claude\settings.json`
**macOS/Linux:** `~/.claude/settings.json`

```json
{
  "hooks": {
    "startup": [
      {
        "type": "loadFile",
        "path": "~/.claude/CLAUDE.md"
      },
      {
        "type": "command",
        "command": "echo '🪦 Odin AI Agent System v1.1.0 Loaded'"
      }
    ]
  }
}
```

#### Adım 4: Test Et

Claude Code'u aç ve şu komutu ver:

```
Odin sistemini test et
```

---

### Yöntem 2: Proje İçi Manuel

✅ **Avantajlar:** Proje ile birlikte Git'te takip edilir
⏱️ **Süre:** 30 saniye

#### Adım 1: Repoyu Klonla

```bash
git clone https://github.com/KULLANICI/odin-ai-agent.git
cd odin-ai-agent
```

#### Adım 2: Kullanmaya Başla

Claude Code'u bu klasörde aç ve prompt ver:

```
Projeyi analiz et
```

---

### Yöntem 3: Hibrit (En İyi)

✅ **Avantajlar:** Hem global hem proje içi
⏱️ **Süre:** 3 dakika

#### Adım 1: Global Kurulum (Yöntem 1)

```bash
cp -r .agent ~/.claude/.agent
cp -r .claude/skills ~/.claude/skills
cp CLAUDE.md ~/.claude/CLAUDE.md
```

#### Adım 2: Her Proje İçin

```bash
cd my-project

# Symlink oluştur (macOS/Linux)
ln -s ~/.claude/.agent .agent

# Veya kopyala (Windows)
xcopy /E /I C:\Users\KULLANICI\.claude\.agent .agent
```

---

## 🔍 Kurulum Doğrulama

### Test Et

Claude Code'a şu prompt'u ver:

```
Odin sistem durumu nedir?
```

**Beklenen Çıktı:**
```
🪦 Odin AI Agent System v1.1.0

✅ Sistem Aktif
   - 25 agent hazır
   - MCP Tools: 5 server aktif
   - Circuit breaker: 26/26 CLOSED
   - Queue: 5 aktif
   - Knowledge base: 51 dosya
```

---

## 📁 Dosya Yapısı

```
odin-ai-agent/
├── .agent/
│   ├── config/           # Konfigürasyon (16 dosya)
│   ├── library/          # Knowledge base (51 dosya)
│   ├── prompts/          # Agent prompt'ları (26 dosya)
│   ├── scripts/          # Bash + Python script'leri (23 dosya)
│   ├── state/            # Runtime state (5 dosya)
│   └── queue/            # Task queue'leri (5 dosya)
├── .claude/
│   └── skills/           # autonomous-dev.mdc
├── CLAUDE.md             # Global kurallar
├── odin.py              # Ana CLI
├── README.md             # Sistem dokümantasyonu
└── INSTALL.md            # Bu dosya
```

---

## 🛠️ Kullanım

### CLI Komutları

```bash
# Yardım
python odin.py --help

# Görev ekle
python odin.py add "User authentication system oluştur" --agent backend --priority high

# Queue listele
python odin.py list --status pending

# Durum görüntüle
python odin.py status

# Sistem güncelle
python odin.py update
```

### Script Komutları

```bash
# Circuit breaker durum
bash .agent/scripts/circuit.sh status

# Queue durum
bash .agent/scripts/queue.sh status

# Validation
bash .agent/scripts/validate-cli.sh validate-state

# Dashboard
bash .agent/scripts/dashboard.sh --watch
```

---

## 🔧 Bağımlılıklar

### Gerekli Paketler

```bash
# Python 3.8+ gerekli
python --version

# İsteğe bağlı (RAG için)
pip install sentence-transformers

# İsteğe bağlı (CLI renkli çıktı için)
pip install rich typer
```

---

## 🐛 Sorun Giderme

### Sorun: "Python bulunamadı"

```bash
# Python 3.8+ kur
# Windows: python.org
# macOS: brew install python3
# Linux: sudo apt install python3
```

### Sorun: "Agent çalışmıyor"

```bash
# Circuit durumunu kontrol et
bash .agent/scripts/circuit.sh status

# Circuit'i sıfırla
bash .agent/scripts/circuit.sh reset <agent-type>
```

### Sorun: "Queue boş kalıyor"

```bash
# Queue'yu sıfırla
bash .agent/scripts/queue.sh clear

# Yeniden başlat
python odin.py update
```

---

## 📞 Destek

**Sorun mu buldun?**

1. `.agent/state/` dosyalarını kontrol et
2. Circuit breaker durumunu kontrol et
3. GitHub issue aç

---

## ✅ Kurulum Tamamlandı

Sistem kullanıma hazır! İlk prompt'unu vererek başlayabilirsin:

```
Merhaba Odin! Beni tanı
```

**Beklenen Yanıt:**
```
🪦 Odin AI Agent System v1.1.0

Merhaba! Ben Odin, 25 specialized agent ile otonom geliştirme sistemi.

Size nasıl yardımcı olabilirim?
- 🏗️ Proje geliştirme
- 🔍 Kod analizi
- 🐛 Bug fixing
- 📝 Dokümantasyon
- 🧪 Test yazma
...
```

---

**Versiyon:** 1.1.0
**Son Güncelleme:** 2026-01-10
**Durum:** ✅ Production Ready
