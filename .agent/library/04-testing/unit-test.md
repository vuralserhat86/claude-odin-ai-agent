# Unit Testing - Test Isolation Rules

> v1.0.0 | 2026-01-09 | Jest, Vitest, Pytest

## 🔴 MUST
- [ ] **AAA Pattern** - Arrange, Act, Assert
```typescript
describe('User.setName()', () => {
  it('should update user name when valid name is provided', () => {
    // Arrange
    const user = new User('John');
    const newName = 'Jane';
    // Act
    user.setName(newName);
    // Assert
    expect(user.getName()).toBe(newName);
  });
});
```
- [ ] **Test Isolation** - Her test independent
- [ ] **Descriptive Names** - should... when... format
- [ ] **One Assertion** - Her test tek assertion
- [ ] **Critical Path Coverage** - Critical code 100%
- [ ] **Mock Dependencies** - External services mock et
```typescript
const mockDb = { insert: jest.fn().mockResolvedValue({ id: '123' }) };
const service = new UserService(mockDb);
await service.createUser({ email: 'test@example.com' });
expect(mockDb.insert).toHaveBeenCalledWith(expect.objectContaining({ email: 'test@example.com' }));
```

## 🟡 SHOULD
- [ ] **Group Related Tests** - describe blocks
```typescript
describe('UserService', () => {
  let service: UserService;
  beforeEach(() => { service = new UserService(mockDb); });
  describe('createUser()', () => {
    it('should create user with valid data', async () => { });
  });
});
```
- [ ] **Setup/Teardown** - beforeEach/afterEach
- [ ] **Test Data Builders** - Factories kullan
```typescript
class UserBuilder {
  private user: Partial<User> = { id: 'test-id', name: 'Test' };
  static aUser(): UserBuilder { return new UserBuilder(); }
  withId(id: string): UserBuilder { this.user.id = id; return this; }
  build(): User { return this.user as User; }
}
```
- [ ] **Specific Assertions** - Specific matchers
- [ ] **Async Testing** - Proper async handling
```typescript
await expect(service.createUser({ email: 'invalid' }))
  .rejects.toThrow('Invalid email');
```
- [ ] **Faker** - Realistic test data
```typescript
import { faker } from '@faker-js/faker';
return { id: faker.uuid.v4(), name: faker.person.fullName() };
```

## ⛔ NEVER
- [ ] **Test Implementation Details** - Public behavior test et
```typescript
// ❌ Testing private methods
expect(service['privateMethod']()).toBe(true);
// ✅ Testing public behavior
expect(service.formatForDisplay(user)).toEqual('John (john@example.com)');
```
- [ ] **Test Third-Party Code** - Library'leri trust et
- [ ] **Flaky Tests** - Non-deterministic tests fix et
```typescript
// ❌ Time-dependent
setTimeout(() => { expect(session.isValid()).toBe(false); }, 3600000);
// ✅ Fake timers
jest.useFakeTimers();
jest.advanceTimersByTime(3600000);
expect(session.isValid()).toBe(false);
```
- [ ] **No Assertion** - Her test assertion içermeli

## 🔗 Referanslar
- [Jest Documentation](https://jestjs.io/docs/getting-started)
- [Vitest Documentation](https://vitest.dev/)
- [Testing Best Practices](https://testingjavascript.com/)
