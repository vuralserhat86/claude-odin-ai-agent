# Refactoring

> v1.0.0 | 2026-01-09

## 🔴 MUST
- [ ] **Test Coverage First** - Refactoring öncesi test coverage sağla
```typescript
// ✅ DOĞRU - Test coverage first
describe('processUser', () => {
  it('should process valid user', async () => {
    const result = await processUser(validUser);
    expect(result.status).toBe('processed');
  });

  it('should reject invalid user', async () => {
    await expect(processUser(invalidUser)).rejects.toThrow('Invalid email');
  });
});

// Now refactor safely
function processUser(user: User): ProcessedUser {
  validateUser(user);
  const normalized = normalizeUserData(user);
  const enriched = enrichUserData(normalized);
  return formatUserData(enriched);
}
```

- [ ] **Small Steps** - Küçük adımlarla refactor et
- [ ] **Run Tests Frequently** - Her değişiklikten sonra test çalıştır
- [ ] **Preserve Behavior** - Refactoring davranışı değiştirmemeli

- [ ] **Extract Method** - Long function'ları böl
```typescript
// ❌ YANLIŞ - Long function
function calculateOrderPrice(order: any): number {
  let price = order.basePrice;
  if (order.quantity > 100) price = price * 0.9;
  if (order.customer.type === 'premium') {
    if (order.customer.years > 5) price = price * 0.85;
  }
  return price;
}

// ✅ DOĞRU - Extract methods
function calculateOrderPrice(order: Order): number {
  let price = order.basePrice;
  price = applyQuantityDiscount(price, order.quantity);
  price = applyCustomerDiscount(price, order.customer);
  return Math.max(0, price);
}

function applyQuantityDiscount(price: number, quantity: number): number {
  if (quantity > 100) return price * 0.90;
  if (quantity > 50) return price * 0.95;
  return price;
}
```

- [ ] **Replace Magic Numbers** - Sabitleri isimlendir

## 🟡 SHOULD
- [ ] **Guard Clauses** - Early return ile nesting azalt
```typescript
// ❌ YANLIŞ - Deep nesting
function calculateDiscount(order: Order): number {
  if (order.customer) {
    if (order.customer.isPremium) {
      if (order.total > 1000) { discount = 0.15; }
    }
  }
}

// ✅ DOĞRU - Guard clauses
function calculateDiscount(order: Order): number {
  if (!order.customer) return getGuestDiscount(order.total);
  let discount = order.customer.isPremium ? getPremiumDiscount(order.total) : getRegularDiscount(order.total);
  return order.total * Math.min(discount, 0.50);
}
```

- [ ] **Replace Conditional with Polymorphism** - Type-based logic'i polymorphism'e çevir
```typescript
// ❌ YANLIŞ - Type-based switch
function getShippingCost(method: string): number {
  switch (method) { case 'standard': return weight * 0.5; case 'express': return weight * 1.0; default: throw new Error('Unknown method'); }
}
// ✅ DOĞRU - Polymorphism
interface ShippingMethod { calculateCost(weight: number): number; getDeliveryDays(): number; }
class StandardShipping implements ShippingMethod { calculateCost(weight: number): number { return weight * 0.5; } getDeliveryDays(): number { return 5; } }
```

- [ ] **Extract Class** - İlgili veri ve method'ları yeni sınıfa taşı

## ⛔ NEVER
- [ ] **Never Refactor Without Tests** - Testsiz refactoring = gambling
- [ ] **Never Change Behavior** - Behavior change = bug değil yeni feature
- [ ] **Never Refactor and Add Features** - İkisi ayrı commit olmalı
- [ ] **Never Big Bang Refactoring** - Küçük adımlar, tekrarlanan commit'ler

## 🔗 Referanslar
- [Refactoring by Martin Fowler](https://refactoring.com/)
- [Refactoring Catalog](https://refactoring.guru/refactoring)
- [Working Effectively with Legacy Code](https://www.oreilly.com/library/view/working-effectively-with/0131177052/)
