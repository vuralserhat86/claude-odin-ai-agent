# Java

> v1.0.0 | 2026-01-09 | Java 21, Spring Boot 3

## 🔴 MUST
- [ ] **Naming Conventions** - camelCase methods, PascalCase classes
```java
@Service
@Transactional(readOnly = true)
public class UserService {
    private static final Logger log = LoggerFactory.getLogger(UserService.class);
    private final UserRepository userRepository;

    @Transactional
    public UserDTO createUser(CreateUserRequest request) {
        validateUserRequest(request);
        User user = User.builder()
            .id(UUID.randomUUID())
            .email(request.email().toLowerCase())
            .password(encodePassword(request.password()))
            .build();
        return userMapper.toDTO(userRepository.save(user));
    }

    public Optional<UserDTO> findById(UUID id) {
        return userRepository.findById(id).map(userMapper::toDTO);
    }
}
```
- [ ] **Exception Handling** - Custom exceptions + @ControllerAdvice
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(NotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(response);
    }
}
```

## 🟡 SHOULD
- [ ] **Constructor Injection** - Constructor injection over field
- [ ] **Configuration Properties** - @ConfigurationProperties with validation
- [ ] **DTOs** - Separate DTOs from entities (MapStruct)
- [ ] **Optional Returns** - Optional instead of null
```java
@ConfigurationProperties(prefix = "app")
@Validated
public record ApplicationProperties(
    @NotBlank String name,
    @Min(1024) @Max(65535) int port
) {}

@Entity
@Table(name = "users")
public class User {
    @Id private UUID id;
    @Column(unique = true) private String email;
}
```

## ⛔ NEVER
- [ ] **Null Returns** - Use Optional
- [ ] **Empty Catch** - Always handle exceptions
- [ ] **God Classes** - Single responsibility
- [ ] **Primitive Obsession** - Use value objects
```java
// ✅ DOĞRU - Value object
public record Email(String value) {
    public Email {
        requireNonNull(value);
        if (!isValid(value)) throw new IllegalArgumentException("Invalid");
    }
}
```

## 🔗 Referanslar
- [Java Code Conventions](https://oracle.com/technetwork/java/codeconventions-150003.pdf)
- [Spring Boot Best Practices](https://spring.io/guides)
- [Effective Java](https://www.oreilly.com/library/view/effective-java/9780134686097/)
