# 🔗 Session Hooks - Nedir ve Nasıl Çalışır?

## 📖 Basit Tanım

**Session Hooks = Claude Code'un "otomatik başlatma" sistemi**

Her proje açılışında otomatik olarak çalışacak kodları tanımlar.

---

## 🎯 Analogi

```
Windows Başlangıcı:
├── Başlat → Programlar otomatik açılır
└── Örnek: Discord, Spotify otomatik başlar

Claude Code Session Hooks:
├── Proje aç → Sistem otomatik yüklenir
└── Örnek: CLAUDE.md otomatik okunur
```

---

## 🔄 Manuel vs Otomatik

### Manuel (Hooksuz)

```
1. Proje açılır
2. Kullanıcı prompt yazar
3. Claude sistemi anlamaya çalışır (bilgisi varsa)
```

**Sorun:** Her proje ayrı, kurulum gerekli

### Otomatik (Session Hooks ile)

```
1. Proje açılır
2. Claude Code settings.json'i okur
3. "startup" hook çalışır
4. CLAUDE.md otomatik yüklenir
5. Kullanıcı prompt yazar
6. Claude sistemi bilir (CLAUDE.md sayesinde)
```

**Avantaj:** Bir kez kur, tüm projelerde çalışır

---

## 🏗️ Mimari

```
┌─────────────────────────────────────────────────────┐
│ Claude Code Başlangıç                              │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ settings.json Oku                                 │
│ (~/.claude/settings.json)                         │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ "hooks" Bölümünü Bul                              │
│                                                  │
│ {                                                │
│   "hooks": {                                     │
│     "startup": [...]                             │
│   }                                              │
│ }                                                │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ "startup" Hook'ları Sırayla Çalıştır              │
│                                                  │
│ 1. loadFile → CLAUDE.md'yi yükle                │
│ 2. command → Sistem kurulum script'i çalıştır    │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│ Sistem Hazır                                      │
│                                                  │
│ • CLAUDE.md yüklendi                              │
│ • Global kurallar aktif                           │
│ • Agent sistemi hazır                             │
└─────────────────────────────────────────────────────┘
```

---

## 📋 settings.json Yapısı

### Konum

| Platform | Konum |
|----------|-------|
| **Windows** | `%USERPROFILE%\.claude\settings.json` |
| **macOS** | `~/.claude/settings.json` |
| **Linux** | `~/.claude/settings.json` |

### Temel Yapı

**Windows:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -Command \"Get-Content $env:USERPROFILE\\.claude\\CLAUDE.md\""
          }
        ]
      }
    ]
  }
}
```

**macOS/Linux:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "cat ~/.claude/CLAUDE.md"
          }
        ]
      }
    ]
  }
}
```

### Detaylı Yapı

**Windows:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -Command \"Get-Content $env:USERPROFILE\\.claude\\CLAUDE.md\"",
            "statusMessage": "🪦 Odin AI Agent System v1.0 yükleniyor..."
          }
        ]
      }
    ]
  }
}
```

**macOS/Linux:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "cat ~/.claude/CLAUDE.md",
            "statusMessage": "🪦 Odin AI Agent System v1.0 yükleniyor..."
          }
        ]
      }
    ]
  }
}
```

---

## 🔧 Hook Türleri

### 1. command (Komut Çalıştır)

**Windows:**
```json
{
  "type": "command",
  "command": "powershell -Command \"Get-Content $env:USERPROFILE\\.claude\\CLAUDE.md\""
}
```

**macOS/Linux:**
```json
{
  "type": "command",
  "command": "cat ~/.claude/CLAUDE.md"
}
```

**Ne Yapar?**
- Shell komutu çalıştırır
- Çıktıyı Claude context'ine ekler

**Kullanım Alanı:**
- Global kuralları yükle (CLAUDE.md oku)
- Sistem kurulum script'leri çalıştır
- State başlatma

### 2. prompt (LLM Prompt)

```json
{
  "type": "prompt",
  "prompt": "Analyze the following context: $ARGUMENTS"
}
```

**Ne Yapar?**
- LLM ile prompt değerlendirir
- Dinamik karar alma

**Kullanım Alanı:**
- Otomatik analiz
- Akıllı filtreleme

---

## 🎯 Odin için Session Hooks

### Önerilen Yapılandırma

**Windows:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -Command \"Get-Content $env:USERPROFILE\\.claude\\CLAUDE.md\"",
            "statusMessage": "🪦 Odin AI Agent System v1.0 yükleniyor..."
          }
        ]
      }
    ]
  }
}
```

**macOS/Linux:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "cat ~/.claude/CLAUDE.md",
            "statusMessage": "🪦 Odin AI Agent System v1.0 yükleniyor..."
          }
        ]
      }
    ]
  }
}
```

### Ne İçin?

| Hook | Amaç |
|------|------|
| **SessionStart** | Her oturum başlangıcında çalışır |
| **command** | CLAUDE.md'yi okur ve context'e ekler |
| **statusMessage** | Yükleme sırasında mesaj gösterir |

---

## 🚀 Kurulum Adımları

### Adım 1: Global Dosyaları Yerleştir

```bash
# .agent klasörünü global'e kopyala
cp -r .agent ~/.claude/.agent

# CLAUDE.md'yi global'e kopyala
cp CLAUDE.md ~/.claude/CLAUDE.md
```

### Adım 2: settings.json Oluştur

```bash
# Windows
notepad %USERPROFILE%\.claude\settings.json

# macOS/Linux
nano ~/.claude/settings.json
```

