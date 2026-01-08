# 🪦 Odin - Autonomous AI Development Agent

**Claude Code için otonom çoklu-agent geliştirme sistemi**

25 specialized agent, Circuit Breaker, Dead Letter Queue ve MCP Tools entegrasyonu ile tam otonom geliştirme deneyimi.

---

## ✨ Özellikler

| Özellik | Açıklama |
|---------|----------|
| **25 Specialized Agent** | Core, Development, Research, Quality, Support |
| **Circuit Breaker** | Hatalı agent'ları otomatik engelle |
| **Dead Letter Queue** | Başarısız task'ları yönet |
| **MCP Tools** | GitHub + Web research entegrasyonu |
| **Simple/Complex Analysis** | Otomatik task ayrımı |
| **Türkçe Destek** | Tam Türkçe raporlama |

---

## 🚀 Hızlı Başlangıç

### Minimum Kurulum (30 saniye)

```bash
# 1. Repoyu kopyala
git clone https://github.com/KULLANICI/autonomous-conductor.git
cd autonomous-conductor

# 2. Kullanmaya başla
# Claude Code'u bu klasörde aç, prompt ver:
"Projeyi analiz et"
```

### Global Kurulum (Otomatik)

Detaylı bilgi için [INSTALL.md](INSTALL.md) dosyasına bakın.

---

## 📖 Kullanım

### Simple Tasks (Direct Execution)

```
"Header'daki 'About' yazısını 'Hakkında' yap"
"Console.log'ları sil"
"Button rengini mavi yap"
```

### Complex Tasks (Agent Delegation)

```
"User authentication system oluştur, JWT ile"
"React hooks araştır, en iyi uygulamaları bul"
"E-ticaret sitesi geliştir"
```

---

## 🛠️ Sistem Bileşenleri

```
.agent/
├── config/           # Yapılandırma (Circuit Breaker, Queue)
├── prompts/agents/   # 25 agent prompt
├── queue/            # Task yönetimi (5 queue)
├── state/            # Sistem durumu
└── scripts/          # Yönetim script'leri

.claude/
└── skills/
    └── autonomous-dev.mdc  # Ana orchestrator skill
```

---

## 📚 Dokümantasyon

| Dosya | İçerik |
|-------|--------|
| [CLAUDE.md](CLAUDE.md) | Global sistem kuralları (Türkçe) |
| [INSTALL.md](INSTALL.md) | Detaylı kurulum rehberi |
| [SESSION_HOOKS.md](SESSION_HOOKS.md) | Session Hooks açıklaması |

---

## 🎯 Yönetim Komutları

```bash
# Circuit Breaker durumu
bash .agent/scripts/circuit.sh status

# Queue durumu
bash .agent/scripts/queue.sh status

# DLQ (Dead Letter Queue)
bash .agent/scripts/queue.sh dlq
```

---

## 🌟 Özellikler

### Circuit Breaker

- 26 agent circuit (her agent için ayrı threshold)
- 3 durum: CLOSED, OPEN, HALF_OPEN
- Otomatik kurtarma

### Dead Letter Queue

- 3 retry mekanizması (exponential backoff)
- Attempt history tracking
- Manuel recovery işlemleri

### MCP Tools

- **GitHub**: Kod ara, repo bul, dosya oku
- **Web**: DuckDuckGo ara, web içeriği oku
- **Research**: Best practices araştır

---

## 📊 Agent Sistemi

**Core (3):** orchestrator, planner, analyst

**Development (8):** frontend, backend, mobile, database, api-design, security, performance, architect

**Research (4):** researcher, competitive, documentation, config

**Quality (5):** reviewer-code, reviewer-security, reviewer-performance, reviewer-business, reviewer-ui

**Support (5):** testing, fixer, deps, build, debugger

---

## 🏗ı Mimari

```
┌─────────────────────────────────────────┐
│ LAYER 4: Multi-Agent Orchestration      │
│ autonomous-dev skill → 25 agent         │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────┴───────────────────────┐
│ LAYER 3: Tool Use Execution             │
│ Simple: Direct tools                    │
│ Complex: Agent prompts + MCP            │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────┴───────────────────────┐
│ LAYER 2: Error Handling                │
│ DLQ + Circuit Breaker                   │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────┴───────────────────────┐
│ LAYER 1: I/O (MCP + Native Tools)       │
│ GitHub + Web + File operations         │
└─────────────────────────────────────────┘
```

---

## 🌐 Dil

**Tüm konuşmalar ve raporlar TÜRKÇE'dir.**

- ✅ Yanıtlar Türkçe
- ✅ Raporlar Türkçe
- ✅ Hata mesajları Türkçe
- ✅ Kod yorumları Türkçe
- ❌ Değişkenler İngilizce (coding standard)

---

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen pull request gönderin.

---

## 📝 Lisans

MIT License

---

## 🙏 Teşekkürler

Bu sistem, Claude Code'un gücünü artırmak için tasarlanmıştır.

**Odin:** Her şeyi gören, her şeyi yöneten - Çoklu-agent orkestrasyonu için geliştirilmiş otonom AI geliştirme sistemi.

---

**Version:** 1.0.0
**Status:** Production Ready
**Language:** Türkçe (Primary)
