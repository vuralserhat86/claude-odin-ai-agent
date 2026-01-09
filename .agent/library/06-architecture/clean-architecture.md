# Clean Architecture

> v1.0.0 | 2026-01-09

## 🔴 MUST
- [ ] **Dependency Rule** - Dependencies point inward
```
┌─────────────────────────────────────────┐
│         Frameworks & Drivers            │
├─────────────────────────────────────────┤
│          Interface Adapters             │
├─────────────────────────────────────────┤
│            Use Cases                    │
├─────────────────────────────────────────┤
│             Entities                    │
└─────────────────────────────────────────┘
```

- [ ] **Entities Core** - Business rules en içte (framework-independent)
```typescript
// ✅ DOĞRU - Pure business rules
export class UserEntity {
  static validateEmail(email: string): void {
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
      throw new ValidationError('Invalid email format');
  }
  static isAdult(birthDate: Date): boolean {
    const age = new Date().getFullYear() - birthDate.getFullYear();
    return age >= 18;
  }
}
```

- [ ] **Use Cases** - Application business rules
```typescript
// ✅ DOĞRU - Use case implementation
export class RegisterUserUseCase {
  constructor(private userRepo: IUserRepository, private emailService: IEmailService) {}
  async execute(request: RegisterUserRequest): Promise<User> {
    UserEntity.validateEmail(request.email);
    const exists = await this.userRepo.existsByEmail(request.email);
    if (exists) throw new ConflictError('User with this email already exists');
    const user = { id: crypto.randomUUID(), name: request.name.trim(), email: request.email.toLowerCase() };
    const savedUser = await this.userRepo.save(user);
    await this.emailService.sendWelcomeEmail(savedUser);
    return savedUser;
  }
}
```

- [ ] **Interface Adapters** - Framework-specific code
```typescript
// ✅ DOĞRU - Web controller
export class RegisterUserController {
  constructor(private registerUserUseCase: IRegisterUserUseCase) {}
  async handle(req: Request, res: Response): Promise<void> {
    try {
      const user = await this.registerUserUseCase.execute(req.body);
      res.status(201).json({ success: true, data: { id: user.id } });
    } catch (error) {
      if (error instanceof ValidationError) res.status(400).json({ success: false, error: { code: 'VALIDATION_ERROR' } });
    }
  }
}
```

## 🟡 SHOULD
- [ ] **DTO Transformation** - Layer boundaries'da DTO transform et
- [ ] **Interface Segregation** - Small, focused interfaces

## ⛔ NEVER
- [ ] **Never Skip Layers** - Direct database access from controller
```typescript
// ❌ YANLIŞ - Skipping layers
class UserController {
  async register(req: Request) {
    const user = await db.users.insert(req.body); // Direct DB access!
    res.status(201).json(user);
  }
}
// ✅ DOĞRU - Proper layering
class UserController {
  constructor(private useCase: IRegisterUserUseCase) {}
  async register(req: Request) {
    const user = await this.useCase.execute(req.body);
    res.status(201).json(user);
  }
}
```

- [ ] **Never Business Logic in Controllers** - Controllers sadece routing
- [ ] **Never Framework in Entities** - Entities framework-independent
- [ ] **Never Circular Dependencies** - Inner layer outer layer import etmez

## 🔗 Referanslar
- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Clean Architecture TypeScript](https://github.com/stemmlerjs/ddd-forum)
