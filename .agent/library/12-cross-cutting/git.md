# Git - Version Control

> **v1.0.0** | **2026-01-09** | **Git 2.40+, GitHub**

---

## 🔴 MUST

- [ ] **Conventional Commits** - `type(scope): description` formatı kullan
- [ ] **Atomic Commits** - Her commit tek bir değişiklik yapar
- [ ] **.gitignore** - Sensitive dosyaları `.gitignore`'a ekle
- [ ] **Branch Protection** - Main branch'e direct push yapma

```bash
# Conventional commit format
git commit -m "feat(auth): add JWT login"
git commit -m "fix(api): resolve timeout issue"
git commit -m "docs(readme): update installation"

# .gitignore essentials
node_modules/
.env
.env.local
*.log
.DS_Store
dist/
build/
```

---

## 🟡 SHOULD

- [ ] **Feature Branch Workflow** - Her feature için ayrı branch
- [ ] **Pull Request** - Değişiklikleri PR ile merge et
- [ ] **Commit Message** - Türkçe açıklama, İngilizce kod
- [ ] **Git Config** - Kullanıcı bilgilerini ayarla

```bash
# Feature branch oluştur
git checkout -b feature/user-auth

# PR öncesi rebase
git fetch origin main
git rebase origin/main

# Git config
git config --global user.name "Ad Soyad"
git config --global user.email "email@example.com"
git config --global core.autocrlf true
```

---

## ⛔ NEVER

- [ ] **Never Commit Direct to Main** - Main branch korumalı
- [ ] **Never Commit Secrets** - `.env`, API keys asla commit edilmez
- [ ] **Never Force Push to Shared** - Paylaşılan branch'e force push yok
- [ ] **Never Commit Build Artifacts** - `node_modules/`, `dist/` commit edilmez

```bash
# ❌ YANLIŞ
git push -f origin main  # Main'e force push
git add .env             # Secrets commit
git commit -m "update"   # Anlamsız message

# ✅ DOĞRU
git push origin feature-branch
git add .gitignore       # Önce .gitignore
git commit -m "feat: add user authentication"
```

---

## 🔗 Referanslar

- [Git Documentation](https://git-scm.com/doc)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Flow](https://docs.github.com/en/get-started/quickstart/github-flow)
- [gitignore.io](https://www.gitignore.io/)
