# Code Style - Consistent Code Formatting Rules

> v1.0.0 | 2026-01-09 | Prettier, ESLint, Black

## 🔴 MUST
- [ ] **Prettier Configuration** - Setup ve run et
```json
// .prettierrc
{
  "semi": true, "trailingComma": "es5", "singleQuote": true,
  "printWidth": 100, "tabWidth": 2, "arrowParens": "always"
}
```
- [ ] **ESLint Configuration** - Linting rules setup et
```json
{
  "extends": ["eslint:recommended", "plugin:@typescript-eslint/recommended", "prettier"],
  "rules": { "no-console": "warn", "no-debugger": "error" }
}
```
- [ ] **Pre-Commit Hooks** - Auto-format pre-commit'te çalıştır
```bash
npm install -D husky lint-staged
npx husky install
```
- [ ] **CI Validation** - CI'da format check et

## 🟡 SHOULD
- [ ] **Group Imports** - Import'ları group et (third-party, internal, types)
```typescript
// Third-party
import express from 'express';
// Type imports
import type { User } from '@/types';
// Internal
import { userService } from '@/services/userService';
```
- [ ] **Max Line Length** - 100 character limit
- [ ] **JSDoc for Public APIs** - Public functions için JSDoc
```typescript
/**
 * Creates a new user in the system
 * @param email - User's email (must be unique)
 * @returns The created user with generated ID
 */
async function createUser(email: string): Promise<User>
```
- [ ] **Explain Why, Not What** - Comments "why" explain etmeli
```typescript
// Using FIFO queue to ensure messages are processed in order
const queue = new FIFOQueue();
```

## ⛔ NEVER
- [ ] **Never Mix Tabs and Spaces** - Consistent indentation
```typescript
// ❌ Mixed
function example() {
	if (true) { console.log(); } // Tab
    	console.log(); // Spaces
}
// ✅ Clean
function example() {
  if (true) { console.log(); }
}
```
- [ ] **Never Commented Out Code** - Git history kullan
```typescript
// ❌ Commented code
// const old = () => { };
// ✅ Git history
function newImplementation() { }
```
- [ ] **Never Trailing Whitespace** - Remove et
- [ ] **Never Multiple Blank Lines** - Max 2 consecutive

## 🔗 Referanslar
- [Prettier Documentation](https://prettier.io/docs/en/)
- [ESLint Documentation](https://eslint.org/docs/latest/)
- [Airbnb Style Guide](https://github.com/airbnb/javascript)
