# React - Modern Frontend

> **v1.0.0** | **2026-01-09** | **React 18, Next.js**

---

## 🔴 MUST

- [ ] **Functional Components** - Sadece functional components kullan
- [ ] **Props Destructuring** - Props her zaman destructure edilmeli
- [ ] **Single Responsibility** - Her component tek iş yapar
- [ ] **Stable Keys** - Key prop benzersiz ve stable olmalı

```typescript
// ✅ DOĞRU - Functional + destructuring
interface Props {
  name: string;
  age?: number;
}

function UserCard({ name, age = 0 }: Props) {
  return (
    <div>
      <h1>{name}</h1>
      <p>Age: {age}</p>
    </div>
  );
}

// Stable keys
{users.map(user => (
  <UserCard key={user.id} {...user} />
))}
```

---

## 🟡 SHOULD

- [ ] **Custom Hooks** - Logic'i custom hook'lara taşı
- [ ] **Composition** - Component composition kullan
- [ ] **Memo** - Expensive calculations için useMemo
- [ ] **Callback** - Function referansları için useCallback

```typescript
// Custom hook
function useUsers() {
  const [users, setUsers] = useState([]);

  useEffect(() => {
    fetchUsers().then(setUsers);
  }, []);

  return users;
}

// Memo
const sorted = useMemo(() =>
  users.sort((a, b) => a.name.localeCompare(b.name)),
  [users]
);

// Composition
function Layout({ header, sidebar, children }) {
  return (
    <>
      {header}
      <div className="content">
        {sidebar}
        {children}
      </div>
    </>
  );
}
```

---

## ⛔ NEVER

- [ ] **Never Class Components** - Class component kullanma
- [ ] **Never Nested Renders** - Nested component tanımları yok
- [ ] **Never Index Keys** - Index as key kullanma (dinamik listeler)
- [ ] **Never Direct Mutation** - State'i direkt mutate etme

```typescript
// ❌ YANLIŞ
class OldComponent extends Component { }
items.map((item, i) => <Item key={i} />)
user.name = 'New'; // Direct mutation

function Component() {
  function Nested() { } // Nested component

// ✅ DOĞRU
function Component() {
  const [user, setUser] = useState(null);
  const updateUser = (name) => setUser(u => ({ ...u, name }));

  return items.map(item => <Item key={item.id} />);
}
```

---

## 🔗 Referanslar

- [React Docs](https://react.dev)
- [Hooks Rules](https://react.dev/reference/rules)
- [React Patterns](https://reactpatterns.com/)
- [Next.js Docs](https://nextjs.org/docs)
