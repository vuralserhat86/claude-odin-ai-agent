# Android - Kotlin Development

> **v1.0.0** | **2026-01-09** | **Kotlin 1.9, Jetpack Compose**

---

## 🔴 MUST

- [ ] **Jetpack Compose** - Modern UI için Compose kullan
- [ ] **Coroutines** - Async için coroutine kullan
- [ ] **MVVM** - UI ve business logic'i ayır
- [ ] **Hilt DI** - Dependency injection için Hilt

```kotlin
// Compose + MVVM + Coroutines
@Composable
fun UserList(viewModel: UserViewModel = viewModel()) {
    val users by viewModel.users.collectAsState()

    LazyColumn {
        items(users) { user ->
            Text(user.name)
        }
    }

    LaunchedEffect(Unit) {
        viewModel.loadUsers()
    }
}

@HiltViewModel
class UserViewModel @Inject constructor(
    private val repository: UserRepository
) : ViewModel() {
    private val _users = MutableStateFlow<List<User>>(emptyList())
    val users: StateFlow<List<User>> = _users.asStateFlow()

    fun loadUsers() {
        viewModelScope.launch {
            _users.value = repository.fetchUsers()
        }
    }
}
```

---

## 🟡 SHOULD

- [ ] **State Hoisting** - State'i yükselt
- [ ] **Room Database** - Local storage için Room
- [ ] **Retrofit** - Network için Retrofit kullan
- [ ] **Paging 3** - Pagination için Paging

```kotlin
// State hoisting
@Composable
fun UserInput(
    value: String,
    onValueChange: (String) -> Unit
) {
    TextField(value, onValueChange)
}

// Room + Retrofit
@Entity
data class User(@PrimaryKey val id: String, val name: String)

@Dao
interface UserDao {
    @Query("SELECT * FROM user")
    fun getAll(): Flow<List<User>>
}

interface ApiService {
    @GET("users")
    suspend fun getUsers(): List<User>
}
```

---

## ⛔ NEVER

- [ ] **Never Block Main** - Main thread'i bloke etme
- [ ] **Never Leak Context** - Context leak'lerinden kaçın
- [ ] **Never Hardcode Strings** - String resources kullan
- [ ] **Never Ignore Lifecycles** - Lifecycle aware ol

```kotlin
// ❌ YANLIŞ
Thread.sleep(1000) // Block main
context.startActivity(...) // Leak risk
text = "Hello" // Hardcoded

// ✅ DOĞRU
viewModelScope.launch { delay(1000) }
val intent = Intent(context, NextActivity::class.java)
text = getString(R.string.hello)
```

---

## 🔗 Referanslar

- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Kotlin Coroutines](https://kotlinlang.org/docs/coroutines-overview.html)
- [Android Architecture](https://developer.android.com/topic/architecture)
- [Material Design 3](https://m3.material.io/)
