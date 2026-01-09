# Go - Google's Language

> **v1.0.0** | **2026-01-09** | **Go 1.21+**

---

## 🔴 MUST

- [ ] **Error Handling** - Her zaman error kontrol et
- [ ] **Gofmt** - gofmt ile format kullan
- [ ] **Interface Design** - Küçük, odaklı interface'ler
- [ ] **Context** - Context için context.Context kullan

```go
// ✅ DOĞRU - Error handling
func (s *UserService) GetUser(ctx context.Context, id string) (*User, error) {
    if id == "" {
        return nil, ErrInvalidID
    }

    user, err := s.db.GetUser(ctx, id)
    if err != nil {
        if errors.Is(err, sql.ErrNoRows) {
            return nil, ErrUserNotFound
        }
        return nil, fmt.Errorf("get user: %w", err)
    }

    return user, nil
}

// Context propagation
func main() {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
    defer cancel()
    // Use ctx in calls
}
```

---

## 🟡 SHOULD

- [ ] **Goroutines** - Goroutine leak'lerden kaçın
- [ ] **Channels** - Buffered channels appropriately
- [ ] **Struct Embedding** - Composition için embedding kullan
- [ ] **Defer** - Cleanup için defer kullan

```go
// Goroutine with wait group
func ProcessItems(items []Item) {
    var wg sync.WaitGroup
    for _, item := range items {
        wg.Add(1)
        go func(i Item) {
            defer wg.Done()
            process(i)
        }(item)
    }
    wg.Wait()
}

// Struct embedding
type BaseService struct {
    db *Database
}

type UserService struct {
    BaseService
    cache *Cache
}
```

---

## ⛔ NEVER

- [ ] **Never Ignore Errors** - Errorleri asla ignore etme
- [ ] **Never Panic** - Production'da panic kullanma
- [ ] **Never Goroutine Leak** - Goroutine leak'lerden kaçın
- [ ] **Never Global State** - Global değişkenlerden kaçın

```go
// ❌ YANLIŞ
user, _ := db.GetUser(id) // Error ignored!
panic("failed") // Panic in production

// ✅ DOĞRU
user, err := db.GetUser(id)
if err != nil {
    return err
}
```

---

## 🔗 Referanslar

- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review](https://github.com/golang/go/wiki/CodeReviewComments)
- [Go Blog](https://go.dev/blog/)
- [Standard Library](https://pkg.go.dev/std)
