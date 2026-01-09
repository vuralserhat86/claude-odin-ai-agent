# Retry Patterns

> v1.0.0 | 2026-01-09

## 🔴 MUST
- [ ] **Exponential Backoff** - Retry aralığı exponentially artmalı
```typescript
// ✅ DOĞRU - Exponential backoff with jitter
class RetryPolicy {
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    for (let attempt = 0; attempt <= this.config.maxRetries; attempt++) {
      try {
        return await fn();
      } catch (error) {
        if (attempt >= this.config.maxRetries || !this.shouldRetry(error as Error)) throw error;
        const delay = this.calculateDelay(attempt);
        await this.sleep(delay);
      }
    }
    throw lastError;
  }

  private calculateDelay(attempt: number): number {
    const exponentialDelay = this.config.baseDelay * Math.pow(2, attempt);
    const jitter = exponentialDelay * this.config.jitterFactor;
    return Math.min(exponentialDelay + (Math.random() - 0.5) * 2 * jitter, this.config.maxDelay);
  }

  private shouldRetry(error: Error): boolean {
    if (error instanceof HttpClientError) return false; // Don't retry 4xx
    return true; // Retry 5xx and network errors
  }
}
```

- [ ] **Max Retries** - Maximum retry limit zorunlu
```typescript
class APIClient {
  private retryPolicy = new RetryPolicy({ maxRetries: 3, baseDelay: 1000, maxDelay: 30000, jitterFactor: 0.3 });
  async fetchUser(userId: string): Promise<User> {
    return this.retryPolicy.execute(async () => {
      const response = await fetch(`https://api.example.com/users/${userId}`, { signal: AbortSignal.timeout(10000) });
      if (!response.ok) {
        if (response.status >= 400 && response.status < 500) throw new HttpClientError(`HTTP ${response.status}`);
        throw new Error(`HTTP ${response.status}`);
      }
      return response.json();
    });
  }
}
```

- [ ] **Idempotent Operations** - Retry'ler için operations idempotent şart

## 🟡 SHOULD
- [ ] **Conditional Retry** - Sadece retryable error'larda retry
```typescript
// ✅ DOĞRU - Conditional retry based on error type
class SmartRetryPolicy {
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    for (let attempt = 0; attempt <= 3; attempt++) {
      try {
        return await fn();
      } catch (error) {
        if (attempt >= 3) break;
        const strategy = this.findStrategy(error as Error);
        if (strategy && strategy.shouldRetry(error as Error)) {
          await this.sleep(strategy.getDelay(attempt));
        } else break;
      }
    }
    throw lastError;
  }

  private findStrategy(error: Error): RetryStrategy | undefined {
    if (error instanceof NetworkError) return new NetworkErrorStrategy();
    if (error.message.includes('429')) return new RateLimitStrategy();
    return undefined;
  }
}
```

- [ ] **Combine with Circuit Breaker** - Circuit breaker ile retry'i birleştir

## ⛔ NEVER
- [ ] **Never Retry Without Backoff** - Fixed delay = thundering herd
```typescript
// ❌ YANLIŞ - No backoff
async function badRetry() {
  for (let i = 0; i < 3; i++) {
    try { return await operation(); }
    catch { if (i < 2) continue; } // Immediate retry!
  }
}
// ✅ DOĞRU - Exponential backoff
async function goodRetry() {
  for (let i = 0; i < 3; i++) {
    try { return await operation(); }
    catch (error) {
      if (i >= 2) throw error;
      await sleep(1000 * Math.pow(2, i)); // 1s, 2s, 4s
    }
  }
}
```

- [ ] **Never Retry Non-Idempotent** - Non-idempotent operations duplicate data yaratır
- [ ] **Never Infinite Retry** - Max limit şart
- [ ] **Never Hide Retries** - Retry behavior log et

## 🔗 Referanslar
- [AWS Exponential Backoff](https://docs.aws.amazon.com/general/latest/gr/gr-retries.html)
- [Google Cloud Retry](https://cloud.google.com/iot/docs/how-tos/exponential-backoff)
- [Retry Pattern (Microsoft)](https://docs.microsoft.com/en-us/azure/architecture/patterns/retry)
