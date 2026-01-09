# Monitoring

> v1.0.0 | 2026-01-09 | Prometheus, Grafana, Sentry

## 🔴 MUST
- [ ] **Three Pillars** - Metrics, Logs, Traces implement et
```typescript
// ✅ DOĞRU - Comprehensive observability
import { Counter, Histogram } from 'prom-client';
import * as Sentry from '@sentry/node';

// Metrics
const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code']
});

const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request duration',
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1, 5]
});

// Sentry error tracking
Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1
});
```

- [ ] **RED Method** - Rate, Errors, Duration metrics track et
- [ ] **Structured Logging** - JSON format log'lar kullan
```typescript
// ✅ DOĞRU - Structured logging
logger.info('User logged in', {
  userId: user.id,
  email: maskEmail(user.email),
  ipAddress: req.ip,
  requestId: req.id
});
```

- [ ] **Alert Rules** - Critical alert'ler define et
```yaml
# ✅ DOĞRU - Prometheus alerting
- alert: HighErrorRate
  expr: rate(http_requests_total{status_code=~"5.."}[5m]) > 0.05
  for: 10m
  labels: { severity: critical }
  annotations:
    summary: "High error rate detected"
```

## 🟡 SHOULD
- [ ] **Business Metrics** - Business KPI'leri track et
```typescript
// ✅ DOĞRU - Business metrics
const ordersCreated = new Counter({
  name: 'orders_created_total',
  help: 'Total orders created',
  labelNames: ['payment_method']
});
```

- [ ] **SLA/SLO Tracking** - SLA compliance monitor et
- [ ] **Dashboard Design** - Service ve business dashboard'lar oluştur
- [ ] **Trace Propagation** - Cross-service trace context propagate et

## ⛔ NEVER
- [ ] **Never Alert Fatigue** - Her ufak hataya alertleme
```yaml
# ❌ YANLIŞ - Too many alerts
- alert: AnyError
  expr: http_requests_total{status_code=~"5.."} > 0
# ✅ DOĞRU - Meaningful alerts
- alert: HighErrorRate
  expr: rate(http_requests_total{status_code=~"5.."}[5m]) > 0.05
  for: 10m
```

- [ ] **Never Silent Failures** - Failure'ları yutma
```typescript
// ❌ YANLIŞ - Swallowed error
try { await operation(); } catch (error) { /* Silent failure */ }
// ✅ DOĞRU - Always log failures
try {
  await operation();
} catch (error) {
  logger.error('Operation failed', { error: error.message, stack: error.stack, context: { userId, requestId } });
  Sentry.captureException(error);
  throw error;
}
```

- [ ] **Never Lose Context** - Error context'i koru
- [ ] **Never Log Sensitive Data** - Passwords, tokens log'lama

## 🔗 Referanslar
- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Sentry Documentation](https://docs.sentry.io/)
- [OpenTelemetry](https://opentelemetry.io/docs/)
- [Grafana Dashboards](https://grafana.com/docs/grafana/latest/dashboards/)
