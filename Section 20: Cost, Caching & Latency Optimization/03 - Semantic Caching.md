---
title: Semantic Caching
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 20: Cost, Caching & Latency Optimization"
tags:
  - cost
  - caching
  - semantic-cache
  - embeddings
  - optimization
related:
  - "[[02 - Prompt Caching]]"
  - "[[07 - Vector Embeddings]]"
---

# Semantic Caching

> [!NOTE]
> **TL;DR**
> Where prompt caching reuses prompt *prefixes*, **semantic caching** reuses whole **answers**. Many users ask the same thing in different words ("how do I reset my password?" vs "I forgot my password, what now?"). An **exact-match** cache misses these; a **semantic** cache catches them by **embedding the query** and checking if a *sufficiently similar* past query exists — if cosine similarity exceeds a threshold, return the cached answer and **skip the LLM call entirely** (zero tokens, ~instant). It's a vector-search cache (reuses §1/§8 embeddings + a vector store). The big risk is the **similarity threshold**: too loose → wrong cached answers served; too tight → few hits. Best for high-volume, repetitive, fairly **static** Q&A (FAQ, support); risky for personalized or time-sensitive answers.

> [!NOTE]
> **Where this fits**
> Third note of **Section 20**. It complements [[02 - Prompt Caching]] (prefix-level) with answer-level caching, built on the embeddings from [[07 - Vector Embeddings]].

---

## 1. Prompt cache vs semantic cache

| | Prompt caching | Semantic caching |
|---|---|---|
| Reuses | Processed prompt **prefix** | The whole **answer** |
| Match on | **Exact** token prefix | **Similar meaning** (embeddings) |
| Saves | Part of input cost + latency | The **entire** LLM call (all tokens) |
| Still calls LLM? | Yes (suffix) | **No** on a hit |
| Managed by | Provider | **You** (your cache + vector store) |

They stack: semantic cache catches repeats; prompt caching helps the calls that do run.

---

## 2. Why exact-match caching isn't enough

A naive cache keyed on the exact query string almost never hits in chat — humans phrase the same intent endlessly differently:

```
"how do I reset my password?"
"I forgot my password, what now?"
"can't log in, need a new password"
   → same intent, different strings → exact cache: 3 misses, 3 LLM calls
```

Semantic caching treats these as **the same question**.

---

## 3. How semantic caching works

```
incoming query
   │ embed it (§7)
   ▼
search cache (vector store) for nearest past query
   │
   ├─ similarity ≥ threshold ?  ── YES → return cached answer  (0 tokens, instant) ✅
   └────────────────────────── NO  → call LLM → store {query_embedding: answer} → return
```

It's literally a **vector search over past queries**, with the stored value being the previous answer. The same Qdrant/embedding stack from §8 powers it.

---

## 4. The threshold — the make-or-break knob

> [!WARNING]
> **The similarity threshold is a correctness risk, not just a tuning param**
> - **Too loose** (low threshold): different questions get treated as "similar" → users get **wrong cached answers**. This is worse than a cache miss — it's a silent correctness bug.
> - **Too tight** (high threshold): only near-identical phrasings hit → low hit rate, little savings.
>
> Tune it against real query pairs and **err on the strict side** — a missed cache costs tokens; a false hit costs trust.

```
"reset my password" vs "delete my account"  → semantically close-ish, but DIFFERENT intent
   loose threshold → serves password steps for an account-deletion request ❌
```

---

## 5. When to use it (and when not)

| Good fit | Bad fit |
|---|---|
| High-volume **FAQ / support** | **Personalized** answers (depend on user/account) |
| **Static** knowledge (docs, policies) | **Time-sensitive** answers (prices, status, "today") |
| Repetitive queries | Highly varied, long-tail queries |
| Read-heavy | Anything where staleness is dangerous |

> [!IMPORTANT]
> **Cache invalidation is the hard part**
> A cached answer is a snapshot. If the underlying knowledge changes (policy update, new price), the cache is now **wrong**. Need a TTL and/or invalidation strategy (clear on content update). And **never** cache answers that depend on the specific user, or one user's answer leaks to another (a privacy bug, §19) — scope or skip caching for personalized responses.

---

## 6. Tools & shape

```python
# conceptual semantic cache
def answer(query):
    qv = embed(query)
    hit = cache_store.search(qv, k=1)
    if hit and hit.score >= THRESHOLD:
        return hit.answer                       # cache hit: no LLM call
    resp = llm(query)                            # miss: real call
    cache_store.upsert(qv, {"answer": resp, "ts": now})   # store with TTL
    return resp
```

- **GPTCache** — a library purpose-built for semantic caching (pluggable embeddings + vector store + eviction).
- Or roll your own with the existing **Qdrant + embeddings** stack from §8.

---

## 7. Benefits when it hits

- **Cost**: a hit costs **~0 LLM tokens** (just an embedding + vector lookup) vs a full call — the biggest possible saving.
- **Latency**: milliseconds vs seconds — huge UX win.
- **Load**: fewer calls → less rate-limit pressure (§24).

---

## 8. Main takeaways

- **Semantic caching** reuses whole **answers** by matching **similar** queries (embeddings), not exact strings.
- A **hit skips the LLM entirely** → ~0 tokens, ~instant.
- It's a **vector search over past queries** (reuses §7/§8 stack; GPTCache helps).
- The **similarity threshold** is a correctness risk: loose → wrong answers; tight → few hits. Err strict.
- Great for **static, high-volume FAQ**; bad for **personalized / time-sensitive** answers.
- Mind **invalidation/TTL** (stale answers) and **never cache user-specific** answers across users (privacy, §19).

---

## 9. Things I still want to figure out

- How to pick/validate the **threshold** systematically (eval, §17)?
- Best **invalidation** strategy when source content updates?
- Hit rates achievable on real support traffic?

---

## 10. Things to dig into

- **GPTCache** library.
- Building it on **Qdrant** (§8) + embeddings (§7).
- Measuring cache **hit rate** + false-hit rate via eval.
- Next: [[04 - Latency and Streaming]].

---

## 11. Next up in this section

- [ ] [[04 - Latency and Streaming]] — making responses *feel* fast (and be faster).

---

## Related
- [[02 - Prompt Caching]] — prefix-level caching (stacks with this).
- [[07 - Vector Embeddings]] — the matching mechanism.

## Sources
- [GPTCache](https://github.com/zilliztech/GPTCache)
- [Qdrant](https://qdrant.tech/) (DIY backend)
