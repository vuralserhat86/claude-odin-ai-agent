# Caching

> v1.0.0 | 2026-01-09 | Redis, Memcached

## 🔴 MUST
- [ ] **Cache-Aside Pattern** - Cache-aside (lazy loading) kullan
```typescript
// ✅ DOĞRU - Cache-aside with proper invalidation
class UserService {
  async getUser(id: string): Promise<User | null> {
    const cacheKey = `user:${id}`;

    // Try cache first
    const cached = await this.cache.get<User>(cacheKey);
    if (cached !== null) {
      console.log(`Cache HIT for ${cacheKey}`);
      return cached;
    }

    console.log(`Cache MISS for ${cacheKey}, fetching from DB`);
    const user = await this.db.findById(id);
    if (!user) return null;

    // Store in cache with TTL
    await this.cache.set(cacheKey, user, 300); // 5 minutes
    return user;
  }

  async updateUser(id: string, data: Partial<User>): Promise<User> {
    const user = await this.db.update(id, data);

    // Invalidate cache
    const cacheKey = `user:${id}`;
    await this.cache.del(cacheKey);
    console.log(`Cache invalidated for ${cacheKey}`);

    return user;
  }
}
```

- [ ] **TTL Configuration** - Her cache entry için TTL set et
- [ ] **Cache Invalidation** - Data değişince cache invalidate et
- [ ] **Error Handling** - Cache failure'da fallback et
```typescript
// ✅ DOĞRU - Graceful degradation
class ResilientCache {
  async get<T>(key: string): Promise<T | null> {
    try {
      return await this.circuitBreaker.execute(async () => {
        const value = await this.redis.get(key);
        return value ? JSON.parse(value) : null;
      });
    } catch (error) {
      if (error instanceof CircuitOpenError) {
        console.warn('Cache circuit open, returning null');
        return null;
      }
      console.error('Cache get failed:', error);
      return null;
    }
  }
}
```

## 🟡 SHOULD
- [ ] **Multi-Level Caching** - L1 (in-memory) + L2 (Redis) + L3 (DB)
```typescript
// ✅ DOĞRU - Multi-level caching
class MultiLevelCache {
  async get(key: string): Promise<unknown | null> {
    // L1: Check in-memory cache first
    const l1Value = this.l1.get(key);
    if (l1Value !== undefined) return l1Value;

    // L2: Check Redis
    const l2Value = await this.l2.get(key);
    if (l2Value !== null) {
      this.l1.set(key, l2Value); // Promote to L1
      return l2Value;
    }

    // L3: Fetch from database
    const l3Value = await this.l3.get(key);
    if (l3Value !== null) {
      this.l1.set(key, l3Value);
      await this.l2.set(key, l3Value, 300);
    }
    return l3Value;
  }
}
```

- [ ] **Cache Warming** - Startup'da critical data cache'e yükle
- [ ] **Hit Rate Tracking** - Cache hit/miss ratio track et

## ⛔ NEVER
- [ ] **Never Cache Everything** - Everything cache = memory bloat
```typescript
// ❌ YANLIŞ - No TTL = memory leak
await cache.set(id, user);
// ✅ DOĞRU - Strategic caching with TTL
await cache.set(id, user, 300); // 5 minute TTL
```

- [ ] **Never Cache Without TTL** - No TTL = memory leak risk
- [ ] **Never Inconsistently Invalidate** - Partial invalidation = stale data
- [ ] **Never Cache Large Objects** - Large objects = poor performance

## 🔗 Referanslar
- [Redis Caching Best Practices](https://redis.io/docs/manual/patterns/)
- [Cache-Aside Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/cache-aside)
- [Amazon ElastiCache Best Practices](https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/best-practices.html)
