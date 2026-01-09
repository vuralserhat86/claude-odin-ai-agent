# CI/CD - Continuous Integration

> **v1.0.0** | **2026-01-09** | **GitHub Actions, Docker**

---

## 🔴 MUST

- [ ] **Lint Check** - CI'da lint kontrolü zorunlu
- [ ] **Run Tests** - Tüm test suite CI'da çalışmalı
- [ ] **Build Verification** - Package buildable olmalı
- [ ] **Security Scan** - Dependency scan et

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Format check
        run: npm run format:check

      - name: Run tests
        run: npm test -- --coverage

      - name: Build
        run: npm run build

      - name: Security audit
        run: npm audit --audit-level=high
```

---

## 🟡 SHOULD

- [ ] **Automated Deploy** - CD ile otomatik deploy
- [ ] **Environment Promotion** - dev → staging → prod
- [ ] **Rollback** - Quick rollback mechanism
- [ ] **Zero Downtime** - Blue-green deployment

```yaml
# CD deployment
deploy:
  needs: test
  runs-on: ubuntu-latest
  steps:
    - name: Deploy to staging
      run: |
        kubectl set image deployment/app \
          app-container=$IMAGE:$TAG \
          -n staging

    - name: Smoke test
      run: ./scripts/smoke-test.sh staging

    - name: Promote to production
      if: success()
      run: |
        kubectl set image deployment/app \
          app-container=$IMAGE:$TAG \
          -n production
```

---

## ⛔ NEVER

- [ ] **Never Commit Secrets** - .env commit etme
- [ ] **Never Skip Tests** - Test skip yok
- [ ] **Never Manual Deploy** - Manual deployment'ten kaçın

```yaml
# ❌ YANLIŞ
- name: Deploy
  env:
    API_KEY: sk-... # Hardcoded secret
  run: npm run deploy -- --skip-tests

# ✅ DOĞRU
- name: Deploy
  env:
    API_KEY: ${{ secrets.API_KEY }}
  run: |
    npm test && npm run deploy
```

---

## 🔗 Referanslar

- [GitHub Actions](https://docs.github.com/actions)
- [CI/CD Best Practices](https://www.atlassian.com/continuous-delivery)
- [Docker Build Push](https://github.com/docker/build-push-action)
- [Kubernetes Deploy](https://github.com/stefanprodan/kube-actions)
