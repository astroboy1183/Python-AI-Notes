---
title: Prompt Caching
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 20: Cost, Caching & Latency Optimization"
tags:
  - cost
  - caching
  - prompt-caching
  - latency
  - optimization
related:
  - "[[01 - Understanding LLM Cost and Tokens]]"
  - "[[03 - Semantic Caching]]"
---

# Prompt Caching

> [!NOTE]
> **TL;DR**
> **Prompt caching** lets the provider reuse the computation for a **repeated prefix** of the prompt, so you don't pay full price (in tokens *and* latency) to re-process the same system prompt, instructions, few-shot examples, or long document on every call. The model caches the processed prefix; subsequent calls that share that exact prefix hit the cache → **cached input tokens are much cheaper** (often a large discount) and **faster** (no recompute). The golden rule: **put the stable content first, the variable content last** — caching matches on an exact prefix, so anything that changes early invalidates the cache. It's nearly free money for apps with big static system prompts, long shared context, or many-shot examples. Caches have a **short TTL**, so the savings come from request bursts, not one-offs.

> [!NOTE]
> **Where this fits**
> Second note of **Section 20**. It attacks the "system prompt / context repeated every call" cost driver from [[01 - Understanding LLM Cost and Tokens]]. Distinct from [[03 - Semantic Caching]] (which caches whole answers).

---

## 1. The waste it removes

Every call re-sends — and the model re-processes — the same leading content:

```
call 1: [big system prompt][few-shot examples][user Q1]
call 2: [big system prompt][few-shot examples][user Q2]   ← prefix reprocessed again
call 3: [big system prompt][few-shot examples][user Q3]   ← and again...
```

The prefix is identical, yet you pay input tokens + latency to process it every time. Prompt caching makes the provider **remember the processed prefix**.

---

## 2. How it works

```
first call:  process [prefix] (full price) → CACHE the processed prefix → process [suffix]
later calls: REUSE cached [prefix] (cheap/fast) → only process the new [suffix]
```

- **Cost**: cached prefix tokens are billed at a steep discount (sometimes a small fraction of normal input price; some providers also add a small write cost on the first call).
- **Latency**: the cached prefix isn't recomputed → noticeably faster time-to-first-token for long prompts.
- **Matching**: on an **exact** prefix match (same tokens, same order, usually above a minimum length).

> [!IMPORTANT]
> **Order matters: stable first, variable last**
> Caching keys on the **prefix**. If anything that changes per request (the user's question, a timestamp, retrieved chunks that differ each time) appears **early**, it breaks the match and nothing caches. Structure prompts as:
> ```
> [STABLE: system prompt, instructions, few-shot, long doc]   ← cacheable prefix
> [VARIABLE: this request's question / dynamic context]       ← put last
> ```

---

## 3. Two flavors

| Type | Who manages it | Notes |
|---|---|---|
| **Automatic** | The provider | Caching kicks in transparently when a long enough prefix repeats (common on OpenAI-style APIs) |
| **Explicit** | You mark cache breakpoints | Some APIs (e.g. Anthropic) let you tag which prefix segments to cache with cache-control markers |

Either way the design principle is the same: maximize the **shared, stable prefix**.

---

## 4. Where it shines

| Scenario | Cacheable prefix |
|---|---|
| Big **system prompt** / persona | The whole system prompt |
| **Few-shot** prompting (§3) | The exemplars |
| **Document Q&A** | The long document, asked many questions |
| **Agents** (§7) | Tool definitions + instructions repeated each loop step |
| **Multi-turn chat** | The stable system + early history |

Agents benefit a lot: an agent loop re-sends the same tool definitions and system prompt on every step — caching that prefix cuts both cost and per-step latency.

---

## 5. The TTL caveat

> [!WARNING]
> **Caches expire quickly**
> Prompt caches have a **short time-to-live** (on the order of minutes). The win comes from **bursts** — many requests sharing a prefix in a short window (an active chat session, a batch of questions over one document). A prefix used once an hour won't stay cached. Design traffic patterns to reuse prefixes while they're warm.

---

## 6. Practical checklist

- ✅ Move **all stable content to the front**; variable content to the end.
- ✅ Keep the system prompt **byte-identical** across calls (no timestamps, no per-request IDs early).
- ✅ For document Q&A, put the **document first**, the question last.
- ✅ For explicit-cache APIs, mark the **largest stable segment** as cacheable.
- ✅ Verify via the response usage (providers report **cached token** counts).
- ⚠️ Don't randomize/reorder stable content — it silently kills caching.

```python
# good ordering for caching
messages = [
    {"role": "system", "content": BIG_STABLE_SYSTEM_PROMPT},  # cached prefix
    *FEW_SHOT_EXAMPLES,                                        # cached prefix
    {"role": "user", "content": this_requests_question},      # variable, last
]
```

---

## 7. Main takeaways

- **Prompt caching** reuses the processed **prefix** → cheaper + faster repeated calls.
- **Cached input tokens** are heavily discounted; latency drops (no recompute).
- Matches on an **exact prefix** → put **stable content first, variable last**.
- Two flavors: **automatic** (provider) and **explicit** (cache markers).
- Big wins: large **system prompts**, **few-shot**, **document Q&A**, **agent loops**.
- Caches have a **short TTL** → savings come from **bursts**, not one-offs.
- Keep stable content **byte-identical**; verify cached-token counts in usage.

---

## 8. Things I still want to figure out

- Exact **discount + TTL** per provider (changes over time)?
- Minimum prefix length for caching to trigger?
- How prompt caching interacts with **streaming** (§4) and tool calls?

---

## 9. Things to dig into

- **OpenAI prompt caching** docs (automatic).
- **Anthropic prompt caching** (explicit cache_control).
- Verify with the **cached tokens** field in `usage`.
- Next: [[03 - Semantic Caching]].

---

## 10. Next up in this section

- [ ] [[03 - Semantic Caching]] — cache whole *answers* to repeated/similar questions.

---

## Related
- [[01 - Understanding LLM Cost and Tokens]] — the cost driver this targets.
- [[03 - Semantic Caching]] — the complementary, answer-level cache.

## Sources
- [OpenAI prompt caching](https://platform.openai.com/docs/guides/prompt-caching)
- [Anthropic prompt caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
