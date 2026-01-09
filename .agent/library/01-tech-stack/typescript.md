# TypeScript - Type-Safe JavaScript Rules

> v1.0.0 | 2026-01-09 | TypeScript 5.3+

## 🔴 MUST
- [ ] **Explicit Types for Public APIs** - Public function signatures explicit types
```typescript
// ❌ Wrong - No types
function getUser(id) { return fetch(`/api/users/${id}`).then(r => r.json()); }
// ✅ Right - Explicit types
interface User { id: string; name: string; email: string; }
async function getUser(id: string): Promise<User> {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}
```

- [ ] **No Any Types** - `any` kullanma, proper types kullan
- [ ] **Strict Mode Enabled** - tsconfig.json'da strict: true
```json
{ "compilerOptions": { "strict": true, "strictNullChecks": true, "noImplicitAny": true } }
```

- [ ] **Type Guards Instead of Assertions** - Type guards kullan
```typescript
// ❌ Wrong - Type assertion
const user = data as User;
// ✅ Right - Type guard
function isUser(data: unknown): data is User {
  return typeof data === 'object' && data !== null && 'id' in data && 'name' in data;
}
if (isUser(data)) console.log(data.name);
```

- [ ] **Optional Chaining** - Nullish coalescing kullan
```typescript
const name = user?.name ?? 'Unknown';
```

- [ ] **Discriminated Unions** - Complex unions için discriminated unions
```typescript
type State = LoadingState | SuccessState | ErrorState;
function handleState(state: State) {
  switch (state.status) {
    case 'loading': console.log('Loading...'); break;
    case 'success': console.log(state.data); break;
    case 'error': console.error(state.error); break;
  }
}
```

## 🟡 SHOULD
- [ ] **Utility Types** - Built-in utility types kullan
```typescript
interface User { id: string; name: string; email: string; age: number; }
type UserUpdate = Partial<User>;
type UserPreview = Pick<User, 'id' | 'name'>;
type CreateUser = Omit<User, 'id'>;
```

- [ ] **Branded Types** - Domain-specific types için branded types
```typescript
type UserId = string & { readonly __brand: unique symbol };
```

- [ ] **Descriptive Generic Names** - T yerine descriptive names
```typescript
// ❌ Wrong
function getData<T>(url: string): Promise<T> { }
// ✅ Right
async function fetchJson<TData>(url: string): Promise<TData> {
  const response = await fetch(url);
  return response.json();
}
```

- [ ] **Generic Constraints** - Generics'i constrain et
```typescript
interface Identifiable { id: string; }
function findById<T extends Identifiable>(items: T[], id: string): T | undefined {
  return items.find(item => item.id === id);
}
```

- [ ] **Path Aliases** - Import path'leri için alias kullan
```json
{ "compilerOptions": { "baseUrl": ".", "paths": { "@/*": ["./src/*"] } } }
```

## ⛔ NEVER
- [ ] **Never Use Any** - `any` type safety'i öldürür
- [ ] **Never Suppress Errors with @ts-ignore** - @ts-ignore kullanma
- [ ] **Never Duplicate Types** - DRY principle types için de geçerli
```typescript
// ❌ Wrong - Duplicate fields
interface AdminUser { id: string; name: string; email: string; admin: boolean; }
// ✅ Right - Extend
interface AdminUser extends User { admin: boolean; }
```

- [ ] **Never Disable Strict Mode** - Strict mode TypeScript'in gücü
- [ ] **Never Use @ts-nocheck** - Entire file bypass yok
- [ ] **Never Non-Null Assertion** - `!` kullanma, proper guards kullan

## 🔗 Referanslar
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/intro.html)
- [TypeScript Deep Dive](https://basarat.gitbook.io/typescript/)
- [Effective TypeScript](https://effectivetypescript.com/)
