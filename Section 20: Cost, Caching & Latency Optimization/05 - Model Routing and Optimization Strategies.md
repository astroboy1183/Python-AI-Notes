---
title: Model Routing and Optimization Strategies
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 20: Cost, Caching & Latency Optimization"
tags:
  - cost
  - model-routing
  - optimization
  - llmops
related:
  - "[[01 - Understanding LLM Cost and Tokens]]"
  - "[[04 - Latency and Streaming]]"
---

# Model Routing and Optimization Strategies

> [!NOTE]
> **TL;DR**
> **Model routing** sends each request to the **cheapest model that can handle it** instead of using one big model for everything. Easy tasks (classification, routing, simple Q&A) → a small/fast/cheap model; hard tasks (complex reasoning, code) → a flagship model. Routing strategies range from **rules** (by task type, prompt length, keywords) to a **cheap classifier/LLM router** that grades difficulty, to **cascade/fallback** (try the cheap model first, escalate only if its answer fails a confidence/quality check). Combined with the rest of the section — **prompt caching** (§2), **semantic caching** (§3), **context reduction** (§18 rerank), **history management**, and **output limits** — routing can cut spend dramatically. The enabling discipline is **eval (§17)**: you can only safely downgrade a task once you've proven a smaller model passes.

> [!NOTE]
> **Where this fits**
> Final note of **Section 20**. It's the biggest cost lever from [[01 - Understanding LLM Cost and Tokens]], and it ties all the section's strategies together into a playbook.

---

## 1. The idea: right-size the model per request

Using a frontier model for *everything* is like sending a senior engineer to answer "what's 2+2." Most requests are easy; route them to a cheap model and reserve the expensive one for the hard ones.

```
                ┌─ easy (classify, extract, route, FAQ) ─► small model (cheap, fast)
request ─► route┤
                └─ hard (multi-step reasoning, code)     ─► flagship model (smart)
```

A frontier model can be **10–100×** the price of a small one (§1), so even routing *half* the traffic down a tier is a large saving.

---

## 2. Routing strategies

| Strategy | How | Trade-off |
|---|---|---|
| **Rule-based** | Route by task type, prompt length, keywords, endpoint | Simple, predictable; brittle for fuzzy cases |
| **Classifier router** | A cheap model/classifier predicts difficulty → picks tier | Flexible; adds a small upfront call |
| **Cascade / fallback** | Try cheap model; **escalate** if its answer fails a check | Pay extra only on hard cases; needs a good "did it fail?" signal |
| **Embedding/similarity** | Route based on similarity to known easy/hard examples | Data-driven; needs examples |

### Cascade — the elegant default
```
query → cheap model → answer
          │ confidence / quality check (self-rating, validation, judge)
          ├─ passes → return (cheap!)
          └─ fails  → escalate to flagship → return
```
Most traffic resolves on the cheap tier; only the genuinely hard fraction pays for the big model. The check itself must be cheap and reliable (functional validation, a quick judge, §17).

---

## 3. Beyond model choice — the full playbook

Routing is one lever; combine with the rest of the section:

| Strategy | Section | Saves |
|---|---|---|
| **Smallest model that passes eval** | §17 + this | the biggest line item |
| **Model routing / cascade** | this | big-model calls on easy tasks |
| **Prompt caching** | [[02 - Prompt Caching]] | reprocessing stable prefixes |
| **Semantic caching** | [[03 - Semantic Caching]] | whole calls for repeat questions |
| **Context reduction** (rerank, trim) | §18, [[04 - Latency and Streaming]] | input tokens per call |
| **History management** (summarize/window) | §13/§20 | unbounded history growth |
| **Output limits** (`max_tokens`, concise) | [[01 - Understanding LLM Cost and Tokens]] | expensive output tokens |
| **Batching** | §24 serving | throughput/efficiency |

---

## 4. Managing chat history (a routing-adjacent lever)

Replaying the full conversation each turn grows cost linearly (§1). Options:

| Technique | How |
|---|---|
| **Sliding window** | Keep only the last N turns |
| **Summarization** | Periodically compress old turns into a short summary |
| **Memory (§13)** | Store facts externally; retrieve relevant ones instead of replaying all |

The §13 memory layer is itself a cost optimization: send *relevant memories* instead of the *entire history*.

---

## 5. Quality must gate cost-cutting

> [!IMPORTANT]
> **Never downgrade without eval**
> Every optimization here risks quality: a smaller model, a cache hit, trimmed context, a shorter answer — each can degrade output. The **eval suite (§17)** is the guardrail. Process: change → run eval → ship only if the score holds. Without eval, cost-cutting is just quietly shipping a worse product.

```
optimization → eval score holds? ── yes → keep the savings
                                 └─ no  → revert / route only easy cases down
```

---

## 6. A concrete routing example

```python
# rule + cascade hybrid (conceptual)
def route(query):
    if is_simple(query):                 # rule: short, classification-like
        return "gpt-4.1-nano"
    return "gpt-4.1-mini"

def answer(query):
    model = route(query)
    resp = llm(query, model=model)
    if not passes_quality(resp):         # cascade: escalate on failure
        resp = llm(query, model="gpt-4.1")   # flagship fallback
    return resp
```

(Model names illustrative.) Measure the resulting **cost per request** and **quality** (§17) to confirm the trade is net-positive.

---

## 7. Main takeaways

- **Model routing** = send each request to the **cheapest model that's good enough**.
- Strategies: **rule-based**, **classifier router**, **cascade/fallback**, **similarity**.
- **Cascade** (cheap first, escalate on failure) is an elegant default — most traffic stays cheap.
- Combine routing with **caching (§2/§3), context reduction, history management, output limits, batching**.
- **Memory (§13)** cuts cost by sending *relevant facts* instead of *full history*.
- **Eval (§17) gates every optimization** — never downgrade without proving quality holds.
- A frontier model is 10–100× a small one, so routing even part of traffic down saves a lot.

---

## 8. Things I still want to figure out

- Cheapest reliable **difficulty classifier** for routing?
- Best **quality-check signal** for cascade escalation (cheap + accurate)?
- Managed **router** services vs rolling my own?

---

## 9. Things to dig into

- **RouteLLM** and other routing frameworks.
- **Cascade / FrugalGPT** ideas (try-cheap-then-escalate).
- History **summarization** chains; memory (§13) as cost control.

---

## 10. Section wrap-up

Section 20 is the **efficiency layer**: understand token cost, stop paying twice (**prompt + semantic caching**), make it feel fast (**streaming/latency**), and right-size the model (**routing**) — all gated by **eval (§17)** so savings don't silently cost quality. Together with safety (§19) and evaluation (§17), this is what makes an AI app not just *work* but *sustainable* at scale.

---

## Related
- [[01 - Understanding LLM Cost and Tokens]] — the cost model routing optimizes.
- [[04 - Latency and Streaming]] — routing also affects latency.
- [[09 - Building a Memory-Aware Assistant]] — memory as a history-cost optimization.

## Sources
- [RouteLLM](https://github.com/lm-sys/RouteLLM)
- [FrugalGPT paper](https://arxiv.org/abs/2305.05176)
