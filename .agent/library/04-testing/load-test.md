# Load Testing

> v1.0.0 | 2026-01-09 | k6, Artillery, Gatling

## 🔴 MUST
- [ ] **Baseline Performance** - Normal load altında baseline ölç
```javascript
import http from 'k6/http';
export let options = {
  stages: [
    { duration: '2m', target: 10 },   // Ramp up
    { duration: '5m', target: 50 },   // Normal load
    { duration: '2m', target: 100 },  // Peak
    { duration: '2m', target: 0 },    // Ramp down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<500', 'p(99)<1000'],
    'http_req_failed': ['rate<0.01'],
  },
};
export default function () {
  const res = http.get('https://api.example.com/products');
  check(res, { 'status 200': (r) => r.status === 200 });
  sleep(Math.random() * 2 + 1);
}
```
- [ ] **Realistic User Behavior** - Think time ve mixed scenarios
```javascript
export default function () {
  http.get('https://shop.example.com/');
  sleep(Math.random() * 3 + 2); // Think time
  http.get(`https://shop.example.com/search?q=laptop`);
}
```
- [ ] **Metrics Collection** - p50, p95, p99 track et
```javascript
import { Trend } from 'k6/metrics';
const searchTime = new Trend('search_duration');
searchTime.add(res.timings.duration);
```

## 🟡 SHOULD
- [ ] **Parameterized Data** - Unique test data kullan
```javascript
import { SharedArray } from 'k6/data';
const products = new SharedArray('products', () => JSON.parse(open('./products.json')));
const product = products[__VU % products.length];
```
- [ ] **Artillery Config** - YAML config scenarios
```yaml
config:
  target: "https://api.example.com"
  phases:
    - duration: 300
      arrivalRate: 50
scenarios:
  - name: "Browse"
    flow:
      - get:
          url: "/products"
```

## ⛔ NEVER
- [ ] **Load Test Production** - Only test environments
- [ ] **Ignore Think Time** - Realistic pauses şart
```javascript
// ❌ No think time
http.get('/products');
// ✅ With think time
http.get('/products');
sleep(Math.random() * 3 + 2);
```
- [ ] **Same Data Repeatedly** - Varied requests ile cache bypass

## 🔗 Referanslar
- [k6 Documentation](https://k6.io/docs/)
- [k6 Examples](https://k6.io/docs/examples/)
- [Artillery Documentation](https://artillery.io/docs/)
