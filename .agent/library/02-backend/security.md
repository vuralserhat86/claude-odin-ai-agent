# Security - Application Security Rules

> v1.0.0 | 2026-01-09 | Web Security

## 🔴 MUST
- [ ] **Hash Passwords** - bcrypt/argon2 kullan
```typescript
import bcrypt from 'bcrypt';
async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}
```
- [ ] **JWT Expiration** - Kısa expiration ile
```typescript
jwt.sign(payload, process.env.JWT_SECRET!, { expiresIn: '1h' });
```
- [ ] **Validate Inputs** - Server-side validation (zod)
```typescript
const schema = z.object({ email: z.string().email() });
const validated = schema.parse(req.body);
```
- [ ] **Parameterized Queries** - SQL injection prevention
```typescript
await db.query('SELECT * FROM users WHERE email = $1', [email]);
```
- [ ] **HTTPS Only** - Production'da HTTPS
- [ ] **Security Headers** - Helmet middleware
```typescript
app.use(helmet({ hsts: { maxAge: 31536000 } }));
```
- [ ] **CORS** - Correct configuration
```typescript
app.use(cors({ origin: allowedOrigins, credentials: true }));
```

## 🟡 SHOULD
- [ ] **Secure Cookies** - HttpOnly, Secure, SameSite
```typescript
cookie: { httpOnly: true, secure: true, sameSite: 'strict' }
```
- [ ] **Refresh Token Rotation** - Implement rotation
- [ ] **Rate Limiting** - API endpoints limit et
```typescript
rateLimit({ windowMs: 15 * 60 * 1000, max: 5 });
```
- [ ] **Account Lockout** - Brute force protection
- [ ] **Audit Logging** - Sensitive operations log et

## ⛔ NEVER
- [ ] **Plain Text Passwords** - Hashing şart
- [ ] **MD5/SHA1** - Weak algorithms
- [ ] **Passwords in URL** - Never URL parameters
- [ ] **Tokens in Error** - Error'da tokens expose etme
- [ ] **Internal IDs** - UUID kullan
- [ ] **Full Error Details** - Generic messages
- [ ] **Log Sensitive Data** - Passwords log etme

## 🔗 Referanslar
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP Cheat Sheets](https://cheatsheetseries.owasp.org/)
- [Helmet.js](https://helmetjs.github.io/)
