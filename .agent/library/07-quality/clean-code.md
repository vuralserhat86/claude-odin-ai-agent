# Clean Code

> v1.0.0 | 2026-01-09

## 🔴 MUST
- [ ] **Açıklayıcı İsimler** - Değişken, fonksiyon isimleri niyeti belirtmeli
```typescript
// ❌ YANLIŞ - Anlamsız isimler
const d = new Date();
const data1 = fetchData();

// ✅ DOĞRU - Açıklayıcı isimler
const currentDate = new Date();
const rawUsers = await fetchUsersFromAPI();
const activeUsers = filterActiveUsers(rawUsers);
```

- [ ] **Küçük ve Tek Görev** - Her fonksiyon tek bir iş yapmalı
```typescript
// ❌ YANLIŞ - Çok şey yapan fonksiyon
async function processUserData(userId: string) {
  const user = await db.users.findOne(userId);
  const orders = await db.orders.find({ userId });
  user.vipStatus = orders.reduce((sum, o) => sum + o.total, 0) > 1000;
  await db.users.update(userId, user);
  await emailService.send(user.email, `You spent ${totalSpent}`);
  return { user, totalSpent };
}

// ✅ DOĞRU - Single responsibility
async function getUserById(userId: string): Promise<User> {
  const user = await db.users.findOne(userId);
  if (!user) throw new Error('User not found');
  return user;
}

async function calculateTotalSpent(userId: string): Promise<number> {
  const orders = await db.orders.find({ userId });
  return orders.reduce((sum, order) => sum + order.total, 0);
}
```

- [ ] **Az Argüman** - İdeal 0-2 argüman, 3'ten fazlası object parameter
```typescript
// ❌ YANLIŞ - Çok argüman
function createUser(name: string, email: string, age: number, address: string, city: string, country: string, postalCode: string, phone: string) { }

// ✅ DOĞRU - Object parameter
interface CreateUserParams {
  name: string;
  email: string;
  age: number;
  address: { street: string; city: string; country: string; postalCode: string; };
  phone: string;
}
function createUser(params: CreateUserParams): User { }
```

- [ ] **Flag Argüman Avoid** - Boolean flag = fonksiyon bölünmeli
```typescript
// ❌ YANLIŞ - Flag argument
function bookFlight(userId: string, isVip: boolean): void {
  if (isVip) { /* VIP booking */ } else { /* Regular */ }
}

// ✅ DOĞRU - Separate functions
function bookRegularFlight(userId: string): void { }
function bookVipFlight(userId: string): void { }
```

## 🟡 SHOULD
- [ ] **Named Constants** - Magic number'lar yerine constant kullan
```typescript
// ❌ YANLIŞ - Magic numbers
if (total > 1000) return total * 0.15;
// ✅ DOĞRU - Named constants
const DISCOUNT_THRESHOLDS = { HIGH: 1000, MEDIUM: 500, LOW: 100 } as const;
const DISCOUNT_RATES = { HIGH: 0.15, MEDIUM: 0.10, LOW: 0.05, NONE: 0 } as const;
```

- [ ] **Early Return** - Hataları erken return et
```typescript
// ❌ YANLIŞ - Deep nesting
if (userId) { const user = await db.users.findOne(userId); if (user) { if (user.isActive) { /* process */ } } }
// ✅ DOĞRU - Early return
if (!userId) throw new ValidationError('User ID is required');
const user = await db.users.findOne(userId);
if (!user) throw new NotFoundError('User', userId);
if (!user.isActive) throw new BusinessError('User account is inactive');
if (amount <= 0) throw new ValidationError('Amount must be positive');
return { success: true };
```

- [ ] **Kod Açık Olmalı** - Yorum yerine açık kod yaz

## ⛔ NEVER
- [ ] **Never Code Duplication** - Duplication = bug'lar
- [ ] **Never Dead Code** - Kullanılmayan kod sil
- [ ] **Never Premature Optimization** - İlk okunabilirlik, sonra optimizasyon
- [ ] **Never Over-Engineering** - Simple problem = simple çözüm

## 🔗 Referanslar
- [Clean Code by Robert C. Martin](https://www.oreilly.com/library/view/clean-code-a/9780136083238/)
- [Clean Code TypeScript](https://github.com/labs42io/clean-code-typescript)
- [Refactoring Guru](https://refactoring.guru/)
