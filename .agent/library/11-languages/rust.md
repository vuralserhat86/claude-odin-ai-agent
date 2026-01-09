# Rust - Systems Programming

> **v1.0.0** | **2026-01-09** | **Rust 1.75+, Cargo, Tokio**

---

## 🔴 MUST

- [ ] **Ownership Rules** - Ownership kurallarına uymak zorunlu
- [ ] **Borrow Checker** - Borrow checker kurallarını takip et
- [ ] **Error Handling** - `Result` ve `Option` kullan, `unwrap()` yok
- [ ] **Unsafe Bloklar** - Unsafe kodları minimize et

```rust
// ❌ YANLIŞ
fn get_user(id: u32) -> User {
    users.get(id).unwrap() // Panic risk!
}

// ✅ DOĞRU
fn get_user(id: u32) -> Result<User, Error> {
    users.get(id)
        .cloned()
        .ok_or_else(|| Error::NotFound(id))
}

// Borrowing
fn process(user: &User) -> String {
    format!("{} <{}>", user.name, user.email)
} // user hala sahibinde
```

---

## 🟡 SHOULD

- [ ] **Iterators** - Iterator methods kullan
- [ ] **Pattern Matching** - Match expressions kullan
- [ ] **Smart Pointers** - Rc, Arc, Box appropriately
- [ ] **Async/Await** - Tokio runtime kullan

```rust
// Iterator chain
let result: Vec<_> = users
    .iter()
    .filter(|u| u.is_active())
    .map(|u| u.name.clone())
    .collect();

// Pattern matching
match result {
    Ok(user) => println!("Found: {}", user.name),
    Err(Error::NotFound(id)) => eprintln!("User {} not found", id),
    Err(e) => eprintln!("Error: {}", e),
}

// Async with Tokio
async fn fetch_user(id: u32) -> Result<User> {
    Ok(db::find_user(id).await?)
}
```

---

## ⛔ NEVER

- [ ] **Never Unwrap** - Production kodda `unwrap()` kullanma
- [ ] **Never Panic** - Panic'den kaçın, handle error
- [ ] **Never Memory Leaks** - Rc ve RefCell döngülerinden kaçın
- [ ] **Never Raw Pointers** - Unsafe olmadan raw pointer kullanma

```rust
// ❌ YANLIŞ
let user = users.get(id).unwrap(); // Panic!
let count = Rc::new(RefCell::new(0)); // Leak risk

// ✅ DOĞRU
let user = users.get(id)?;
let count = Arc::new(AtomicUsize::new(0));
```

---

## 🔗 Referanslar

- [Rust Book](https://doc.rust-lang.org/book/)
- [Rust Guidelines](https://rust-lang.github.io/rust-guidelines/)
- [API Guidelines](https://rust-lang.github.io/api-guidelines/)
- [Tokio Docs](https://tokio.rs/docs/)
