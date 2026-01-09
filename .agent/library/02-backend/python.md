# Python - Modern Backend Development

> v1.0.0 | 2026-01-09 | Python 3.12+

## 🔴 MUST
- [ ] **PEP 8** - Style guide'ına uymalı
```python
# ✅ DOĞRU - PEP 8 compliant
class UserProcessor:
    def process_data(self, data: dict) -> str:
        value = data['value']
        return value
```
- [ ] **Type Hints** - Python 3.5+ type hints
```python
def get_user(user_id: str) -> Optional[User]:
    result = db.execute(query, {"user_id": user_id})
    return User.from_row(result.fetchone()) if result else None
```
- [ ] **Docstrings** - Her function docstring
```python
def get_user(user_id: str) -> Optional[User]:
    """Fetch user by ID from database.

    Args:
        user_id: Unique user identifier

    Returns:
        User object if found, None otherwise
    """
```
- [ ] **Specific Exceptions** - Generic Exception avoid et
```python
try:
    with open(filename) as f:
        return process(f.read())
except FileNotFoundError as e:
    logger.error(f"File not found: {filename}")
    raise
```
- [ ] **Context Managers** - `with` statement kullan
- [ ] **Logging** - Print yerine logging module

## 🟡 SHOULD
- [ ] **Dataclasses** - Data containers
```python
@dataclass(frozen=True)
class User:
    id: str
    name: str
```
- [ ] **Enum Classes** - Fixed values için Enum
```python
class UserRole(Enum):
    ADMIN = "admin"
    USER = "user"
```
- [ ] **Async Programming** - I/O bound için asyncio
```python
async def fetch_user_data(user_id: str) -> dict:
    async with httpx.AsyncClient() as client:
        response = await client.get(f"/users/{user_id}")
        return response.json()
```
- [ ] **Poetry/uv** - Modern dependency management
- [ ] **Context Managers** - Custom @contextmanager

## ⛔ NEVER
- [ ] **Semicolons** - Python'da yok
- [ ] **Mix Tabs/Spaces** - 4 spaces consistent
- [ ] **Bare Except** - `except:` kullanma
```python
# ❌ Catches everything
except: pass
# ✅ Specific
except Exception as e: logger.error(f"Error: {e}")
```
- [ ] **Shadow Built-ins** - Built-in names kullanma
- [ ] **String Concatenation in Loop** - join kullan
```python
# ❌ O(n^2)
result = ""
for item in items: result += str(item)
# ✅
result = "".join(str(item) for item in items)
```
- [ ] **Global Variables** - Constants kullan

## 🔗 Referanslar
- [PEP 8 Style Guide](https://peps.python.org/pep-0008/)
- [Type Hints Documentation](https://docs.python.org/3/library/typing.html)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
