---
title: Hybrid Search
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 18: Advanced RAG"
tags:
  - rag
  - hybrid-search
  - bm25
  - vector-search
  - retrieval
related:
  - "[[02 - Chunking Strategies]]"
  - "[[04 - Reranking]]"
---

# Hybrid Search

> [!NOTE]
> **TL;DR**
> Vector (semantic) search is great at *meaning* but bad at *exact terms* — it can miss a product code, an error string, a person's name, or a rare keyword because those don't embed distinctively. **Keyword search** (the classic **BM25** / sparse approach) is the opposite: precise on exact terms, blind to synonyms/meaning. **Hybrid search** runs both and **fuses** the results, getting the best of each. The standard fusion method is **Reciprocal Rank Fusion (RRF)**, which combines the two ranked lists by rank position (no need to reconcile incompatible score scales). Hybrid search is one of the highest-leverage RAG upgrades because it fixes the embarrassing "the answer literally contained the word and we still missed it" failures of pure vector search.

> [!NOTE]
> **Where this fits**
> Third note of **Section 18** — the retrieval-stage fix. It pairs naturally with [[04 - Reranking]] (hybrid widens the net; rerank tightens it).

---

## 1. Two kinds of search, opposite strengths

| | Vector (dense) search | Keyword (sparse / BM25) search |
|---|---|---|
| Matches on | **Meaning** (embeddings) | **Exact terms** (token overlap) |
| Great at | Synonyms, paraphrase, concepts | IDs, codes, names, rare words, jargon |
| Bad at | Exact strings it didn't embed distinctly | Synonyms, "different words same meaning" |
| Example win | "car" finds "automobile" | "ERR_4042" finds the exact log line |

```
query: "ERR_4042 on checkout"
vector search → maybe finds "payment errors" (vague, misses the code)
keyword search → finds the exact "ERR_4042" line  ✅
```

```
query: "how do I get my money back"
vector search → finds "refund policy"  ✅
keyword search → finds nothing (no shared words)
```

Neither alone is enough. **Hybrid = run both.**

---

## 2. BM25 — the keyword workhorse

**BM25** is the long-standing sparse retrieval algorithm (an improved TF-IDF). It scores documents by term frequency (how often query words appear) and inverse document frequency (rarer words count more), with length normalization. No embeddings, no GPU — fast and exact.

> [!IMPORTANT]
> **Sparse vs dense**
> "Sparse" (BM25) = a vector with one dimension per vocabulary word, mostly zeros — captures exact lexical overlap. "Dense" (embeddings) = a few hundred/thousand floats capturing meaning. They fail on opposite inputs, which is exactly why combining them works.

---

## 3. Fusing the results: Reciprocal Rank Fusion (RRF)

The problem: vector scores (cosine ~0–1) and BM25 scores (unbounded) aren't comparable, so you can't just add them. **RRF** sidesteps this by using **rank position**, not raw score:

```
RRF_score(doc) = Σ over each result list  1 / (k + rank_in_that_list)
```

- A document ranked highly in *either* list gets a strong combined score.
- `k` is a small constant (commonly ~60) that dampens the top ranks.
- Scale-free: no need to normalize incompatible score types.

```
vector list:  [docA, docC, docB]
keyword list: [docB, docA, docD]
RRF fuses by rank → docA (top-ish in both) wins; docB/docC strong; docD weak
```

Other fusion options exist (weighted score normalization), but RRF is the simple, robust default.

---

## 4. The hybrid pipeline

```
            ┌─► vector search ─► ranked list 1 ─┐
query ──────┤                                   ├─► RRF fuse ─► top-k ─► (rerank) ─► LLM
            └─► BM25 search ───► ranked list 2 ─┘
```

Often hybrid is the **wide net** (recall) and a **reranker** ([[04 - Reranking]]) then tightens it (precision) — they compose well.

---

## 5. How to get it

- **Vector DBs with built-in hybrid**: many (e.g. Qdrant, Weaviate, Elasticsearch/OpenSearch, pgvector + full-text) support sparse+dense and RRF natively — often the simplest route.
- **Framework retrievers**: LangChain/LlamaIndex offer ensemble/hybrid retrievers combining a BM25 retriever and a vector retriever.
- **Roll your own**: run BM25 (e.g. `rank_bm25`) + vector search separately, fuse with a small RRF function.

```python
# conceptual
vec_hits = vector_store.search(query, k=20)
kw_hits  = bm25.search(query, k=20)
fused    = reciprocal_rank_fusion([vec_hits, kw_hits], k=60)[:top_k]
```

---

## 6. When hybrid matters most

> [!TIP]
> **Reach for hybrid when exact terms appear in queries**
> Domains full of **identifiers** — code/error messages, legal citations, product SKUs, medical codes, names, acronyms — benefit hugely. For purely conceptual Q&A over prose, pure vector may suffice. Check RAGAS **Context Recall**: if it's low and you can see the answer contained literal query terms, hybrid is the fix.

---

## 7. Main takeaways

- **Vector search** = meaning; **keyword/BM25 search** = exact terms. Opposite strengths.
- Pure vector search **misses exact terms** (IDs, codes, names, rare words).
- **Hybrid search** runs both and **fuses** the results.
- **BM25** is the standard sparse algorithm (TF-IDF improved); fast, exact, no embeddings.
- **Reciprocal Rank Fusion (RRF)** combines lists by **rank**, dodging incompatible score scales.
- Many vector DBs / frameworks support hybrid + RRF **out of the box**.
- Highest value in **identifier-heavy** domains; verify with RAGAS Context Recall.
- Composes with **reranking** (hybrid = recall, rerank = precision).

---

## 8. Things I still want to figure out

- Best **weighting** of dense vs sparse when not using plain RRF?
- Does my vector DB (**Qdrant**) support native hybrid, and how?
- How does hybrid interact with **metadata filtering**?

---

## 9. Things to dig into

- **BM25** (`rank_bm25`) and Elastic/OpenSearch hybrid.
- **Qdrant / Weaviate** native hybrid + RRF docs.
- LangChain `EnsembleRetriever`.
- Next: [[04 - Reranking]].

---

## 10. Next up in this section

- [ ] [[04 - Reranking]] — re-score the fused candidates with a cross-encoder for precision.

---

## Related
- [[02 - Chunking Strategies]] — what gets indexed for both searches.
- [[04 - Reranking]] — tightens the hybrid candidate set.

## Sources
- [Reciprocal Rank Fusion (paper)](https://plg.uwaterloo.ca/~gvcormac/cormacksigir09-rrf.pdf)
- [Qdrant hybrid search](https://qdrant.tech/articles/hybrid-search/)
