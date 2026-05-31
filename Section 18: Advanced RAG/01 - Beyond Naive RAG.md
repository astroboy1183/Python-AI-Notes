---
title: Beyond Naive RAG
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 18: Advanced RAG"
tags:
  - rag
  - retrieval
  - advanced-rag
  - foundations
related:
  - "[[03 - What is RAG and the Naive Approach]]"
  - "[[02 - Chunking Strategies]]"
  - "[[04 - Evaluating RAG with RAGAS]]"
---

# Beyond Naive RAG

> [!NOTE]
> **TL;DR**
> The RAG built in §8 is **"naive RAG"**: chunk documents → embed → store → on a query, embed it, pull top-k by cosine similarity, stuff into the prompt. It works for demos but hits real limits — **bad chunking** loses context, **pure vector search** misses exact keywords/IDs, **single-shot retrieval** can't handle vague or multi-part questions, and **top-k by similarity** drags in near-duplicates and noise. Advanced RAG fixes each stage: smarter **chunking** (note 02), **hybrid search** (vector + keyword, note 03), **reranking** (note 04), **query transformation** (note 05), and **structural retrieval patterns** + agentic RAG (note 06). The mental model: naive RAG is a single dumb lookup; advanced RAG is a **retrieval pipeline** with pre-processing, multiple retrievers, and post-processing — and (from §17) it's all **measurable** with RAGAS.

> [!NOTE]
> **Where this fits**
> First note of **Section 18: Advanced RAG** — the gap-fill upgrade to the naive pipeline from [[03 - What is RAG and the Naive Approach]]. It frames the limits; notes 02–06 fix them one stage at a time.

---

## 1. Recap: the naive RAG pipeline

```
INDEX:  docs → chunk → embed → store in vector DB
QUERY:  question → embed → top-k similarity search → stuff into prompt → LLM answers
```

Simple, and a great starting point. But each arrow hides a weakness.

---

## 2. Where naive RAG breaks

| Weakness | Why it hurts |
|---|---|
| **Fixed-size chunking** | Splits mid-thought; a chunk may lack the context to be meaningful |
| **Pure vector search** | Misses exact matches — product codes, names, error strings, rare keywords |
| **Single-shot retrieval** | A vague/multi-part question maps to a bad query embedding |
| **Top-k by similarity** | Returns near-duplicates and "similar but irrelevant" noise |
| **No relevance filter** | The LLM gets whatever was top-k, junk included → hurts faithfulness |
| **Embedding ≠ relevance** | Cosine similarity is a proxy; the *most similar* chunk isn't always the *most useful* |

> [!WARNING]
> **"Similar" is not "relevant"**
> Vector search optimizes for embedding similarity, which only approximates true relevance. A chunk can be semantically near the query yet useless for answering it — and the genuinely useful chunk can rank low. This gap is why reranking ([[04 - Reranking]]) exists.

---

## 3. The advanced RAG mental model

Naive RAG is one lookup. Advanced RAG is a **pipeline** with three phases around the retriever:

```
              ┌──────────── PRE-RETRIEVAL ────────────┐
query ──►  rewrite / expand / decompose / route
              └───────────────────┬───────────────────┘
                                  ▼
              ┌──────────────── RETRIEVAL ───────────────┐
        vector search  +  keyword (BM25)  =  hybrid
              └───────────────────┬───────────────────────┘
                                  ▼
              ┌──────────── POST-RETRIEVAL ───────────┐
           rerank  →  filter  →  compress / dedupe
              └───────────────────┬───────────────────┘
                                  ▼
                          context → LLM → answer
```

Each phase has its own techniques — the rest of the section walks them.

---

## 4. The roadmap (what fixes what)

| Stage | Technique | Note | Fixes |
|---|---|---|---|
| Indexing | Better **chunking** | [[02 - Chunking Strategies]] | mid-thought splits, lost context |
| Retrieval | **Hybrid search** | [[03 - Hybrid Search]] | missed keywords/IDs |
| Post-retrieval | **Reranking** | [[04 - Reranking]] | similar-but-irrelevant noise |
| Pre-retrieval | **Query transformation** | [[05 - Query Transformation]] | vague / multi-part questions |
| Structure | **Retrieval patterns + agentic RAG** | [[06 - Advanced Retrieval Patterns]] | small-chunk vs full-context, multi-hop |

> [!TIP]
> **Don't add everything at once**
> Each technique adds latency and complexity. Use **RAGAS** (§17) to find the actual bottleneck — low context recall? add hybrid + better chunking. Low precision? add reranking. Measure, then add the one technique that moves the metric.

---

## 5. The biggest levers (if I only do a few)

In rough order of bang-for-buck on a typical naive pipeline:

1. **Reranking** — usually the single largest quality jump for least effort.
2. **Hybrid search** — fixes the embarrassing "didn't find the obvious keyword" misses.
3. **Better chunking** — cheap at index time, compounds everything downstream.
4. **Query rewriting** — big help for conversational / vague queries.

---

## 6. Main takeaways

- §8's RAG is **naive RAG**: chunk → embed → top-k → stuff → answer.
- It breaks on **chunking, keyword misses, vague queries, and noisy top-k**.
- **Similar ≠ relevant** — embedding similarity is only a proxy.
- Advanced RAG = a **pipeline**: pre-retrieval, retrieval, post-retrieval.
- Roadmap: chunking → hybrid search → reranking → query transformation → structural patterns.
- **Measure first (RAGAS)**, then add the technique that fixes the actual bottleneck.
- Highest leverage: **reranking**, then **hybrid search**.

---

## 7. Things I still want to figure out

- How much latency does each stage realistically add?
- When does advanced RAG lose to just using a **bigger context window**?
- How to keep the pipeline **maintainable** as stages stack up?

---

## 8. Things to dig into

- **RAG survey papers** (retrieve-and-generate taxonomies).
- LangChain / LlamaIndex advanced retrieval modules.
- Cross-link: measure everything with [[04 - Evaluating RAG with RAGAS]].

---

## 9. Next up in this section

- [ ] [[02 - Chunking Strategies]] — get the index right before anything else.

---

## Related
- [[03 - What is RAG and the Naive Approach]] — the baseline being upgraded.
- [[04 - Evaluating RAG with RAGAS]] — how to know which fix to apply.

## Sources
- [LangChain retrieval docs](https://python.langchain.com/docs/concepts/retrieval/)
- [LlamaIndex advanced retrieval](https://docs.llamaindex.ai/)
