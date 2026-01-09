# SQL - Relational Database Rules

> v1.0.0 | 2026-01-09 | PostgreSQL, MySQL, SQLite

## 🔴 MUST
- [ ] **Parameterized Queries** - SQL injection prevention
```typescript
// ❌ Wrong - SQL injection
const query = `SELECT * FROM users WHERE email = '${email}'`;
// ✅ Right
const query = `SELECT id, name FROM users WHERE email = $1`;
await db.query(query, [email]);
```
- [ ] **Explicit Columns** - SELECT * yerine explicit
```typescript
const query = `SELECT id, name, email FROM users WHERE id = $1`;
```
- [ ] **Transactions** - Multi-step operations
```typescript
async function transferMoney(fromId: string, toId: string, amount: number) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    await client.query('UPDATE accounts SET balance = balance - $1 WHERE id = $2', [amount, fromId]);
    await client.query('UPDATE accounts SET balance = balance + $1 WHERE id = $2', [amount, toId]);
    await client.query('COMMIT');
  } catch {
    await client.query('ROLLBACK');
    throw;
  } finally {
    client.release();
  }
}
```
- [ ] **Proper Schema** - PK, FK, constraints
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
CREATE INDEX idx_users_email ON users(email);
```
- [ ] **Connection Pooling** - Pool kullan
```typescript
const pool = new Pool({ max: 20, idleTimeoutMillis: 30000 });
```

## 🟡 SHOULD
- [ ] **Avoid N+1** - JOIN kullan
```typescript
// ❌ N+1 problem
for (const user of users) {
  user.posts = await db.query('SELECT * FROM posts WHERE user_id = $1', [user.id]);
}
// ✅ Single query with JOIN
const query = `SELECT u.*, json_agg(p) as posts FROM users u LEFT JOIN posts p ON p.user_id = u.id GROUP BY u.id`;
```
- [ ] **Pagination** - Large result sets için
- [ ] **Check Constraints** - Data validation
```sql
ALTER TABLE users ADD CONSTRAINT check_age CHECK (age >= 18);
```
- [ ] **Enum Types** - Fixed values
```sql
CREATE TYPE user_role AS ENUM ('admin', 'user');
```
- [ ] **Soft Deletes** - Veri kaybı önlemek için
- [ ] **EXPLAIN ANALYZE** - Slow queries optimize et

## ⛔ NEVER
- [ ] **SELECT *** - Explicit columns kullan
- [ ] **String Concatenation** - Parameterized queries
- [ ] **Ignore Query Results** - Results check et
```typescript
const result = await db.query('UPDATE users SET last_login = NOW() WHERE id = $1', [userId]);
if (result.rowCount === 0) throw new Error('User not found');
```
- [ ] **Reserved Keywords** - Table/column names avoid et
- [ ] **Auto-Increment IDs** - UUID kullan
```sql
-- ❌ Guessable IDs
CREATE TABLE users (id SERIAL PRIMARY KEY);
-- ✅ UUID
CREATE TABLE users (id UUID PRIMARY KEY DEFAULT gen_random_uuid());
```
- [ ] **JSON in Text** - JSONB kullan
```sql
ALTER TABLE users ADD COLUMN metadata JSONB;
CREATE INDEX idx_users_metadata ON users USING GIN (metadata);
```

## 🔗 Referanslar
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MySQL Reference Manual](https://dev.mysql.com/doc/)
- [SQL Style Guide](https://www.sqlstyle.guide/)
