# Hexagonal Architecture

> v1.0.0 | 2026-01-09

## 🔴 MUST
- [ ] **Domain Core Isolated** - External dependencies'den izole
```typescript
export interface User {
  id: string; name: string; email: string;
  passwordHash: string; createdAt: Date;
}
export class UserDomainService {
  validateEmail(email: string): void {
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new Error('Invalid email');
    }
  }
}
```
- [ ] **Ports as Interfaces** - Input/Output port'lar interface
```typescript
export interface IRegisterUserInputPort {
  register(request: RegisterUserRequest): Promise<User>;
}
export interface IUserRepository {
  save(user: User): Promise<User>;
  findByEmail(email: string): Promise<User | null>;
}
```
- [ ] **Use Cases** - Application layer implements input ports
```typescript
export class RegisterUserUseCase implements IRegisterUserInputPort {
  constructor(
    private userDomainService: UserDomainService,
    private userRepo: IUserRepository,
    private emailSender: IEmailSender
  ) {}
  async register(request: RegisterUserRequest): Promise<User> {
    this.userDomainService.validateEmail(request.email);
    const savedUser = await this.userRepo.save(user);
    await this.emailSender.sendWelcomeEmail(savedUser.email, savedUser.name);
    return savedUser;
  }
}
```
- [ ] **Adapters Implement Ports** - Adapters implement ports
```typescript
export class MongoUserRepository implements IUserRepository {
  async save(user: User): Promise<User> {
    await this.client.db('myapp').collection('users').updateOne(
      { _id: new ObjectId(user.id) }, { $set: user }, { upsert: true }
    );
    return user;
  }
}
```

## 🟡 SHOULD
- [ ] **In-Memory Adapters** - Test için fake adapters
```typescript
class InMemoryUserRepository implements IUserRepository {
  private users = new Map<string, User>();
  async save(user: User): Promise<User> {
    this.users.set(user.id, user); return user;
  }
}
```
- [ ] **Dependency Inversion** - Core external katmanlara bağımlı değil

## ⛔ NEVER
- [ ] **Infrastructure in Domain** - Core pure olmalı
```typescript
// ❌ YANLIŞ
export class User {
  constructor(private db: mongoose.Model<User>) {}
  async save() { await this.db.save(this); }
}
// ✅ DOĞRU
export class User {
  constructor(private id: string, private name: string) {}
}
```
- [ ] **Business Logic in Adapters** - Adapters sadece translation
- [ ] **Skip Ports** - Her interaction için port tanımla

## 🔗 Referanslar
- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal/)
- [Ports and Adapters](https://herbertograca.com/2017/09/14/ports-adapters-architecture/)
