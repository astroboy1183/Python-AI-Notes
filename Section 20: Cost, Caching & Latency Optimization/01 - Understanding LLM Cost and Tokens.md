---
title: Understanding LLM Cost and Tokens
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 20: Cost, Caching & Latency Optimization"
tags:
  - cost
  - tokens
  - llmops
  - optimization
  - foundations
related:
  - "[[04 - What is a Token]]"
  - "[[02 - Prompt Caching]]"
---

# Understanding LLM Cost and Tokens

> [!NOTE]
> **TL;DR**
> LLM cost is billed per **token**, split into **input** (prompt) and **output** (completion) tokens — and **output usually costs several times more** than input. So cost = (input_tokens × input_price + output_tokens × output_price), per call. The big cost drivers in real apps: long system prompts repeated every call, RAG context stuffing, full chat history replayed each turn, agent loops that make many calls, and verbose outputs. The optimization levers (the rest of this section): **caching** (don't pay twice for the same work), **shorter context** (reranking, summarizing history, trimming), **model routing** (cheap model for easy tasks), **output limits**, and **batching**. Rule one: you can't optimize what you don't measure — track tokens/cost per request via observability (§17).

> [!NOTE]
> **Where this fits**
> First note of **Section 20: Cost, Caching & Latency Optimization**. It establishes the cost model; the rest of the section is levers to reduce it. Builds on the token concept from [[04 - What is a Token]].

---

## 1. The unit of cost: the token

Everything is priced in **tokens** (~¾ of a word in English; see [[04 - What is a Token]]). Providers charge **separately** for:

```
cost = input_tokens  × input_price_per_token
     + output_tokens × output_price_per_token
```

> [!IMPORTANT]
> **Output tokens cost more than input**
> Across providers, generated (output) tokens are typically priced **several times higher** than prompt (input) tokens — because generation is the expensive autoregressive step. Implication: a long *prompt* is cheaper than a long *answer*. Verbose model output is a sneaky cost driver; capping output length pays off directly.

---

## 2. Where the tokens (and cost) actually go

| Cost driver | Why it adds up |
|---|---|
| **System prompt** | Sent on **every** call; a 1k-token system prompt × millions of calls = real money |
| **RAG context** | Stuffing many/large chunks into every prompt (§8) |
| **Chat history** | Replaying the **whole** conversation each turn → grows unbounded |
| **Agent loops** | One user request → many LLM calls (reasoning + tool steps) |
| **Few-shot examples** | Long exemplars repeated every call |
| **Verbose output** | Padding, restating the question, markdown bloat |

```
naive chat turn 10:  [system][example1][example2][...10 turns of history...][query] → big input every time
```

---

## 3. Model tiers — the biggest single lever

Providers offer a ladder of models trading capability for cost:

```
nano/mini/small  ──cheap, fast, less capable──┐
                                               ├─ pick the SMALLEST that passes eval
flagship/large   ──expensive, slow, smartest──┘
```

A frontier model can be **10–100×** the price of a small one. Many tasks (classification, extraction, routing, simple Q&A) run fine on a small model. **Model routing** (note 05) sends each request to the cheapest model that's good enough.

> [!TIP]
> **Default to the smallest model that passes your eval**
> This is where §17 pays off: without an eval suite you can't safely downgrade. With one, you can prove a mini model holds quality on your task and capture the savings. "Use the big model everywhere" is the most common avoidable cost.

---

## 4. A worked intuition

```
Assume output is ~4× the input price.

Verbose bot:  1,500 input + 600 output  per turn
Lean bot:       400 input + 150 output  per turn  (reranked context, capped output, trimmed history)

Lean is ~4× cheaper per turn — same task, just optimized. Multiply by millions of turns.
```

(Illustrative — plug in current per-token prices for real numbers.)

---

## 5. The optimization levers (this section)

| Lever | Note | Saves |
|---|---|---|
| **Prompt caching** | [[02 - Prompt Caching]] | re-paying for the same prefix (system prompt, context) |
| **Semantic caching** | [[03 - Semantic Caching]] | re-answering the same/similar question |
| **Latency & streaming** | [[04 - Latency and Streaming]] | perceived + real time |
| **Model routing** | [[05 - Model Routing and Optimization Strategies]] | using a big model when a small one suffices |
| Context reduction | §18 reranking | tokens per call |
| History management | summarize / window | unbounded growth |
| Output limits | `max_tokens`, "be concise" | expensive output tokens |

---

## 6. Measure first

> [!IMPORTANT]
> **Track tokens and cost per request**
> Modern APIs return token **usage** in the response; observability tools (§17) aggregate it into cost dashboards per request/user/feature. Optimization without measurement is guesswork — find the biggest line item (often: history replay or oversized RAG context), fix that first.

```python
resp = client.chat.completions.create(...)
print(resp.usage)   # prompt_tokens, completion_tokens, total_tokens → cost
```

---

## 7. Main takeaways

- Cost is **per token**, split **input** vs **output**; **output costs more**.
- Drivers: **system prompt, RAG context, chat history, agent loops, few-shot, verbose output** — all repeated/multiplied.
- **Model tier is the biggest lever** — a frontier model can be 10–100× a small one.
- **Default to the smallest model that passes eval** (§17 makes this safe).
- Capping **output length** directly cuts the most expensive tokens.
- Levers: **caching, semantic caching, context reduction, history management, routing, batching**.
- **Measure per-request tokens/cost** (usage field + observability) before optimizing.

---

## 8. Things I still want to figure out

- Current **input vs output** price ratios across providers?
- How much do **agent loops** inflate cost vs single calls in practice?
- Best way to **budget/cap** spend per user to prevent abuse (DoS, §19)?

---

## 9. Things to dig into

- Provider **pricing pages** + the `usage` field in responses.
- **Tokenizer** tools (tiktoken) to estimate prompt size (§1).
- Cost dashboards in **LangSmith/Langfuse** (§17).
- Next: [[02 - Prompt Caching]].

---

## 10. Next up in this section

- [ ] [[02 - Prompt Caching]] — stop paying repeatedly for the same prompt prefix.

---

## Related
- [[04 - What is a Token]] — the billing unit.
- [[05 - Tracing and Observability]] — where cost is measured.

## Sources
- [OpenAI pricing & usage](https://platform.openai.com/docs/pricing)
- [Anthropic pricing](https://www.anthropic.com/pricing)
