# Kubernetes

> v1.0.0 | 2026-01-09

## 🔴 MUST
- [ ] **Resource Limits** - Her container için requests/limits
```yaml
# ✅ DOĞRU - Proper resource management
spec:
  containers:
  - name: user-service
    image: user-service:v1.0.0
    resources:
      requests: { memory: "256Mi", cpu: "250m" }
      limits: { memory: "512Mi", cpu: "500m" }
    livenessProbe:
      httpGet: { path: /health, port: http }
      initialDelaySeconds: 30
    readinessProbe:
      httpGet: { path: /health/ready, port: http }
```

- [ ] **Health Checks** - Liveness ve readiness probes
```typescript
// ✅ DOĞRU - Health checks
app.get('/health', (req, res) => res.status(200).json({ status: 'healthy' }));

app.get('/health/ready', async (req, res) => {
  const checks = { database: false, redis: false };
  try { await db.query('SELECT 1'); checks.database = true; } catch {}
  try { await redis.ping(); checks.redis = true; } catch {}
  const allHealthy = Object.values(checks).every(c => c);
  res.status(allHealthy ? 200 : 503).json({ status: allHealthy ? 'ready' : 'not ready', checks });
});
```

- [ ] **ConfigMaps/Secrets** - Configuration externalize et
- [ ] **Labels & Selectors** - Consistent labeling

## 🟡 SHOULD
- [ ] **HPA Configuration** - Otomatik scaling
```yaml
# ✅ DOĞRU - HPA
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: user-service-hpa }
spec:
  scaleTargetRef: { kind: Deployment, name: user-service }
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target: { type: Utilization, averageUtilization: 70 }
```

- [ ] **Network Policies** - Default deny, specific allow
- [ ] **Persistent Volumes** - Stateful workload'lar için PVC

## ⛔ NEVER
- [ ] **Never Run as Root** - Container'ları root olarak çalıştırma
```yaml
# ❌ YANLIŞ
securityContext: { runAsUser: 0 }
# ✅ DOĞRU
securityContext: { runAsUser: 1000, runAsNonRoot: true, readOnlyRootFilesystem: true }
```

- [ ] **Never Latest Tag** - Latest tag kullanma
```yaml
# ❌ YANLIŞ
image: myapp:latest
# ✅ DOĞRU
image: myapp:v1.2.3
```

- [ ] **Never Hardcoded Config** - Config'ları image'de sakla
- [ ] **Never Ignore Resource Limits** - Limits without requests = sorun

## 🔗 Referanslar
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
