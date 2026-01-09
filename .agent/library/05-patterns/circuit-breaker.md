# Circuit Breaker Pattern

> v1.0.0 | 2026-01-09

## 🔴 MUST
- [ ] **CLOSED State** - Normal operation, requests pass through
- [ ] **OPEN State** - Failure threshold exceeded, requests blocked
- [ ] **HALF_OPEN State** - Testing if service has recovered
```typescript
// ✅ DOĞRU - Circuit breaker implementation
enum CircuitState { CLOSED = 'CLOSED', OPEN = 'OPEN', HALF_OPEN = 'HALF_OPEN' }

class CircuitBreaker {
  private state: CircuitState = CircuitState.CLOSED;
  private failures: number = 0;
  private lastFailureTime: number = 0;

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      const now = Date.now();
      if (now - this.lastFailureTime >= this.config.timeout) {
        this.transitionTo(CircuitState.HALF_OPEN);
      } else {
        throw new CircuitOpenError(`Circuit '${this.name}' is OPEN`);
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess(): void {
    if (this.state === CircuitState.HALF_OPEN) this.transitionTo(CircuitState.CLOSED);
    else if (this.state === CircuitState.CLOSED) this.failures = 0;
  }

  private onFailure(): void {
    this.failures++;
    this.lastFailureTime = Date.now();
    if (this.state === CircuitState.HALF_OPEN || this.failures >= this.config.failureThreshold) {
      this.transitionTo(CircuitState.OPEN);
    }
  }
}
```

- [ ] **Timeout Configuration** - Tüm external calls timeout ile
```typescript
// ✅ DOĞRU - Service client with circuit breaker
class InventoryServiceClient {
  private circuitBreaker = new CircuitBreaker('InventoryService', { failureThreshold: 5, timeout: 30000 });
  async getStock(productId: string): Promise<number> {
    return this.circuitBreaker.execute(async () => {
      const response = await fetch(`https://inventory-service.internal/api/stock/${productId}`, { timeout: 5000 });
      return response.json();
    });
  }
}
```

## 🟡 SHOULD
- [ ] **Fallback Values** - Circuit open iken fallback kullan
```typescript
// ✅ DOĞRU - Fallback strategies
class InventoryServiceWithFallback {
  async getStock(productId: string): Promise<number | null> {
    try {
      return await this.circuitBreaker.execute(async () => {
        const data = await fetch(`https://inventory-service.internal/stock/${productId}`);
        await this.cache.set(`stock:${productId}`, data.quantity, 300);
        return data.quantity;
      });
    } catch (error) {
      if (error instanceof CircuitOpenError) {
        const cached = await this.cache.get(`stock:${productId}`);
        if (cached !== null) return cached;
        return null; // Graceful degradation
      }
      throw error;
    }
  }
}
```

- [ ] **Metrics Export** - Circuit breaker metrics export et

## ⛔ NEVER
- [ ] **Never Skip Circuit Breaker** - "Critical service" için circuit breaker atla
```typescript
// ❌ YANLIŞ - Skipping for "critical" service
async function getPaymentMethods(): Promise<PaymentMethod[]> {
  return await paymentService.getMethods(); // No circuit breaker!
}
// ✅ DOĞRU - Even critical services need protection
async function getPaymentMethods(): Promise<PaymentMethod[]> {
  try {
    return await paymentCircuitBreaker.execute(async () => await paymentService.getMethods());
  } catch (error) {
    if (error instanceof CircuitOpenError) return await cache.get('payment-methods') ?? [];
    throw error;
  }
}
```

- [ ] **Never Set Timeout Too Low** - Too aggressive timeout = frequent trips
- [ ] **Never Reuse Same Breaker** - Different services için ayrı breaker'lar

## 🔗 Referanslar
- [Circuit Breaker Pattern (Martin Fowler)](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Microsoft Circuit Breaker](https://docs.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker)
- [Resilience4j Documentation](https://resilience4j.readme.io/)
