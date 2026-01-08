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

```json
{
  "hooks": {
    "startup": [
      {
        "type": "loadFile",
        "path": "~/.claude/CLAUDE.md"
      }
    ]
  }
}
```

### Detaylı Yapı

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
        "command": "echo 'Odin AI Agent System Loaded'"
      }
    ]
  }
}
```

---

## 🔧 Hook Türleri

### 1. loadFile (Dosya Yükle)

```json
{
  "type": "loadFile",
  "path": "~/.claude/CLAUDE.md"
}
```

**Ne Yapar?**
- Belirtilen dosyayı otomatik okur
- Claude'un context'ine ekler
- Her oturumda çalışır

**Kullanım Alanı:**
- Global kurallar (CLAUDE.md)
- Proje özel talimatlar
- Sistem tanımlamaları

### 2. command (Komut Çalıştır)

```json
{
  "type": "command",
  "command": "bash ~/.claude/.agent/scripts/bootstrap.sh"
}
```

**Ne Yapar?**
- Shell komutu çalıştırır
- Sistem kurulum script'leri çalıştırır

**Kullanım Alanı:**
- Queue başlatma
- State oluşturma
- Log temizleme

---

## 🎯 Odin için Session Hooks

### Önerilen Yapılandırma

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
        "command": "echo '🪦 Odin AI Agent System v1.0.0 Loaded'"
      }
    ]
  }
}
```

### Ne İçin?

| Hook | Amaç |
|------|------|
| **loadFile** | Global kuralları yükle (Türkçe konuşma, Simple/Complex analizi) |
| **command** | Sistem başlangıç mesajı göster |

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
# Windows (PowerShell)
# Not defterini aç, aşağıdaki içeriği yapıştır:
# %USERPROFILE%\.claude\settings.json

# macOS/Linux
nano ~/.claude/settings.json
```

### Adım 3: İçeriği Yapıştır

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
        "command": "echo '🪦 Odin AI Agent System v1.0.0 Loaded'"
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

```json
{
  "hooks": {
    "startup": [
      { "type": "loadFile", "path": "~/.claude/CLAUDE.md" },
      { "type": "loadFile", "path": "~/.claude/custom-rules.md" },
      { "type": "command", "command": "echo 'System ready'" },
      { "type": "command", "command": "bash ~/scripts/init.sh" }
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
```json
{
  "type": "loadFile",
  "path": "/tam/yol/CLAUDE.md"  // Tam yolu kullan
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

**Versiyon:** 1.0.0
**Son Güncelleme:** 2025-01-08
