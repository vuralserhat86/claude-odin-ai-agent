# Integration Testing

> v1.0.0 | 2026-01-09 | Supertest, TestContainers, MSW

## 🔴 MUST
- [ ] **Separate Test Database** - Integration test'ler için ayrı database kullan
```typescript
// ✅ DOĞRU - Test database setup
const db = new Database(process.env.TEST_DB_URL);
beforeAll(async () => await db.migrate.latest());
beforeEach(async () => { await db('users').delete(); await db('posts').delete(); });
afterAll(async () => await db.destroy());
```

- [ ] **Test Real HTTP** - HTTP endpoint'lerini gerçek test et (Supertest)
```typescript
// ✅ DOĞRU - API integration test
import request from 'supertest';
describe('POST /api/users', () => {
  it('should create user with valid data', async () => {
    const response = await request(app).post('/api/users').send({ email: 'test@example.com', password: 'password123', name: 'Test User' }).expect(201).expect('Content-Type', /json/);
    expect(response.body).toMatchObject({ success: true, data: { id: expect.any(String), email: 'test@example.com' } });
    expect(response.body.data).not.toHaveProperty('password');
  });
});
```

- [ ] **Transaction Rollback** - Database test'leri için transaction rollback kullan
```typescript
// ✅ DOĞRU - Transaction rollback
describe('UserService integration', () => {
  let transaction: Transaction;
  beforeEach(async () => { transaction = await db.transaction(); });
  afterEach(async () => { await transaction.rollback(); });
  it('should create user in database', async () => {
    const service = new UserService(transaction);
    const user = await service.createUser({ email: 'test@example.com' });
    const dbUser = await transaction('users').where('id', user.id).first();
    expect(dbUser).toBeDefined();
  });
});
```

- [ ] **Isolated Tests** - Her test bağımsız çalışmalı
```typescript
// ❌ YANLIŞ - Shared test state
let sharedUserId: string;
it('creates user', async () => { sharedUserId = user.id; });
it('deletes user', async () => { await deleteUser(sharedUserId); });
// ✅ DOĞRU - Isolated test
it('creates and deletes user', async () => { const user = await createUser({ name: 'Test' }); await deleteUser(user.id); expect(await findUser(user.id)).toBeNull(); });
```

## 🟡 SHOULD
- [ ] **Mock External APIs** - External services mock et (MSW, Nock)
```typescript
// ✅ DOĞRU - Mocking with MSW
import { setupServer } from 'msw/node'; import { rest } from 'msw';
const server = setupServer(rest.post('https://api.example.com/auth', (req, res, ctx) => res(ctx.status(200), ctx.json({ token: 'mock-token' }))));
beforeAll(() => server.listen()); afterEach(() => server.resetHandlers()); afterAll(() => server.close());
```

- [ ] **Test Auth Flows** - Login, logout, register, RBAC test et
```typescript
// ✅ DOĞRU - Role-based access testing
describe('Admin access control', () => {
  it('should allow admin to delete users', async () => { await request(app).delete('/api/users/some-user-id').set('Authorization', `Bearer ${adminToken}`).expect(204); });
  it('should deny user from deleting users', async () => { await request(app).delete('/api/users/some-user-id').set('Authorization', `Bearer ${userToken}`).expect(403); });
});
```

## ⛔ NEVER
- [ ] **Never Use Production Database** - Test data production'dan gelmemeli
```typescript
// ❌ YANLIŞ - Using production database
const db = new Database(process.env.DATABASE_URL); // Production!
// ✅ DOĞRU - Separate test database
const db = new Database(process.env.TEST_DB_URL);
```

- [ ] **Never Test Order-Dependent** - Test order matter etmemeli
```typescript
// ❌ YANLIŞ - Order-dependent tests
it('test 1', async () => { /* Expects empty DB */ });
it('test 2', async () => { /* Leaves data in DB */ });
it('test 3', async () => { /* Depends on test 2 */ });

// ✅ DOĞRU - Cleanup after each test
beforeEach(async () => await cleanupDatabase());
afterEach(async () => await cleanupDatabase());
```

## 🔗 Referanslar
- [Supertest Documentation](https://github.com/visionmedia/supertest)
- [Testcontainers](https://testcontainers.com/)
- [MSW Documentation](https://mswjs.io/)
- [Integration Testing Best Practices](https://kentcdodds.com/blog/write-tests)
