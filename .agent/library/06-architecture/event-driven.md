# Event-Driven Architecture

> v1.0.0 | 2026-01-09 | RabbitMQ, Kafka, Redis

## 🔴 MUST
- [ ] **Immutable Events** - Events never mutate edilmeli
```typescript
// ✅ DOĞRU - Immutable events
interface UserCreatedEvent {
  eventId: string;
  eventType: 'UserCreated';
  version: 1;
  timestamp: Date;
  data: { userId: string; name: string; email: string };
}

// Event factory
export class EventFactory {
  static create<T>(eventType: string, data: T): DomainEvent {
    return { eventId: crypto.randomUUID(), eventType, version: 1, timestamp: new Date(), data };
  }
}
```

- [ ] **Event Naming** - Past tense verb kullan (UserCreated, not CreateUser)
```typescript
// ❌ YANLIŞ - Command-style
interface CreateUserEvent { eventType: 'CreateUser'; }
// ✅ DOĞRU - Event-style (past tense)
interface UserCreatedEvent { eventType: 'UserCreated'; }
```

- [ ] **Idempotent Handlers** - Event handlers idempotent olmalı
```typescript
// ✅ DOĞRU - Idempotent event handler
class OrderEventHandler {
  async handleUserUpdated(event: UserUpdatedEvent): Promise<void> {
    const processed = await this.eventStore.isProcessed(event.eventId);
    if (processed) return; // Skip if already processed
    await this.orderRepository.updateUserDetails({ userId: event.data.userId });
    await this.eventStore.markAsProcessed(event.eventId);
  }
}
```

- [ ] **Dead Letter Queue** - Failed events için DLQ kullan

## 🟡 SHOULD
- [ ] **Event Sourcing** - Events as source of truth store et
- [ ] **CQRS** - Separate read/write models
```typescript
// ✅ DOĞRU - CQRS pattern
// Write model (command side)
class WriteOrderService {
  async createOrder(command: CreateOrderCommand): Promise<string> {
    const order = new OrderAggregate(command.userId, command.items);
    await this.writeDb.save(order);
    await this.eventBus.publish('OrderCreated', { orderId: order.id });
    return order.id;
  }
}

// Read model (query side)
class ReadOrderProjection {
  @EventHandler('OrderCreated')
  async onOrderCreated(event: OrderCreatedEvent): Promise<void> {
    await this.readDb.insert('orders_view', { orderId: event.orderId });
  }
}
```

- [ ] **Schema Evolution** - Backward compatible event changes
```typescript
// ❌ YANLIŞ - Breaking change
{ eventType: 'UserCreated', data: { userId, fullName } } // name -> fullName
// ✅ DOĞRU - Backward compatible
{ eventType: 'UserCreated', version: 2, data: { userId, name, fullName } } // Keep old, add new
```

## ⛔ NEVER
- [ ] **Never Use Events for Commands** - Events = past, Commands = future
```typescript
// ❌ YANLIŞ - Command as event
interface CreateUserEvent { eventType: 'CreateUser'; }
// ✅ DOĞRU - Event describes past
interface UserCreatedEvent {
  eventType: 'UserCreated';
  data: { userId: string; createdAt: Date };
}
```

- [ ] **Never Create God Handler** - Single her şeyi handle etmemeli
- [ ] **Never Break Event Contract** - Backward compatibility'ı koru
- [ ] **Never Skip Idempotency** - At-least-once delivery = idempotency şart

## 🔗 Referanslar
- [Event-Driven Architecture](https://martinfowler.com/articles/201701-event-driven.html)
- [Enterprise Integration Patterns](https://www.enterpriseintegrationpatterns.com/)
- [RabbitMQ Tutorials](https://www.rabbitmq.com/getstarted.html)
