# E2E Testing

> v1.0.0 | 2026-01-09 | Playwright, Cypress

## 🔴 MUST
- [ ] **Critical User Paths** - Sadece critical user journey'lerini test et
```typescript
// ✅ DOĞRU - Independent test, explicit wait
test('should complete registration and login', async ({ page }) => {
  const userEmail = `test${Date.now()}@example.com`;
  await page.goto('/register');
  await page.fill('[name="email"]', userEmail);
  await page.fill('[name="password"]', 'SecurePass123!');
  await page.click('[type="submit"]');
  await page.waitForURL('**/dashboard', { timeout: 5000 });
});
```

- [ ] **Explicit Waits** - Explicit wait strategies kullan, `waitForTimeout` yok
```typescript
// ❌ YANLIŞ - Zaman bağımlılığı
await page.waitForTimeout(5000);
// ✅ DOĞRU - Explicit wait
await page.waitForSelector('[data-testid="welcome-message"]');
```

- [ ] **Page Object Model** - UI actions reusable methods olarak tanımla
```typescript
// ✅ DOĞRU - Page Object Model
export class LoginPage {
  constructor(private page: Page) {}
  readonly emailInput = this.page.locator('[name="email"]');
  async goto() { await this.page.goto('/login'); }
  async login(email: string, password: string) {
    await this.emailInput.fill(email);
    await this.page.locator('[name="password"]').fill(password);
    await this.page.locator('[type="submit"]').click();
  }
}
```

- [ ] **Clean Test Data** - Her test için fresh data kullan

## 🟡 SHOULD
- [ ] **Visual Regression Testing** - Screenshot comparison kullan
```typescript
// ✅ DOĞRU - Visual regression
test('homepage matches screenshot', async ({ page }) => {
  await page.goto('/');
  await page.waitForLoadState('networkidle');
  await expect(page).toHaveScreenshot('homepage.png', { fullPage: true, maxDiffPixels: 100 });
});
```

- [ ] **Responsive Testing** - Different viewport sizes test et
- [ ] **API Testing in E2E** - API contract'ını da test et

## ⛔ NEVER
- [ ] **Never Test Third-Party Services** - External services'ı test etme (mock kullan)
```typescript
// ❌ YANLIŞ - Testing third-party service
test('Stripe payment works', async () => { /* DON'T test Stripe! */ });
// ✅ DOĞRU - Mock third-party service
await page.route('**/api/stripe/**', route => route.fulfill({ status: 200, body: JSON.stringify({ success: true }) }));
```

- [ ] **Never Test Implementation Details** - User behavior test et, implementation değil
```typescript
// ❌ YANLIŞ - Testing implementation
test('uses useState hook', async () => { /* Can't test React internals */ });
// ✅ DOĞRU - Testing user behavior
test('user can add item to cart', async ({ page }) => {
  await page.click('[data-testid="add-to-cart"]');
  await expect(page.locator('[data-testid="cart-count"]')).toHaveText('1');
});
```

- [ ] **Never Hardcoded Test Data** - Her test unique data kullanmalı

## 🔗 Referanslar
- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [Cypress Documentation](https://docs.cypress.io/guides/overview/why-cypress)
- [Page Object Model](https://playwright.dev/docs/pom)
