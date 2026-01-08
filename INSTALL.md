# 📥 Kurulum Rehberi

**Odin** AI Development Agent sisteminin 3 farklı kurulum yöntemi.

---

## 🚀 Yöntem 1: Proje İçi Manuel (En Basit - 30 Saniye)

### Kimler İçin?
- ✅ Tek bir proje için kullanacaklar
- ✅ Git ile versiyon kontrolü isteyenler
- ✅ Proje özel yapılandırma isteyenler

### Adımlar

```bash
# 1. Repoyu kopyala
git clone https://github.com/KULLANICI/autonomous-odin.git
cd autonomous-odin

# 2. Kullanmaya başla
# Claude Code'u bu klasörde aç
# Prompt ver:
"Projeyi analiz et"
```

### Avantajlar
- ✅ Proje ile birlikte Git'te takip edilir
- ✅ Ek kurulum gerekmez
- ✅ Proje özel düzenleme yapılabilir

### Dezavantajlar
- ❌ Her projeye kopyalamak gerekir
- ❌ Otomatik yükleme yok

---

## 🌐 Yöntem 2: Global Otomatik (Önerilen - 2 Dakika)

### Kimler İçin?
- ✅ Tüm projelerinde kullanmak isteyenler
- ✅ Tek seferlik kurulum isteyenler
- ✅ Otomatik yükleme isteyenler

### Adımlar

#### Adım 1: Repoyu İndir

```bash
# Repoyu bir klasöre indir (örneğin: ~/Downloads)
git clone https://github.com/KULLANICI/autonomous-odin.git
cd autonomous-odin
```

#### Adım 2: Global Klasöre Kopyala

```bash
# .agent klasörünü global Claude Code klasörüne kopyala
cp -r .agent ~/.claude/.agent

# .claude/skills klasörünü global'e kopyala (ÖNEMLİ!)
cp -r .claude/skills ~/.claude/skills

# CLAUDE.md'yi global klasöre kopyala
cp CLAUDE.md ~/.claude/CLAUDE.md
```

#### Adım 3: Session Hooks Yapılandır (Otomatik Yükleme)

```bash
# settings.json oluştur/düzenle
# Windows: %USERPROFILE%\.claude\settings.json
# macOS/Linux: ~/.claude/settings.json
```

**settings.json içeriği:**
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

### Avantajlar
- ✅ Tüm projelerde otomatik çalışır
- ✅ Tek seferlik kurulum
- ✅ Otomatik yükleme (Session Hooks)

### Dezavantajlar
- ❌ Git ile takip edilmez
- ❌ Global yapılandırma

---

## 🔄 Yöntem 3: Hibrit (En İyi - 3 Dakika)

### Kimler İçin?
- ✅ Hem global hem proje içi kullanmak isteyenler
- ✅ Esneklik isteyenler
- ✅ En iyi iki dünya

### Adımlar

#### Adım 1: Global Kurulum (Yöntem 2'deki gibi)

```bash
# Global klasöre kopyala
cp -r .agent ~/.claude/.agent
cp -r .claude/skills ~/.claude/skills
cp CLAUDE.md ~/.claude/CLAUDE.md

# Session hooks yapılandır
# settings.json'e startup hook ekle
```

#### Adım 2: Proje İçi Link Oluştur

```bash
# Her projede:
cd my-project

# Global .agent'a symlink oluştur
ln -s ~/.claude/.agent .agent

# Veya kopyala:
cp -r ~/.claude/.agent .
```

### Avantajlar
- ✅ Global otomatik yükleme
- ✅ Proje içi Git takibi
- ✅ Merkezi yönetim
- ✅ Esneklik

### Dezavantajlar
- ❌ Biraz daha karmaşık
- ❌ Daha fazla adım

---

## 🔍 Kurulum Doğrulama

### Test Edin

```bash
# 1. Claude Code'u aç
# 2. Şu komutu ver:
"Sistemi test et, bana durumu raporla"

# Beklenen çıktı:
# "✅ Odin AI Development Agent sistemi aktif.
#  25 agent hazır, Circuit Breaker çalışıyor, DLQ boş."
```

### Komutları Test Edin

```bash
# Circuit Breaker durumu
bash ~/.claude/.agent/scripts/circuit.sh status

# Queue durumu
bash ~/.claude/.agent/scripts/queue.sh status

# Veya proje içi kurulum yaptıysanız:
bash .agent/scripts/circuit.sh status
bash .agent/scripts/queue.sh status
```

---

## 📂 Dosya Yapısı (Kurulum Sonrası)

### Global Kurulum

```
~/.claude/
├── .agent/              (Sistem)
│   ├── config/
│   ├── prompts/
│   ├── queue/
│   ├── state/
│   └── scripts/
├── CLAUDE.md           (Global rules)
└── settings.json       (Hooks)
```

### Proje İçi Kurulum

```
my-project/
├── .agent/             (Sistem)
├── .claude/
│   └── skills/
└── CLAUDE.md           (Global rules)
```

---

## 🛠️ Sorun Giderme

### Sorun: "command not found: jq"

**Çözüm:** jq yükle

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Windows (Chocolatey)
choco install jq
```

### Sorun: "CLAUDE.md yüklenmiyor"

**Çözüm:** Session hooks kontrol et

```bash
# settings.json'i kontrol et
cat ~/.claude/settings.json

# "hooks" ve "startup" bölümü olmalı
```

### Sorun: "Agent çalışmıyor"

**Çözüm:** Circuit Breaker durumunu kontrol et

```bash
bash .agent/scripts/circuit.sh list

# OPEN circuit varsa reset et:
bash .agent/scripts/circuit.sh reset <agent-type>
```

---

## 🔄 Güncelleme

### Repo'yu Güncelle

```bash
cd ~/autonomous-odin  # veya klonladığınız yer
git pull origin main

# Global kurulum yaptıysanız:
cp -r .agent/* ~/.claude/.agent/
cp CLAUDE.md ~/.claude/CLAUDE.md
```

### Versiyon Kontrolü

```bash
# Versiyon bilgisi README.md'de veya CLAUDE.md'de
head -5 README.md
```

---

## 🗑️ Kaldırma

### Global Kaldırma

```bash
# Global klasörleri sil
rm -rf ~/.claude/.agent
rm ~/.claude/CLAUDE.md

# Session hooks'u kaldır
# settings.json'den "hooks" bölümünü sil
```

### Proje İçi Kaldırma

```bash
# Proje klasöründen sil
rm -rf .agent
rm .claude/skills/autonomous-dev.mdc
rm CLAUDE.md
```

---

## 📞 Destek

Sorun yaşarsanız:
1. [README.md](README.md) dosyasını okuyun
2. [SESSION_HOOKS.md](SESSION_HOOKS.md) dosyasına bakın
3. GitHub Issues'a sorunuzu gönderin

---

## ✅ Kurulum Kontrol Listesi

- [ ] Repo klonlandı
- [ ] Kurulum yöntemi seçildi (Manuel / Global / Hibrit)
- [ ] Dosyalar kopyalandı
- [ ] (Opsiyonel) Session hooks yapılandırıldı
- [ ] (Opsiyonel) settings.json düzenlendi
- [ ] Kurulum test edildi
- [ ] Komutlar çalışıyor (circuit.sh, queue.sh)
- [ ] İlk prompt denendi

**Tüm işaretler varsa ✅ kurulum tamamlanmıştır!**

---

**Versiyon:** 1.0.0
**Son Güncelleme:** 2025-01-08
