# LLM Best Practices

> **v1.0.0** | **2026-01-09** | **OpenAI, Anthropic, GLM**

---

## 🔴 MUST

- [ ] **Clear Prompts** - Açık, spesifik prompt'lar
- [ ] **Token Management** - Token kullanımını izle
- [ ] **Error Handling** - Rate limit ve error handling
- [ ] **Cost Control** - Harcama limiti belirle

```typescript
// Structured prompt + error handling
class LLMService {
  async generate(requirements: string): Promise<string> {
    const prompt = `
Role: Expert TypeScript developer
Task: Generate code for: ${requirements}

Requirements:
- TypeScript 5.3+
- Async/await patterns
- Error handling with try/catch
- JSDoc comments

Return only code, no explanations.
`.trim();

    try {
      const response = await this.openai.chat.completions.create({
        model: 'gpt-4',
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.3,
        max_tokens: 2000
      });

      return response.choices[0].message.content;
    } catch (error) {
      if (error.status === 429) {
        await this.backoff();
        return this.generate(requirements);
      }
      throw error;
    }
  }
}
```

---

## 🟡 SHOULD

- [ ] **System Prompts** - System prompt kullan
- [ ] **Few-Shot Examples** - Örneklerle guide et
- [ ] **Temperature** - Task'a göre temperature ayarla
- [ ] **Streaming** - Uzun çıktı için streaming kullan

```typescript
// System prompt + few-shot
const messages = [
  {
    role: 'system',
    content: 'You are a senior developer. Output clean TypeScript code.'
  },
  {
    role: 'user',
    content: 'Create a User class'
  },
  {
    role: 'assistant',
    content: 'class User { constructor(public id: string) {} }'
  },
  {
    role: 'user',
    content: requirements
  }
];

// Streaming
const stream = await openai.chat.completions.create({
  model: 'gpt-4',
  messages,
  stream: true
});

for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0].delta.content);
}
```

---

## ⛔ NEVER

- [ ] **Never Prompt Injection** - Kullanıcı girdisini validate et
- [ ] **Never Hardcoded API Keys** - API key'leri environment'dan al
- [ ] **Never Ignore Rate Limits** - Rate limitleri takip et
- [ ] **Never Send Secrets** - Secret'leri prompt'a ekleme

```typescript
// ❌ YANLIŞ
const apiKey = 'sk-...'; // Hardcoded
const prompt = userMessage; // No validation
await openai.create({ messages: [{ role: 'user', content: prompt }] });

// ✅ DOĞRU
const apiKey = process.env.OPENAI_API_KEY;
if (userMessage.length > 1000) throw new Error('Too long');
const sanitized = sanitize(userMessage);
```

---

## 🔗 Referanslar

- [OpenAI Cookbook](https://github.com/openai/openai-cookbook)
- [Anthropic Prompt Guide](https://docs.anthropic.com/claude/docs/prompt-engineering)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
- [LLM Security](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
