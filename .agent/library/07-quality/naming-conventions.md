# Naming Conventions - Clear Identifier Rules

> v1.0.0 | 2026-01-09 | TypeScript, Python

## 🔴 MUST
- [ ] **camelCase Variables** - Variables ve functions camelCase
```typescript
// ❌ Wrong
const d = new Date();
const u = await getUser(userId);
// ✅ Right
const currentDate = new Date();
const user = await getUser(userId);
```
- [ ] **PascalCase Classes** - Classes ve interfaces PascalCase
```typescript
// ❌ Wrong
class userManager {}
interface user_data {}
// ✅ Right
class UserManager {}
interface UserData {}
```
- [ ] **UPPER_CASE Constants** - Constants UPPER_CASE
```typescript
const MAX_RETRIES = 5;
const DEFAULT_TIMEOUT = 10000;
```
- [ ] **Boolean Prefixes** - is/has/should prefix ile
```typescript
const isActive = true;
const hasPermission = false;
const shouldUpdate = true;
```
- [ ] **Function Names Verb-First** - Verb-first naming
```typescript
function getUser() {}
function calculateTotal() {}
function validateInput() {}
```
- [ ] **File Naming Convention** - Consistent convention follow et
```
src/
├── components/
│   ├── Button.tsx        (PascalCase)
│   └── UserProfile.tsx   (PascalCase)
├── services/
│   ├── userService.ts    (camelCase)
│   └── authService.ts    (camelCase)
└── utils/
    └── formatDate.ts     (camelCase)
```

## 🟡 SHOULD
- [ ] **Ubiquitous Language** - Domain terms kullan
```typescript
// ✅ E-commerce context
interface Order {
  orderId: string;        // Not: oid
  customerId: string;     // Not: custId
  orderItems: OrderItem[];
}
```
- [ ] **Factory Functions** - `create` prefix ile
```typescript
function createUser(data: CreateUserDto): User {}
function createOrder(items: Item[]): Order {}
```
- [ ] **Converter Functions** - `to` prefix ile
```typescript
function toJSON(user: User): string {}
function toDTO(user: User): UserDTO {}
function fromJSON(json: string): User {}
```
- [ ] **Predicate Functions** - `is/has/can/should` prefix ile
```typescript
function isValidEmail(email: string): boolean {}
function hasPermission(user: User, permission: string): boolean {}
function canDelete(user: User): boolean {}
```
- [ ] **Handler Functions** - `handle` prefix ile
```typescript
function handleSubmit(event: FormEvent): void {}
function handleClick(event: MouseEvent): void {}
function handleError(error: Error): void {}
```
- [ ] **Type Suffixes** - `Interface`, `DTO`, `Entity`, `Model` suffix
```typescript
interface User {}
interface CreateUserDto {}
interface UserEntity {}
class UserModel {}
```
- [ ] **React Custom Hooks** - `use` prefix ile
```typescript
function useUser() {}
function useFormData() {}
function useAPI<T>() {}
```

## ⛔ NEVER
- [ ] **Never Single Letters** - Except loop counters
```typescript
// ❌ Wrong
const a = 1; const b = 2;
// ✅ Right (loops OK)
for (let i = 0; i < items.length; i++) { }
```
- [ ] **Never Misspelled Words** - Correct spelling zorunlu
```typescript
// ❌ Wrong
const recievedDate = new Date();
// ✅ Right
const receivedDate = new Date();
```
- [ ] **Never Numbers in Names** - `user1`, `user2` avoid et
```typescript
// ❌ Wrong
const user1 = users[0];
const user2 = users[1];
// ✅ Right
const primaryUser = users[0];
const secondaryUser = users[1];
```
- [ ] **Never Same Name Different Case** - Case-only differences yok
```typescript
// ❌ Wrong (confusing)
const User = getUser();
const user = User;
// ✅ Right
const userResponse = await getUser();
const userData = userResponse.data;
```
- [ ] **Never Unclear Abbreviations** - Full names kullan (except well-known)
```typescript
// ❌ Wrong
interface User { uid: string; em: string; }
// ✅ Right
interface User { id: string; email: string; }
```

## 🔗 Referanslar
- [Clean Code Naming](https://clean-code-javascript.com/#naming)
- [Google TypeScript Style Guide](https://google.github.io/styleguide/tsguide.html)
- [Airbnb Naming Conventions](https://github.com/airbnb/javascript#naming)
