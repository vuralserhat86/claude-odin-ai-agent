# API Design - RESTful API Rules

> v1.0.0 | 2026-01-09 | REST/GraphQL

## 🔴 MUST
- [ ] **Correct HTTP Methods** - GET (read), POST (create), PUT/PATCH (update), DELETE (delete)
```typescript
// ❌ Wrong - RPC-style
GET /api/getUsers
POST /api/createUser
// ✅ Right - RESTful design
GET    /api/users           // List all users
GET    /api/users/123       // Get specific user
POST   /api/users           // Create new user
PUT    /api/users/123       // Update user (full)
PATCH  /api/users/123       // Update user (partial)
DELETE /api/users/123       // Delete user
```
- [ ] **Resource Naming** - Nouns kullan, verbs kullanma
```typescript
// ✅ Nested resources
GET  /api/users/123/posts        // Get user's posts
POST /api/users/123/posts        // Create post for user
GET  /api/posts/456/comments     // Get comments for post
```
- [ ] **Consistent Response Structure** - Tüm endpoint'ler aynı response format
```typescript
interface ApiResponse<T> {
  success: true;
  data: T;
  meta?: { page?: number; limit?: number; total?: number; };
}
interface ApiError {
  success: false;
  error: { code: string; message: string; details?: unknown; };
}
```
- [ ] **HTTP Status Codes** - Correct status codes döndür
```typescript
// 200 OK - Successful GET, PUT, PATCH
// 201 Created - Successful POST
// 204 No Content - Successful DELETE
// 400 Bad Request - Validation errors
// 401 Unauthorized - Authentication required
// 403 Forbidden - Not authorized
// 404 Not Found - Resource not found
// 409 Conflict - Duplicate resource
// 422 Unprocessable Entity - Semantic errors
// 500 Internal Server Error - Server errors
```
- [ ] **Idempotent Operations** - GET, PUT, DELETE idempotent olmalı

## 🟡 SHOULD
- [ ] **URL Versioning** - `/api/v1/`, `/api/v2/` format kullan
```typescript
/api/v1/users
/api/v2/users
// Deprecation header
res.setHeader('Deprecation', 'true');
res.setHeader('Sunset', '2026-01-01');
res.setHeader('Link', '</api/v2/users>; rel="successor-version"');
```
- [ ] **Cursor-Based Pagination** - Large datasets için cursor-based
```typescript
interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    nextCursor?: string;
    limit: number;
    hasMore: boolean;
  };
}
// GET /api/posts?limit=20&cursor=abc123
```
- [ ] **Filtering and Sorting** - Query params ile filtering
```typescript
// GET /api/users?agegte=18&role=user&sort=+name,-created_at
interface QueryParams {
  agegte?: number;      // age >= 18
  agelt?: number;       // age < 65
  role?: string;        // role == 'user'
  sort?: string;        // +name,-created_at
}
```
- [ ] **Rate Limiting** - API endpoint'leri rate limit et
```typescript
import rateLimit from 'express-rate-limit';
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // 5 attempts per window
  standardHeaders: true,
  message: 'Too many login attempts'
});
app.post('/api/auth/login', authLimiter, handleLogin);
```
- [ ] **Backward Compatibility** - Eski versiyonları desteklemeye devam et

## ⛔ NEVER
- [ ] **Never Use Verbs in URL** - URL nouns, HTTP methods verbs
```typescript
// ❌ Wrong
GET /api/getUsers
POST /api/createUser
// ✅ Right
GET /api/users
POST /api/users
```
- [ ] **Never Use Query Params for IDs** - Path parameters kullan
```typescript
// ❌ Wrong
GET /api/users?id=123
// ✅ Right
GET /api/users/123
```
- [ ] **Never Nest More Than 3 Levels** - Deep nesting avoid et
```typescript
// ❌ Wrong
GET /api/users/123/posts/456/comments/789/author
// ✅ Right
GET /api/users/123
GET /api/posts/456/comments
GET /api/comments/789/author
```
- [ ] **Never Return Null in Arrays** - Empty array kullan
```typescript
// ❌ Wrong
{ "posts": [null, null, { "id": "123" }] }
// ✅ Right
{ "posts": [] }
```
- [ ] **Never Inconsistent Casing** - Consistent casing (camelCase)
```typescript
// ❌ Wrong
{ "firstName": "John", "last_name": "Doe", "EmailAddress": "john@example.com" }
// ✅ Right
{ "firstName": "John", "lastName": "Doe", "emailAddress": "john@example.com" }
```
- [ ] **Never Expose Internal Errors** - Sanitize error messages
```typescript
// ❌ Wrong
{ "error": "Error: connect ECONNREFUSED 127.0.0.1:5432" }
// ✅ Right
{ "error": { "code": "DATABASE_ERROR", "message": "Unable to process request" } }
```
- [ ] **Never Return HTML from API** - JSON döndür

## 🔗 Referanslar
- [REST API Tutorial](https://restfulapi.net/)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
- [JSON API Specification](https://jsonapi.org/)
- [Google API Design Guide](https://cloud.google.com/apis/design)
