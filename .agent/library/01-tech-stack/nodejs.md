# Node.js - Backend JavaScript Runtime

> v1.0.0 | 2026-01-09 | Node.js 20+

## 🔴 MUST
- [ ] **Async/Await** - Callbacks kullanma
```typescript
async function getUserData(id: string): Promise<UserData> {
  const user = await db.getUser(id);
  const posts = await db.getPosts(user.id);
  return { user, posts };
}
```
- [ ] **Error Handling** - Her async operation error handling
```typescript
async function deleteUser(id: string): Promise<void> {
  try {
    const user = await db.getUser(id);
    if (!user) throw new NotFoundError(`User not found: ${id}`);
    await db.deleteUser(id);
  } catch (error) {
    console.error(`Failed to delete user ${id}:`, error);
    throw error;
  }
}
```
- [ ] **Custom Errors** - Domain-specific error classes
```typescript
class NotFoundError extends Error {
  constructor(message: string) {
    super(message); this.name = 'NotFoundError';
  }
}
```
- [ ] **ESM** - ES Modules kullan

## 🟡 SHOULD
- [ ] **Stream Large Data** - Streams kullan
```typescript
await pipeline(
  createReadStream(inputPath),
  transformStream,
  createWriteStream(outputPath)
);
```
- [ ] **Cluster Mode** - Multi-core utilization
- [ ] **Connection Pooling** - Database pool
```typescript
const pool = new Pool({ max: 20, idleTimeoutMillis: 30000 });
```
- [ ] **Input Validation** - Zod validation
```typescript
const schema = z.object({ email: z.string().email() });
const validated = schema.parse(req.body);
```
- [ ] **Security Headers** - Helmet middleware

## ⛔ NEVER
- [ ] **Mix Callbacks/Promises** - Choose one pattern
- [ ] **Block Event Loop** - Synchronous operations avoid et
```typescript
// ❌ Blocking
fs.readFileSync('file.txt');
// ✅ Non-blocking
await fs.promises.readFile('file.txt');
```
- [ ] **require() in ESM** - Dynamic import kullan
- [ ] **Large Objects in Memory** - Stream instead
- [ ] **Forget Close Connections** - Database connections close et
```typescript
const client = await pool.connect();
try { return await client.query('SELECT *'); }
finally { client.release(); }
```
- [ ] **Global Variables** - Module-level constants kullan

## 🔗 Referanslar
- [Node.js Documentation](https://nodejs.org/docs/latest-v20.x/api/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)
