# NoSQL - Non-Relational Database Rules

> v1.0.0 | 2026-01-09 | MongoDB, Redis, DynamoDB

## 🔴 MUST
- [ ] **Mongoose Schemas** - Schema validation ile data integrity
```typescript
import mongoose from 'mongoose';
const userSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true, lowercase: true },
  password: { type: String, required: true, minlength: 8 }
}, { timestamps: true });
userSchema.index({ email: 1 });
export const User = mongoose.model('User', userSchema);
```
- [ ] **Indexing Strategy** - Query patterns için indexes
- [ ] **Connection Pooling** - Pool configure et
```typescript
await mongoose.connect(process.env.MONGODB_URI!, {
  maxPoolSize: 10, minPoolSize: 5, socketTimeoutMS: 45000
});
```
- [ ] **Required Fields & Enums** - Validation rules

## 🟡 SHOULD
- [ ] **Projection** - Sadece gerekli fields
```typescript
const users = await User.find({ role: 'user' })
  .select('name email createdAt').limit(100);
```
- [ ] **Lean Queries** - Large result sets için `.lean()`
- [ ] **Bulk Operations** - Multiple inserts için `bulkWrite`
- [ ] **Embed vs Reference** - Frequent access → embed, scalability → reference
- [ ] **Redis Cache** - Frequently accessed data cache et
```typescript
import Redis from 'ioredis';
const redis = new Redis({ host: process.env.REDIS_HOST });
export async function getUser(userId: string) {
  const cached = await redis.get(`user:${userId}`);
  if (cached) return JSON.parse(cached);
  const user = await User.findById(userId);
  if (user) await redis.setex(`user:${userId}`, 300, JSON.stringify(user));
  return user;
}
```

## ⛔ NEVER
- [ ] **Regex Without Indexes** - Slow without indexes
- [ ] **Large Arrays** - Pagination ile, separate collection kullan
- [ ] **$where Clauses** - JavaScript evaluation security risk
- [ ] **Unbounded Arrays** - Bounded array validation
```typescript
recentLogins: {
  type: [Date],
  validate: { validator: (v) => v.length <= 10 }
}
```
- [ ] **Deep Nesting** - Flatten structure
- [ ] **Mixed Data Types** - Explicit schema kullan
- [ ] **Forget TTL Indexes** - Auto-expiration için TTL

## 🔗 Referanslar
- [MongoDB Best Practices](https://www.mongodb.com/docs/manual/administration/production-notes/)
- [Mongoose Documentation](https://mongoosejs.com/docs/)
- [Redis Best Practices](https://redis.io/docs/manual/patterns/)
