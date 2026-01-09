# 📚 Odin AI Agent System - Static Knowledge Library

> **Version:** 1.0.0
> **Last Updated:** 2026-01-09
> **Purpose:** GLM 4.7 Optimized Knowledge Base for Autonomous Development

---

## 🎯 Amaç

Bu knowledge base, Odin AI Agent System'in 25 specialized agent'i için **tek kaynak of truth** olarak tasarlanmıştır.

### 📊 İçerik

| Kategori | Dosya Sayısı | Konu |
|----------|--------------|------|
| 01-tech-stack | 4 | React, Next.js, TypeScript, Node.js |
| 02-backend | 3 | API Design, Python, Security |
| 03-database | 2 | NoSQL, SQL |
| 04-testing | 5 | E2E Test, Integration Test, Load Test, TDD, Unit Test |
| 05-patterns | 5 | Caching, Circuit Breaker, Error Handling, Retry Patterns, State Management |
| 06-architecture | 4 | Clean Architecture, Event-Driven, Hexagonal, Microservices |
| 07-quality | 4 | Clean Code, Code Style, Naming Conventions, Refactoring |
| 08-devops | 4 | CI/CD, Docker, Kubernetes, Monitoring |
| 09-mobile | 2 | Android, iOS |
| 10-ai-ml | 4 | Fine-Tuning, LLM Best Practices, Prompt Engineering, RAG Patterns |
| 11-languages | 4 | C#, Go, Java, Rust |
| 12-cross-cutting | 2 | CLI, Git |
| README | 1 | Kütüphane dizini |

**Toplam:** 51 dosya

---

## 🔍 Nasıl Kullanılır?

### Agent'lar İçin

**Her task öncesi:**

1. ✅ İlgili kategorideki dosyaları oku
2. ✅ MUST kurallarını identifiye et
3. ✅ SHOULD önerilerini değerlendir
4. ✅ NEVER yasaklarını bil

**Kod yazarken:**

```bash
# Örnek: Frontend agent React kullanacak
# 1. .agent/library/01-tech-stack/react.md oku
# 2. MUST kurallarını uygula
# 3. SHOULD önerilerini takip et
# 4. NEVER yasaklarından kaçın
```

### Format Yapısı

Her dosya şu yapıyı izler:

```markdown
# {BAŞLIK} - {KISA AÇIKLAMA}

## 🔴 MUST (Zorunlu)
- [ ] Kural açıklaması

### 📋 Kod Örneği
```typescript
// ❌ YANLIŞ
// ✅ DOĞRU
```

## 🟡 SHOULD (Önerilen)
- [ ] Tavsiye

## ⛔ NEVER (Yapma)
- [ ] Yasak

## 🔗 Referanslar
```

---

## 🎯 GLM 4.7 Optimizasyonu

Bu knowledge base modern LLM'ler için optimize edilmiştir:

| Özellik | Açıklama |
|---------|----------|
| **Checkbox Format** | LLM'lerin rule'ları takip etmesi için |
| **Kısa Açıklamalar** | Token efficiency |
| **Kod Örnekleri** | Pratik uygulama |
| **✅/❌ Karşılaştırma** | Doğru/yanlış ayrımı |
| **3 Seviye** | MUST/SHOULD/NEVER önceliklendirme |

---

## 🔄 Güncelleme Politikası

### Ne Zaman Güncellenir?

1. ✅ Yeni technology stack eklenir
2. ✅ Best practices değişir
3. ✅ Agent feedback toplar
4. ✅ Security issues bulunur

### Versiyonlama

- **Major:** Yapı değişikliği
- **Minor:** Yeni dosya eklenmesi
- **Patch:** Küçük düzeltmeler

---

## 📞 İletişim

**Sorun mu buldun?**

```bash
# Knowledge base issue report et
bash .agent/scripts/queue.sh create --type "kb-issue" --message "..."
```

---

**Durum:** ✅ Production Ready
**Agent Coverage:** 25/25 agents
**Total Rules:** 500+
