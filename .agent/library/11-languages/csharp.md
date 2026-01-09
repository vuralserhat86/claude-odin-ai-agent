# C#

> v1.0.0 | 2026-01-09 | C# 12, .NET 8

## 🔴 MUST
- [ ] **Naming Conventions** - PascalCase public, camelCase parameters
```csharp
public class UserService : IUserService {
    private readonly IRepository<User> _userRepository;
    private const int MaxRetryAttempts = 3;

    public UserService(IRepository<User> userRepository) {
        _userRepository = userRepository ?? throw new ArgumentNullException(nameof(userRepository));
    }

    public async Task<User?> GetUserAsync(Guid userId) {
        return await _userRepository.GetByIdAsync(userId);
    }
}
```
- [ ] **Exception Handling** - Custom exceptions + global filter
```csharp
public class NotFoundException : Exception {
    public NotFoundException(string resource, object key)
        : base($"'{resource}' with key '{key}' not found") { }
}

public class GlobalExceptionHandler : IExceptionFilter {
    public void OnException(Exception ex, HttpContext context) {
        var (statusCode, code, message) = ex switch {
            NotFoundException => (404, "NOT_FOUND", ex.Message),
            _ => (500, "INTERNAL_ERROR", "Error")
        };
    }
}
```

## 🟡 SHOULD
- [ ] **Modern C# Features** - Pattern matching, records
```csharp
// Records for immutable data
public record UserRequest(string Name, string Email);

// Pattern matching
public string GetUserStatus(User? user) => user switch {
    { IsDeleted: true } => "Deleted",
    { IsActive: true } => "Active",
    null => "Not Found",
    _ => "Unknown"
};
```
- [ ] **Constructor Injection** - DI with constructor
- [ ] **Async/Await** - Async all the way
- [ ] **Nullable Reference Types** - Enable nullable
```csharp
#nullable enable
public User? FindUser(string id) => _repository.FindById(id);
```

## ⛔ NEVER
- [ ] **Async Void** - Use Task instead
```csharp
// ❌ Async void
public async void DoSomethingAsync() { }
// ✅ Return Task
public async Task DoSomethingAsync() { }
```
- [ ] **.Result/.Wait()** - Deadlock risk
```csharp
// ❌ Deadlock risk
var user = _userService.GetUserAsync(1).Result;
// ✅ Async all the way
var user = await _userService.GetUserAsync(1);
```
- [ ] **String Concatenation in Loops** - StringBuilder kullan
```csharp
var sb = new StringBuilder();
foreach (var user in users) {
    sb.Append(user.Name).Append(", ");
}
```
- [ ] **Dispose in Destructor** - IDisposable pattern

## 🔗 Referanslar
- [C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- [.NET Best Practices](https://learn.microsoft.com/en-us/dotnet/core/)
- [Modern C# Features](https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/whats-new/csharp-12)
