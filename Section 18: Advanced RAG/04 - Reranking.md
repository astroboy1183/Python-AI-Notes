---
title: Reranking
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 18: Advanced RAG"
tags:
  - rag
  - reranking
  - cross-encoder
  - retrieval
related:
  - "[[03 - Hybrid Search]]"
  - "[[05 - Query Transformation]]"
---

# Reranking

> [!NOTE]
> **TL;DR**
> Reranking is the **post-retrieval precision booster** — and usually the single biggest quality win on a naive pipeline. The problem: vector search uses a **bi-encoder** (query and document embedded *separately*, then compared by cosine) — fast enough to search millions, but it never lets the query and document "look at each other," so ranking is approximate. A **cross-encoder reranker** takes the (query, document) pair *together* through a model and outputs a precise relevance score — far more accurate, but too slow to run over the whole corpus. So the pattern is **two-stage retrieval**: a cheap retriever fetches a wide candidate set (say top-50), then the expensive reranker re-scores and keeps the best (say top-5) for the prompt. Result: cleaner context, higher faithfulness, fewer tokens wasted on noise.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 18** — the post-retrieval stage. It tightens the wide candidate set produced by [[03 - Hybrid Search]].

---

## 1. Why retrieval ranking is approximate

Vector search uses a **bi-encoder**:

```
query    ──► [encoder] ──► query vector   ┐
document ──► [encoder] ──► doc vector      ├─► cosine similarity = score
                                           ┘  (compared independently)
```

The query and document are embedded **separately**, ahead of time. That's what makes it fast (doc vectors are precomputed; search is just nearest-neighbor). But the model never sees the query and document **together**, so it can't reason about how well *this* document answers *this* query. The ranking is a good approximation — not the truth.

> [!IMPORTANT]
> **"Similar" ≠ "relevant" (again)**
> This is the concrete cause of the [[01 - Beyond Naive RAG]] complaint. Bi-encoder similarity is a coarse proxy; the most *useful* chunk for a query often isn't the most *similar* by cosine. Reranking is how that gets corrected.

---

## 2. Cross-encoders: accurate but slow

A **cross-encoder** feeds the query and document **together** into the model:

```
[query  +  document] ──► [cross-encoder] ──► relevance score (0–1)
        (joint input — full attention across both)
```

Because attention spans both texts, it judges relevance far more precisely. The cost: it must run **once per (query, document) pair** — no precomputation possible — so it can't scan a whole corpus.

| | Bi-encoder (retrieval) | Cross-encoder (rerank) |
|---|---|---|
| Input | query & doc separate | query & doc together |
| Speed | very fast (precomputed) | slow (per pair) |
| Accuracy | approximate | high |
| Scale | millions of docs | tens of candidates |

---

## 3. The two-stage pattern

Use each where it's strong:

```
millions of docs
      │  STAGE 1 — fast bi-encoder (vector / hybrid)
      ▼
   top-50 candidates  (high recall, noisy)
      │  STAGE 2 — slow cross-encoder reranker
      ▼
   top-5 (high precision) ──► prompt ──► LLM
```

- **Stage 1 (retrieve):** cast a wide net cheaply — optimize for **recall** (don't miss the right doc).
- **Stage 2 (rerank):** re-score the small candidate set precisely — optimize for **precision** (surface the best few).

This is why hybrid search ([[03 - Hybrid Search]]) and reranking pair so well: hybrid maximizes what enters the candidate set; reranking picks the winners.

---

## 4. Using a reranker (shape)

```python
# conceptual — cross-encoder reranker
candidates = retriever.search(query, k=50)          # stage 1: wide net
scored = reranker.rank(query, [c.text for c in candidates])  # stage 2
top = sorted(scored, key=lambda x: x.score, reverse=True)[:5]
context = "\n\n".join(t.text for t in top)
```

Options:
- **Hosted rerankers**: Cohere Rerank, Jina, Voyage — an API call, no model to host.
- **Open-source cross-encoders**: e.g. `bge-reranker`, `mxbai-rerank`, MS-MARCO cross-encoders via `sentence-transformers`.
- **Framework integrations**: LangChain/LlamaIndex have reranker wrappers (incl. `ContextualCompressionRetriever`).

---

## 5. Benefits beyond accuracy

- **Faithfulness ↑** — less irrelevant context means fewer distractions for the LLM to misuse (RAGAS Faithfulness, §17).
- **Fewer tokens** — sending top-5 reranked beats top-20 raw → cheaper + faster generation (ties to §20).
- **Smaller, sharper prompts** — reranking lets you retrieve wide but **send narrow**.

> [!TIP]
> **Retrieve wide, rerank, send narrow**
> A great default: retrieve ~30–50 candidates, rerank, send only the top 3–5 to the LLM. You get high recall (wide net) and high precision (rerank) without bloating the prompt.

---

## 6. Costs and trade-offs

| Trade-off | Note |
|---|---|
| **Latency** | Adds a rerank step (per-pair scoring) — usually tens–hundreds of ms |
| **Cost** | Hosted rerankers charge per query/doc; OSS needs compute |
| **Complexity** | One more component to host/monitor |

Almost always worth it for quality — but measure the latency budget (§20/§24).

---

## 7. Main takeaways

- Vector search uses a **bi-encoder** (separate embeddings) — fast but **approximate** ranking.
- A **cross-encoder reranker** scores (query, doc) **together** — accurate but **slow**.
- **Two-stage retrieval**: cheap retriever for **recall** → reranker for **precision**.
- Pattern: retrieve **wide** (top-50) → rerank → send **narrow** (top-5).
- Reranking is often the **single biggest quality win** on naive RAG.
- Bonus: higher **faithfulness**, **fewer tokens**, sharper prompts.
- Options: hosted (Cohere/Jina/Voyage) or OSS cross-encoders (`bge-reranker`).
- Costs: extra **latency + compute** — measure against the budget.

---

## 8. Things I still want to figure out

- Ideal **candidate count** (top-k into the reranker) vs latency?
- Hosted vs self-hosted reranker **cost/latency** in practice?
- Do rerankers help even **without** hybrid search?

---

## 9. Things to dig into

- **Cohere Rerank**, **Jina Reranker**, **Voyage rerank** APIs.
- `sentence-transformers` **cross-encoders**; **bge-reranker**.
- LangChain `ContextualCompressionRetriever`.
- Next: [[05 - Query Transformation]].

---

## 10. Next up in this section

- [ ] [[05 - Query Transformation]] — fix the query *before* retrieval (rewriting, multi-query, HyDE).

---

## Related
- [[03 - Hybrid Search]] — produces the candidate set reranking refines.
- [[01 - Beyond Naive RAG]] — "similar ≠ relevant," which reranking fixes.

## Sources
- [Sentence-Transformers cross-encoders](https://www.sbert.net/examples/applications/cross-encoder/README.html)
- [Cohere Rerank](https://docs.cohere.com/docs/rerank-overview)
