# Error Handling

> v1.0.0 | 2026-01-09 | TypeScript, Python

## 🔴 MUST
- [ ] **Custom Error Classes** - Domain-specific error classes oluştur
```typescript
// ✅ DOĞRU - Custom error classes
export class AppError extends Error {
  constructor(
    public message: string,
    public code: string,
    public statusCode: number = 500,
    public isOperational: boolean = true
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND', 404);
  }
}

export class ValidationError extends AppError {
  constructor(field: string, message: string) {
    super(`Validation failed for ${field}: ${message}`, 'VALIDATION_ERROR', 400);
  }
}
```

- [ ] **Specific Catch Blocks** - Specific error types catch et
```typescript
// ✅ DOĞRU - Specific error handling
async function handleRequest(req: Request) {
  try {
    const user = await getUser(req.params.id);
    return response.json(user);
  } catch (error) {
    if (error instanceof NotFoundError) {
      return response.status(404).json({ success: false, error: { code: error.code } });
    } else if (error instanceof ValidationError) {
      return response.status(400).json({ success: false, error: { code: error.code } });
    } else {
      logger.error('Unexpected error', error);
      throw error; // Re-throw for global handler
    }
  }
}
```

- [ ] **Re-throw When Needed** - Error'ları swallow etme, re-throw et
```typescript
// ❌ YANLIŞ - Swallowing errors
try { await riskyOperation(); } catch (error) { /* Silent error! */ }
// ✅ DOĞRU - Preserving stack trace
try {
  const parsed = JSON.parse(data);
  return validate(parsed);
} catch (error) {
  logger.error('Failed to process data', { error, data });
  throw new ValidationError('data', 'Invalid JSON format', { cause: error });
}
```

- [ ] **Always Log Errors** - Her error log et

## 🟡 SHOULD
- [ ] **Global Error Handler** - Express/FastAPI için global error handler
```typescript
// ✅ DOĞRU - Global error handler
export function errorHandler(error: Error, req: Request, res: Response, next: NextFunction) {
  logger.error('Error occurred', { error: error.message, stack: error.stack, path: req.path });
  if (error instanceof AppError) return res.status(error.statusCode).json({ success: false, error: { code: error.code, message: error.message } });
  return res.status(500).json({ success: false, error: { code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' } });
}
```

- [ ] **Async Error Handler** - Async route handler'lar için wrapper
```typescript
// ✅ DOĞRU - Async error handler wrapper
export function asyncHandler(fn: (req: Request, res: Response, next: NextFunction) => Promise<any>) {
  return (req: Request, res: Response, next: NextFunction) => Promise.resolve(fn(req, res, next)).catch(next);
}
app.get('/users/:id', asyncHandler(async (req, res) => { const user = await getUser(req.params.id); res.json(user); }));
```

- [ ] **Circuit Breaker** - External API calls için circuit breaker

## ⛔ NEVER
- [ ] **Never Swallow Errors** - Errorları silent ignore etme
```typescript
// ❌ YANLIŞ - Swallowing errors
try { await riskyOperation(); } catch (error) { /* Do nothing */ }
// ✅ DOĞRU - Proper error handling
try { await riskyOperation(); } catch (error) {
  logger.error('Operation failed', error);
  throw new OperationFailedError('riskyOperation', error);
}
```

- [ ] **Never Use Empty Catch Blocks** - Catch block'ı boş bırakma
- [ ] **Never Throw in Finally** - Finally block'ta throw etme
- [ ] **Never Return Error Values** - Exceptions kullan, error codes döndürme

## 🔗 Referanslar
- [Error Handling Best Practices](https://joyent.com/node-js/production/design/errors)
- [Clean Code Error Handling](https://martinfowler.com/articles/replaceThrowWithNotification.html)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
