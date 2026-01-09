# TDD - Test-Driven Development Rules

> v1.0.0 | 2026-01-09 | Jest, Vitest, Pytest

## 🔴 MUST
- [ ] **Red-Green-Refactor** - TDD cycle'ini strict follow et
```typescript
// RED: Write failing test
test('should add two positive numbers', () => {
  const calc = new Calculator();
  expect(calc.add(2, 3)).toBe(5);
});
// GREEN: Minimal implementation to pass
class Calculator {
  add(a: number, b: number): number { return 5; } // Hard-coded to pass
}
// REFACTOR: Real implementation
class Calculator {
  add(a: number, b: number): number { return a + b; }
}
```

- [ ] **Write Test First** - Her zaman test önce, implementation sonra
```typescript
// ❌ Wrong - Implementation first, test later
class Calculator {
  add(a: number, b: number): number { return a + b; }
}
// ✅ Right - TDD approach
test('should add two numbers', () => {
  expect(new Calculator().add(2, 3)).toBe(5);
});
```

- [ ] **Minimal Implementation** - Test'i geçecek minimal implementation
- [ ] **One Behavior Per Test** - Her test tek behavior test et

## 🟡 SHOULD
- [ ] **Small Iterations** - Tıkanma avoid et için küçük adımlar
```typescript
// Step 1: Write first failing test
test('should return true for valid email', () => {
  expect(EmailValidator.isValid('test@example.com')).toBe(true);
});
// Step 2: Minimal implementation
class EmailValidator {
  static isValid(email: string): boolean { return email.includes('@'); }
}
// Step 3: Next failing test
test('should return false for email without domain', () => {
  expect(EmailValidator.isValid('test@')).toBe(false);
});
// Step 4: Refactor
class EmailValidator {
  static isValid(email: string): boolean { return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email); }
}
```

- [ ] **Use Test Doubles** - Slow dependencies için in-memory fakes
```typescript
// In-memory fake for testing
class InMemoryUserRepository implements UserRepository {
  private users: Map<string, User> = new Map();
  async findByEmail(email: string): Promise<User | null> { return this.users.get(email) || null; }
  async save(user: User): Promise<User> {
    this.users.set(user.email, user);
    return user;
  }
}
```

- [ ] **Refactor with Confidence** - Tests refactor için güven verir
- [ ] **Run Tests Frequently** - Test'leri sık sık çalıştır
- [ ] **Commit After Green** - Her green test'ten sonra commit

## ⛔ NEVER
- [ ] **Never Skip Red Phase** - Test önce implementation sonra
```typescript
// ❌ Wrong - Implementation first
class UserService {
  async register(email: string, password: string): Promise<User> {
    const existing = await this.db.findByEmail(email);
    if (existing) throw new Error('Email exists');
    return this.db.save(new User(email, await hash(password)));
  }
}
// ✅ Right - TDD flow
test('should throw error for duplicate email', async () => {
  const service = new UserService(mockRepo);
  mockRepo.findByEmail.mockResolvedValue(existingUser);
  await expect(service.register('test@example.com', 'pass')).rejects.toThrow('Email already exists');
});
```

- [ ] **Never Write Too Many Tests at Once** - Birer birer test yaz
- [ ] **Never Implement Without Test** - Her code test'den doğmalı
- [ ] **Never Ignore Failing Tests** - Failing test'ler immediate fix edilmeli

## 🔗 Referanslar
- [Test-Driven Development by Example](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)
- [Growing Object-Oriented Software](https://www.amazon.com/Growing-Object-Oriented-Software-Guided-Tests/dp/0321503627)
- [TDD Best Practices](https://martinfowler.com/bliki/TestDrivenDevelopment.html)
