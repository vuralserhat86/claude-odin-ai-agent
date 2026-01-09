# Prompt Engineering

> v1.0.0 | 2026-01-09

## 🔴 MUST
- [ ] **Structured Prompt** - Role, Task, Context, Output Format, Constraints
```typescript
// ✅ DOĞRU - Structured prompt template
function buildPrompt(template: PromptTemplate): string {
  return `
You are an expert backend developer specializing in Node.js and TypeScript.

## Task
${template.task}

## Requirements
${template.requirements.map(r => `- ${r}`).join('\n')}

## Context
${Object.entries(template.context).map(([k, v]) => `- ${k}: ${JSON.stringify(v)}`).join('\n')}

## Output Format
${template.outputFormat}

## Constraints
${template.constraints.map(c => `- ${c}`).join('\n')}
`;
}
```

- [ ] **Clear Role Definition** - Expertise level ve domain belirt
- [ ] **Specific Task Description** - Task'i açıkça define et
- [ ] **Output Format Specification** - Expected output format belirle
```typescript
// ❌ YANLIŞ - Vague prompt
const prompt = "Write some code for a user login";

// ✅ DOĞRU - Specific prompt
const prompt = `
Role: Senior Backend Developer
Task: Write a user login API endpoint with JWT authentication
Requirements:
  - TypeScript with strict mode
  - JWT with access/refresh tokens
  - Input validation with Zod
  - Rate limiting
  - Bcrypt password hashing
`;
```

## 🟡 SHOULD
- [ ] **Few-Shot Learning** - 3-5 representative example sağla
```typescript
// ✅ DOĞRU - Few-shot learning
function createFewShotPrompt(): string {
  return `
You are an expert at writing SQL queries.

## Examples
Request: Get all users who registered in the last 7 days
\`\`\`sql
SELECT * FROM users WHERE created_at > NOW() - INTERVAL '7 days';
\`\`\`

Request: Find top 10 customers by total order amount
\`\`\`sql
SELECT c.id, c.name, SUM(o.total) as total FROM customers c JOIN orders o ON c.id = o.customer_id GROUP BY c.id ORDER BY total DESC LIMIT 10;
\`\`\`

## Your Task
Request: {{USER_REQUEST}}
SQL:
`;
}
```

- [ ] **Chain of Thought** - Step-by-step reasoning göster
- [ ] **Temperature Tuning** - Task'e uygun temperature seç
```typescript
const cotPrompt = `Solve step-by-step: 1. Understand Goal 2. Identify Key Information 3. Identify Constraints 4. Plan Approach 5. Execute 6. Verify 7. Final Answer. Problem: ${problem}`;
const TEMPERATURE = { codeGeneration: 0.1, creativeWriting: 0.9, dataExtraction: 0.0, brainstorming: 1.2, codeReview: 0.3 };
```

- [ ] **Self-Consistency** - Complex tasks için multiple solutions
- [ ] **Negative Examples** - What NOT to do göster

## ⛔ NEVER
- [ ] **Never Ambiguous Instructions** - Clear, specific instructions
```typescript
// ❌ YANLIŞ - Ambiguous
const badPrompt = "Write a function to handle users";
// ✅ DOĞRU - Specific
const goodPrompt = `Write a TypeScript function to validate user registration using Zod. Requirements: Validate email format, Password strength (min 8, 1 uppercase, 1 number, 1 special), Age between 18-120, Return detailed error messages`;
```

- [ ] **Never Overly Long Prompts** - Concise, focused prompts
- [ ] **Never Forget Context** - Provide necessary context
- [ ] **Never Ignore Output Format** - Specify expected format

## 🔗 Referanslar
- [OpenAI Prompt Engineering Guide](https://platform.openai.com/docs/guides/prompt-engineering)
- [Anthropic Prompt Library](https://docs.anthropic.com/claude/prompt-library)
- [Prompt Engineering Guide](https://www.promptingguide.ai/)
