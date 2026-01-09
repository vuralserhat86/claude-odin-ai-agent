# CLI - Command Line Tools

> **v1.0.0** | **2026-01-09** | **Commander, Oclif, Yargs**

---

## 🔴 MUST

- [ ] **Help Flag** - `--help` mutlaka implement et
- [ ] **Exit Codes** - 0=success, non-zero=error
- [ ] **Stderr for Errors** - Hataları stderr'e yaz
- [ ] **Argument Parsing** - Parser library kullan

```typescript
// Commander.js CLI
#!/usr/bin/env node
import { Command } from 'commander';

const program = new Command();

program
  .name('mytool')
  .description('My awesome tool')
  .version('1.0.0')
  .argument('<input>', 'Input file')
  .option('-o, --output <path>', 'Output directory', './dist')
  .option('-w, --watch', 'Watch mode', false)
  .action((input, options) => {
    try {
      build(input, options);
    } catch (error) {
      console.error(`Error: ${error.message}`);
      process.exit(1);
    }
  });

program.parse();

// Exit codes
process.on('unhandledRejection', (err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
```

---

## 🟡 SHOULD

- [ ] **Subcommands** - Logical subcommands kullan
- [ ] **Colors** - Output için colors kullan
- [ ] **Progress** - Long task'lar için progress bar
- [ ] **Config File** - Config file desteği ekle

```typescript
// Subcommands
program
  .command('build')
  .description('Build project')
  .action(build);

program
  .command('test')
  .description('Run tests')
  .action(test);

// Progress bar
import cliProgress from 'cli-progress';
const bar = new cliProgress.SingleBar({}, cliProgress.Presets.shades_classic);
bar.start(100, 0);
for (let i = 0; i < 100; i++) {
  bar.update(i);
}
bar.stop();
```

---

## ⛔ NEVER

- [ ] **Never Silent Fail** - Hataları sessizce yutma
- [ ] **Never Hardcoded Paths** - Hardcoded path'ler yok
- [ ] **Never Pollute Globals** - Global namespace kirletme
- [ ] **Never Block Events** - Event loop'u bloke etme

```typescript
// ❌ YANLIŞ
try { doSomething(); } catch {} // Silent fail
const path = '/Users/myuser/config'; // Hardcoded
while (true) { /* heavy work */ } // Blocks

// ✅ DOĞRU
try {
  doSomething();
} catch (error) {
  console.error('Failed:', error);
  process.exit(1);
}
const path = process.env.HOME + '/config';
```

---

## 🔗 Referanslar

- [Commander.js](https://github.com/tj/commander.js)
- [CLI Guidelines](https://clig.dev/)
- [Oclif](https://oclif.io/)
- [Yargs](https://yargs.js.org/)
