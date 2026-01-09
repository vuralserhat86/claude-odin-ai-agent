# iOS - Swift Development

> **v1.0.0** | **2026-01-09** | **Swift 5.9, SwiftUI, UIKit**

---

## 🔴 MUST

- [ ] **SwiftUI First** - Yeni UI için SwiftUI kullan
- [ ] **Async/Await** - Modern concurrency kullan
- [ ] **Error Handling** - do-catch blokları kullan
- [ ] **Optionals** - Safe unwrap opsiyonelleri

```swift
// SwiftUI + async/await
struct UserListView: View {
    @State private var users: [User] = []

    var body: some View {
        List(users) { user in
            Text(user.name)
        }
        .task {
            await loadUsers()
        }
    }

    private func loadUsers() async {
        do {
            users = try await UserService.fetchUsers()
        } catch {
            handleError(error)
        }
    }
}

// Safe optional handling
guard let url = URL(string: urlString) else {
    return
}
```

---

## 🟡 SHOULD

- [ ] **Combine** - Reactive programming için Combine
- [ ] **MVVM** - MVVM pattern kullan
- [ ] **Codable** - JSON için Codable kullan
- [ ] **Dependency Injection** - DI pattern kullan

```swift
// Combine publisher
class ViewModel: ObservableObject {
    @Published var users: [User] = []

    func fetchUsers() {
        UserService.fetchUsers()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                // Handle completion
            } receiveValue: { [weak self] users in
                self?.users = users
            }
            .store(in: &cancellables)
    }
}

// Codable
struct User: Codable {
    let id: String
    let name: String
}
```

---

## ⛔ NEVER

- [ ] **Never Force Unwrap** - Production'da force unwrap yok
- [ ] **Never Force Cast** - Force cast'ten kaçın
- [ ] **Never Block Main** - Main thread'i bloke etme
- [ ] **Never Ignore Memory** - Memory leak'lerden kaçın

```swift
// ❌ YANLIŞ
let url = URL(string: "https://example.com")! // Force unwrap
let view = sender as! UIButton // Force cast
Thread.sleep(forTimeInterval: 1) // Block main

// ✅ DOĞRU
guard let url = URL(string: "https://example.com") else { return }
if let button = sender as? UIButton {
    // Use button
}
await Task.sleep(nanoseconds: 1_000_000_000)
```

---

## 🔗 Referanslar

- [SwiftUI Docs](https://developer.apple.com/documentation/swiftui)
- [Swift API Design](https://www.swift.org/documentation/api-design-guidelines)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Swift Evolution](https://github.com/apple/swift-evolution)
