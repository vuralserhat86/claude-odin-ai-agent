# Microservices

> v1.0.0 | 2026-01-09 | Kubernetes, Docker, gRPC

## 🔴 MUST
- [ ] **Domain-Driven Design** - Service boundaries domain'e göre olmalı
```
✅ DOĞRU - Service boundaries by domain
┌─────────────────────────────────────────┐
│              API Gateway                │
└─────────────────────────────────────────┘
    │           │           │
    ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐
│  User  │ │ Order  │ │Product │
│Service │ │Service │ │Service │
│┌──────┐│ │┌──────┐│ │┌──────┐│
││Users ││ ││Orders││ ││Prods ││
││ DB   ││ ││ DB   ││ ││ DB   ││
│└──────┘│ │└──────┘│ │└──────┘│
└────────┘ └────────┘ └────────┘
```

- [ ] **API Gateway Pattern** - External API calls için gateway kullan
```typescript
import express from 'express';
import { createProxyMiddleware } from 'http-proxy-middleware';

const app = express();
app.use('/api/users', createProxyMiddleware({ target: 'http://user-service:3002', changeOrigin: true }));
app.use('/api/orders', createProxyMiddleware({ target: 'http://order-service:3003', changeOrigin: true }));
```

- [ ] **Circuit Breaker** - Inter-service calls için circuit breaker
```typescript
import { CircuitBreaker } from 'cockatiel';
class UserServiceClient {
  private breaker = CircuitBreaker.breaker({ halfOpenAfter: 10_000, breaker: new ConsecutiveBreaker(5) });
  async getUser(userId: string): Promise<User> { return this.breaker.execute(async () => { const res = await axios.get(`/users/${userId}`); return res.data; }); }
}
```

- [ ] **Database per Service** - Her service kendi database'ne sahip
```typescript
// ❌ YANLIŞ - Direct database access
class OrderService { async createOrder(userId: string, items: Item[]) { const user = await userDb.query(`SELECT * FROM users WHERE id = ${userId}`); } }
// ✅ DOĞRU - API-based data access
class OrderService { constructor(private userClient: UserServiceClient) {}
  async createOrder(userId: string, items: Item[]) { const user = await this.userClient.getUser(userId); return orderDb.insert({ userId, items }); }
}
```

## 🟡 SHOULD
- [ ] **Idempotent Operations** - Operations idempotent olmalı
```typescript
// ✅ DOĞRU - Idempotent using key
async createOrder(data: CreateOrderDto, idempotencyKey: string): Promise<Order> {
  const existing = await orderDb.findBy('idempotencyKey', idempotencyKey);
  if (existing) return existing;
  return orderDb.insert({ ...data, idempotencyKey });
}
```

- [ ] **Health Check Endpoints** - /health endpoint implement et
```typescript
app.get('/health', async (req, res) => {
  const checks = { uptime: process.uptime(), status: 'healthy' };
  try { await db.raw('SELECT 1'); checks.database = 'healthy'; res.status(200).json(checks); }
  catch (error) { checks.status = 'unhealthy'; res.status(503).json(checks); }
});
```

- [ ] **Containerization** - Docker ile containerize et
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . . && RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
USER node
CMD ["node", "dist/main.js"]
```

## ⛔ NEVER
- [ ] **Never Share Database** - Database sharing coupling yaratır
```
❌ YANLIŞ - Shared database (anti-pattern)
┌────────────┐ ┌────────────┐ ┌────────────┐
│   User     │ │   Order    │ │  Product   │
│  Service   │ │  Service   │ │  Service   │
└─────┬──────┘ └─────┬──────┘ └─────┬──────┘
      │              │              │
      └──────────────┴──────────────┘
                │
       ┌────────▼────────┐
       │ Shared Database │
       └─────────────────┘
```

- [ ] **Never Build Monolith as Services** - Fake microservices avoid et
- [ ] **Never Synchronous Chains** - Long synchronous call chains avoid et

## 🔗 Referanslar
- [Microservices Patterns](https://microservices.io/patterns/)
- [Building Microservices](https://www.amazon.com/Building-Microservices-Sam-Newman/dp/1491950358)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
