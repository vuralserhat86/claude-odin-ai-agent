# Fine-Tuning

> v1.0.0 | 2026-01-09

## 🔴 MUST
- [ ] **Quality Data** - High-quality, diverse training data collect et
```javascript
// ✅ DOĞRU - Quality training data
const trainingData = [
  {
    messages: [
      { role: "system", content: "You are a math tutor. Explain step-by-step." },
      { role: "user", content: "Solve 345 + 678 and explain." },
      { role: "assistant", content: "Step 1: Align numbers\n  345\n+ 678\n\nStep 2: Add columns\n- Ones: 5+8=13 (write 3, carry 1)\n- Tens: 4+7+1=12 (write 2, carry 1)\n- Hundreds: 3+6+1=10\n\nAnswer: 1023" }
    ]
  },
  {
    messages: [
      { role: "system", content: "You are an expert TypeScript developer." },
      { role: "user", content: "Write an email validation function." },
      { role: "assistant", content: "```typescript\ninterface ValidationResult {\n  isValid: boolean;\n  errors: string[];\n}\n\nfunction validateEmail(email: string): ValidationResult {\n  const errors = [];\n  const regex = /^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/;\n  if (!regex.test(email)) errors.push('Invalid format');\n  return { isValid: errors.length === 0, errors };\n}\n```" }
    ]
  }
];
```

- [ ] **Data Split** - Train/validation/test split (80/10/10)
- [ ] **JSONL Format** - Correct JSONL format kullan
- [ ] **Validation** - Data validation before training
```javascript
// ✅ DOĞRU - Validate JSONL format
function validateJSONL(filename) {
  const content = fs.readFileSync(filename, 'utf-8');
  const lines = content.trim().split('\n');

  for (let i = 0; i < lines.length; i++) {
    const item = JSON.parse(lines[i]);
    if (!item.messages || !Array.isArray(item.messages)) {
      throw new Error(`Line ${i + 1}: Missing messages array`);
    }
    if (item.messages[item.messages.length - 1].role !== 'assistant') {
      throw new Error(`Line ${i + 1}: Last message must be assistant`);
    }
  }

  console.log(`✅ Valid: ${lines.length} examples`);
  return true;
}
```

## 🟡 SHOULD
- [ ] **Hyperparameter Tuning** - Low learning rate, 2-4 epochs
```javascript
// ✅ DOĞRU - Fine-tuning configuration
async function fineTuneModel(trainingFileId) {
  const fineTune = await client.fineTuning.jobs.create({
    training_file: trainingFileId,
    model: 'gpt-4o-mini',
    hyperparameters: { n_epochs: 3, learning_rate_multiplier: 0.1, batch_size: 4 },
    suffix: 'custom-model-v1'
  });
  while (fineTune.status === 'pending' || fineTune.status === 'running') {
    await new Promise(r => setTimeout(r, 5000));
    const job = await client.fineTuning.jobs.retrieve(fineTune.id);
    if (job.status === 'succeeded') return job;
  }
}
```

- [ ] **Baseline Comparison** - Compare with base model
- [ ] **Test Set Evaluation** - Holdout test set for evaluation
- [ ] **Qualitative Review** - Manual review of outputs

## ⛔ NEVER
- [ ] **Never Fine-Tune for Facts** - Facts için RAG kullan
```javascript
// ❌ YANLIŞ - Fine-tuning for facts
const factualData = [{ messages: [{ role: 'user', content: 'What is the capital of France?' }, { role: 'assistant', content: 'Paris' }] }];
// ✅ DOĞRU - Fine-tuning for style
const styleData = [{ messages: [{ role: 'system', content: 'Explain medical concepts simply.' }, { role: 'user', content: 'What is hypertension?' }, { role: 'assistant', content: 'Think of blood vessels like pipes.' }] }];
```

- [ ] **Never Use Small Datasets** - Minimum 100+ examples
```javascript
// ❌ YANLIŞ - Too few examples
const smallDataset = [/* 10 examples */];
// ✅ DOĞRU - Sufficient data
const goodDataset = [/* 500-1000 diverse examples */];
// ❌ YANLIŞ - Overfitting
const hyperparameters = { n_epochs: 50 };
// ✅ DOĞRU - Appropriate epochs
const hyperparameters = { n_epochs: 3 };
```

- [ ] **Never Ignore Baseline** - Always compare with base model

## 🔗 Referanslar
- [OpenAI Fine-Tuning Guide](https://platform.openai.com/docs/guides/fine-tuning)
- [Fine-Tuning Best Practices](https://www.anthropic.com/index/fine-tuning)
- [HuggingFace PEFT](https://huggingface.co/docs/peft/)
