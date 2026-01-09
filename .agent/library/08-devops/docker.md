# Docker - Containerization

> **v1.0.0** | **2026-01-09** | **Docker 25+, Compose 3.8+**

---

## 🔴 MUST

- [ ] **Multi-Stage Builds** - Build ve runtime stage'lerini ayır
- [ ] **Minimal Base** - Alpine veya distroless kullan
- [ ] **Non-Root User** - Container non-root user ile çalışmalı
- [ ] **.dockerignore** - Gereksiz dosyaları exclude et

```dockerfile
# Multi-stage build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Runtime stage
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY package*.json ./
RUN npm ci --only=production
USER node
EXPOSE 3000
CMD ["node", "dist/index.js"]

# .dockerignore
node_modules
npm-debug.log
.git
.env
```

---

## 🟡 SHOULD

- [ ] **Layer Optimization** - Az değişen layer'ları üste koy
- [ ] **Health Check** - Container health check ekle
- [ ] **Explicit Tags** - Image tags kullan (latest yok)
- [ ] **Resource Limits** - CPU/memory limit belirle

```dockerfile
# Layer order matters
FROM node:20-alpine
# Önce package files (az değişen)
COPY package*.json ./
RUN npm ci --only=production
# Sonra source code (sık değişen)
COPY . .

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD node healthcheck.js || exit 1

# Docker Compose limits
services:
  app:
    image: myapp:v1.0.0
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
```

---

## ⛔ NEVER

- [ ] **Never Run as Root** - Root user ile container çalıştırma
- [ ] **Never Use Latest** - `latest` tag kullanma
- [ ] **Never Cache Secrets** - Secrets in layer'da kalmamalı
- [ ] **Never Monolithic** - Her container tek service

```dockerfile
# ❌ YANLIŞ
FROM node:20
USER root
COPY .env .
RUN npm install

# ✅ DOĞRU
FROM node:20-alpine
USER node
COPY .env.example .
RUN npm ci --only=production
```

---

## 🔗 Referanslar

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Dockerfile Reference](https://docs.docker.com/reference/dockerfile/)
- [Compose File Format](https://docs.docker.com/compose/compose-file/)
