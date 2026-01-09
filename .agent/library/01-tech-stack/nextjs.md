# Next.js - Full-Stack React Framework Rules

> v1.0.0 | 2026-01-09 | Next.js 14+ (App Router)

## 🔴 MUST
- [ ] **Use App Router** - Pages router yerine App Router
```typescript
app/
├── layout.tsx          // Root layout
├── page.tsx            // Home page
├── about/
│   └── page.tsx        // /about route
├── blog/
│   ├── [slug]/
│   │   └── page.tsx    // /blog/[slug] dynamic route
└── api/
    └── users/
        └── route.ts    // API endpoint
```
- [ ] **Server Components Default** - Default olarak Server Component
```typescript
// ✅ Server Component (default)
export default async function BlogPage() {
  const posts = await fetchPosts(); // Direct DB call
  return <PostList posts={posts} />;
}
// ✅ Client Component (when needed)
'use client';
export default function InteractiveButton() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```
- [ ] **Server-Side Fetching** - async data fetching in Server Components
```typescript
export default async function Page() {
  const data = await fetch('https://api.example.com/data', {
    next: { revalidate: 60 } // ISR: 60 seconds
  }).then(r => r.json());
  return <div>{data.name}</div>;
}
```
- [ ] **Route Handlers** - route.ts ile API endpoint
```typescript
export async function GET(request: NextRequest) {
  const data = await fetchUsers();
  return NextResponse.json(data, { status: 200 });
}
```

## 🟡 SHOULD
- [ ] **Image Optimization** - next/image kullan, never plain <img>
```typescript
import Image from 'next/image';
<Image src="/hero.png" alt="Hero" width={800} height={600} priority />
```
- [ ] **Metadata API** - SEO için metadata kullan
```typescript
export const metadata: Metadata = {
  title: 'Product Page',
  description: 'Buy our amazing product',
  openGraph: { images: ['/product-og.jpg'] }
};
```
- [ ] **Server Actions** - Form submissions için Server Actions
```typescript
'use server';
export async function createPost(formData: FormData) {
  await db.posts.create({ title: formData.get('title') });
  revalidatePath('/blog'); // Cache invalidate
}
```
- [ ] **Loading States** - loading.tsx ile loading states
- [ ] **Error Handling** - error.tsx ile error handling

## ⛔ NEVER
- [ ] **Never Fetch in useEffect for Server Data** - Server Component kullan
```typescript
// ❌ Wrong
'use client';
export default function Page() {
  const [data, setData] = useState(null);
  useEffect(() => { fetch('/api/data').then(r => r.json()).then(setData); }, []);
}
// ✅ Right
export default async function Page() {
  const data = await fetch('/api/data').then(r => r.json());
  return <DataDisplay data={data} />;
}
```
- [ ] **Never Use Router.push for Navigation** - Link component kullan
```typescript
// ❌ Wrong
const router = useRouter();
return <button onClick={() => router.push('/about')}>About</button>;
// ✅ Right
import Link from 'next/link';
return <Link href="/about">About</Link>;
```
- [ ] **Never Import from pages** - Pages router ile App Router mixing yok
- [ ] **Never Use Absolute Imports** - @ alias kullan
```typescript
// ❌ Wrong
import Button from '../../../components/Button';
// ✅ Right
import Button from '@/components/Button';
```

## 🔗 Referanslar
- [Next.js Documentation](https://nextjs.org/docs)
- [App Router](https://nextjs.org/docs/app)
- [Server Actions](https://nextjs.org/docs/app/building-your-application/data-fetching/server-actions)