### Adım 3: İçeriği Yapıştır

**Windows için:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -Command \"Get-Content $env:USERPROFILE\\.claude\\CLAUDE.md\"",
            "statusMessage": "🪦 Odin AI Agent System v1.0 yükleniyor..."
          }
        ]
      }
    ]
  }
}
```

**macOS/Linux için:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "cat ~/.claude/CLAUDE.md",
            "statusMessage": "🪦 Odin AI Agent System v1.0 yükleniyor..."
          }
        ]
      }
    ]
  }
}
```

### Adım 4: Doğrula

```bash
# Claude Code'u aç
# Herhangi bir prompt ver:
"Nasılsın?"

# Beklenen çıktı:
# "Merhabalar! Odin AI Agent System aktif. Size nasıl yardımcı olabilirim?"
# (Türkçe yanıt veriyor çünkü CLAUDE.md yüklendi)
```

---

## 🤔 Sık Sorulan Sorular

### S: "Ana sisteme bağlamak" ne demek?

**C:** Hayır, "ana sisteme bağlamak" değil. Bu terim yanıltıcı.

**Doğrusu:** "Her projede otomatik aktif etmek"

```
❌ Yanlış Anlama:
"Sistemi Claude Code'un ana kaynağına bağlıyoruz"

✅ Doğru Anlama:
"Sistemi Claude Code'un her oturumda otomatik yükleyecek şekilde yapılandırıyoruz"
```

### S: Proje içi kurulum gerekir mi?

**C:** Hayır, global kurulum yeterli.

**Ama:** Proje içi de isterseniz hibrit kullanabilirsiniz.

```
Global: ~/.claude/.agent (tüm projelerde)
Proje: my-project/.agent (sadece bu proje)
```

### S: Session Hooks'u kaldırırsam ne olur?

**C:** Manuel çalışmanız gerekir.

```
Hooksuz:
├── Her projede .agent kopyala
├── Her projede CLAUDE.md kopyala
└── Manuel çağırma

Hook'lu:
├── Bir kez kur
└── Tüm projelerde otomatik
```

### S: Birden fazla hook olabilir mi?

**C:** Evet, sınırsız hook ekleyebilirsiniz.

**Windows:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          { "type": "command", "command": "powershell -Command \"Get-Content $env:USERPROFILE\\.claude\\CLAUDE.md\"" },
          { "type": "command", "command": "powershell -Command \"Get-Content $env:USERPROFILE\\.claude\\custom-rules.md\"" },
          { "type": "command", "command": "echo 'System ready'" }
        ]
      }
    ]
  }
}
```

**macOS/Linux:**
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": ".*",
        "hooks": [
          { "type": "command", "command": "cat ~/.claude/CLAUDE.md" },
          { "type": "command", "command": "cat ~/.claude/custom-rules.md" },
          { "type": "command", "command": "echo 'System ready'" }
        ]
      }
    ]
  }
}
```

### S: Hooks sırası önemli mi?

**C:** Evet, sırayla çalışırlar.

```
1. İlk hook → Çalışır
2. İkinci hook → Birinci bitince çalışır
3. ... → Sequential execution
```

---

## 🔍 Troubleshooting

### Sorun: "Hook çalışmıyor"

**Çözüm:**

1. settings.json konumunu kontrol et
```bash
# Windows
echo %USERPROFILE%\.claude\settings.json

# macOS/Linux
echo ~/.claude/settings.json
```

2. JSON formatını kontrol et
```bash
# Geçerli JSON mu?
cat ~/.claude/settings.json | python -m json.tool
```

3. Claude Code'u yeniden başlat

### Sorun: "CLAUDE.md bulunamıyor"

**Çözüm:**

1. Dosya konumunu kontrol et
```bash
ls -la ~/.claude/CLAUDE.md
```

2. Varsa yolu güncelle

**Windows:**
```json
{
  "type": "command",
  "command": "powershell -Command \"Get-Content C:\\tam\\yol\\CLAUDE.md\""
}
```

**macOS/Linux:**
```json
{
  "type": "command",
  "command": "cat /tam/yol/CLAUDE.md"
}
```

---

## 📊 Karşılaştırma

| Özellik | Manuel | Otomatik (Hooks) |
|---------|--------|------------------|
| **Kurulum** | Her projede | Bir kez |
| **Yönetim** | Zor | Kolay |
| **Git** | Takip edilir | Edilmez |
| **Esneklik** | Proje özel | Global |
| **Kullanım** | Manuel kopyalama | Otomatik yükleme |

---

## ✅ Kontrol Listesi

- [ ] Global klasör oluşturuldu (`~/.claude/`)
- [ ] `.agent` kopyalandı (`~/.claude/.agent/`)
- [ ] `CLAUDE.md` kopyalandı (`~/.claude/CLAUDE.md`)
- [ ] `settings.json` oluşturuldu
- [ ] `hooks` bölümü eklendi
- [ ] `startup` hook tanımlandı
- [ ] Claude Code yeniden başlatıldı
- [ ] Test prompt'u ile doğrulandı

**Tüm işaretler varsa ✅ Session Hooks aktif!**

---

## 🎓 Ek Kaynaklar

- [Claude Code Documentation](https://docs.anthropic.com/claude-code)
- [Settings Reference](https://docs.anthropic.com/claude-code/settings)
- [Hooks Guide](https://docs.anthropic.com/claude-code/hooks)

---

**Versiyon:** 1.1.0
**Son Güncelleme:** 2026-01-09
