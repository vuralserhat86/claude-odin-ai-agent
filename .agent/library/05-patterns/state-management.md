# State Management

> v1.0.0 | 2026-01-09 | Redux, Zustand, Recoil

## 🔴 MUST
- [ ] **Single Source of Truth** - Her state tek bir source'dan gelmeli
```typescript
// ❌ YANLIŞ - State mutation
state.users.push({ id: 3, name: 'Bob' });
state.users[0].name = 'Johnny';

// ✅ DOĞRU - Immutable updates
const newState = { ...state, users: [...state.users, { id: 3, name: 'Bob' }] };

// Or with Immer
const newState = produce(state, draft => {
  draft.users.push({ id: 3, name: 'Bob' });
  draft.users[0].name = 'Johnny';
});
```

- [ ] **Immutable Updates** - State never mutate edilmeli
- [ ] **Normalized State** - Database gibi normalize state structure
```typescript
// ✅ DOĞRU - Normalized state structure
const normalizedState = {
  users: {
    byId: {
      'user1': { id: 'user1', name: 'John', email: 'john@example.com' },
      'user2': { id: 'user2', name: 'Jane', email: 'jane@example.com' }
    },
    allIds: ['user1', 'user2']
  },
  posts: {
    byId: {
      'post1': { id: 'post1', title: 'Hello', authorId: 'user1' }
    },
    allIds: ['post1']
  }
};
```

- [ ] **Separation of Concerns** - Local vs global state ayrımı

## 🟡 SHOULD
- [ ] **Local State First** - Component-local state için useState kullan
```typescript
// 1. Local state
function Counter() { const [count, setCount] = useState(0); return <button onClick={() => setCount(c => c + 1)}>{count}</button>; }
// 2. URL state
function ProductList() { const [searchParams] = useSearchParams(); const page = parseInt(searchParams.get('page') || '1'); }
// 3. Server state (React Query)
const { data: user } = useQuery({ queryKey: ['user', userId], queryFn: () => api.getUser(userId) });
// 4. Global state (Zustand)
const useAuthStore = create<AuthStore>((set) => ({ user: null, token: null, login: (user, token) => set({ user, token }), logout: () => set({ user: null, token: null }) }));
```

- [ ] **Server State** - Server data için React Query/SWR kullan
- [ ] **URL State** - Filter, sort, pagination için URL state kullan
- [ ] **Global State Sparingly** - Sadece gerçekten global state için Redux/Zustand kullan
- [ ] **Derived State** - useMemo ile derived state oluştur
```typescript
// ❌ YANLIŞ - Syncing state
const [items, setItems] = useState([]);
const [filteredItems, setFilteredItems] = useState([]);
useEffect(() => { setFilteredItems(items.filter(item => item.active)); }, [items]);
// ✅ DOĞRU - Derived state
const [items, setItems] = useState([]);
const filteredItems = useMemo(() => items.filter(item => item.active), [items]);
```

## ⛔ NEVER
- [ ] **Never Prop Drilling Deep** - Deep prop drilling yerine context/useRedux kullan
```typescript
// ❌ YANLIŞ - Deep prop drilling
function App() { const user = { name: 'John' }; return <Level1 user={user} />; }
function Level1({ user }) { return <Level2 user={user} />; }
function Level2({ user }) { return <Level3 user={user} />; }
function Level3({ user }) { return <div>{user.name}</div>; }
// ✅ DOĞRU - Context
const UserContext = createContext<User | null>(null);
function App() { return <UserContext.Provider value={user}><Level1 /></UserContext.Provider>; }
function Level3() { const user = useContext(UserContext); return <div>{user.name}</div>; }
```

- [ ] **Never Sync State** - Duplicate state'leri sync etme, single source of truth
- [ ] **Never Put Everything in Redux** - Local state için Redux'a ihtiyaç yok
- [ ] **Never Mutate State Directly** - Immer kullan veya manual spread

## 🔗 Referanslar
- [Redux Toolkit Documentation](https://redux-toolkit.js.org/)
- [Zustand Documentation](https://github.com/pmndrs/zustand)
- [React Query Documentation](https://tanstack.com/query/latest)
- [You Might Not Need Redux](https://davidwalsh.name/you-might-not-need-redux)
