# RAG - Retrieval Augmented Generation

> **v1.0.0** | **2026-01-09** | **LangChain, Vector DBs, LLMs**

---

## 🔴 MUST

- [ ] **Smart Chunking** - Belgeyi mantıklı parçalara böl
- [ ] **Quality Embeddings** - Kaliteli embedding model kullan
- [ ] **Vector Database** - Embedding'leri verimli sakla
- [ ] **Relevance Ranking** - Sonuçları alaka göre sırala

```typescript
// RAG pipeline
class RAGService {
  async query(question: string, topK: number = 5): Promise<string> {
    // 1. Soruyu embed et
    const queryEmbedding = await this.embed(question);

    // 2. İlgili chunk'ları getir
    const chunks = await this.vectorStore.search(queryEmbedding, topK);

    // 3. Context oluştur
    const context = chunks.map(c => c.text).join('\n\n');

    // 4. Context ile cevap üret
    const prompt = `Context:\n${context}\n\nQuestion: ${question}`;
    return this.llm.generate(prompt);
  }

  // Smart chunking
  chunkDocument(text: string, maxSize: number = 500): string[] {
    return text.split(/\n\n+/)
      .reduce((acc: string[], para) => {
        if (acc.length === 0 || acc[acc.length - 1].length + para.length > maxSize) {
          acc.push(para);
        } else {
          acc[acc.length - 1] += '\n\n' + para;
        }
        return acc;
      }, []);
  }
}
```

---

## 🟡 SHOULD

- [ ] **Hybrid Search** - Vector + keyword search
- [ ] **Reranking** - İkinci katman reranking
- [ ] **Context Window** - Context length'i optimize et
- [ ] **Citations** - Kaynak göster

```typescript
// Hybrid search
async hybridSearch(query: string, alpha: number = 0.5) {
  const [vectorResults, keywordResults] = await Promise.all([
    this.vectorSearch(query),
    this.keywordSearch(query)
  ]);

  // Skorları birleştir
  return this.mergeScores(vectorResults, keywordResults, alpha);
}

// Reranking
async rerank(query: string, results: Document[]): Promise<Document[]> {
  const reranked = await this.reranker.rerank(query, results);
  return reranked.slice(0, 10);
}
```

---

## ⛔ NEVER

- [ ] **Never Skip Chunking** - Chunking'siz RAG yok
- [ ] **Never Ignore Relevance** - Alaka skorunu önemse
- [ ] **Never Overload Context** - Context window'u şişirme
- [ ] **Never Stale Data** - Eski embedding'leri temizle

```typescript
// ❌ YANLIŞ
const chunks = text.split('.'); // Naive chunking
const allDocs = await db.getAll(); // Tüm veriyi çek

// ✅ DOĞRU
const chunks = chunkDocument(text, 500);
const relevant = await vectorStore.search(embedding, 5);
```

---

## 🔗 Referanslar

- [LangChain RAG](https://python.langchain.com/docs/use_cases/question_answering/)
- [Vector DB Guide](https://www.anthropic.com/index/vector-databases)
- [RAG Patterns](https://github.com/pinecone-io/pinecone-tutorials)
- [Chunking Strategies](https://www.llamaindex.ai/blog/chunking-strategies)
