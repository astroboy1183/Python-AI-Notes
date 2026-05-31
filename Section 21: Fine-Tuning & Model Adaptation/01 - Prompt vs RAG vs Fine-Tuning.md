---
title: Prompt vs RAG vs Fine-Tuning
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 21: Fine-Tuning & Model Adaptation"
tags:
  - fine-tuning
  - rag
  - prompting
  - decision-framework
  - foundations
related:
  - "[[02 - How Fine-Tuning Works]]"
  - "[[03 - What is RAG and the Naive Approach]]"
---

# Prompt vs RAG vs Fine-Tuning

> [!NOTE]
> **TL;DR**
> When the base model isn't doing what I need, there are three ways to adapt it — in increasing order of effort/cost: **prompting** (change the instructions/examples), **RAG** (inject external knowledge at runtime), and **fine-tuning** (change the model's weights by training on examples). The key insight is that they solve **different problems**: prompting/RAG add **knowledge and context**; fine-tuning teaches **behavior, format, and style** — *how* to respond, not *what facts* to know. The standard ladder: **try prompting first** (cheapest, instant), **add RAG when you need fresh/proprietary knowledge**, and **fine-tune only when prompting+RAG can't get the behavior/consistency/latency you need**. A common myth: "fine-tune to add knowledge." Usually wrong — RAG is better for facts; fine-tuning is for skills and style. They also **combine** (a fine-tuned model used inside a RAG pipeline).

> [!NOTE]
> **Where this fits**
> First note of **Section 21: Fine-Tuning & Model Adaptation**. It positions fine-tuning against the prompting (§3) and RAG (§8) you already know, so the rest of the section (how FT actually works) lands in context.

---

## 1. The three adaptation levers

```
effort/cost  ▲
    fine-tune │  change WEIGHTS (train on examples) — behavior, style, format
        RAG   │  inject KNOWLEDGE at runtime (retrieve + prompt)
     prompt   │  change INSTRUCTIONS/examples (no training)
              └──────────────────────────────────────────────►
```

| Lever | Changes | Cost | Latency to set up | Updates knowledge? |
|---|---|---|---|---|
| **Prompting** | The input | ~free | instant | n/a (no knowledge added) |
| **RAG** | Runtime context | low–medium | hours–days | **easy** (update the index) |
| **Fine-tuning** | Model **weights** | high | days+ (data + training) | **hard** (retrain) |

---

## 2. The crucial distinction: knowledge vs behavior

> [!IMPORTANT]
> **RAG adds knowledge; fine-tuning shapes behavior**
> This is the single most important idea in the whole decision:
> - Need the model to **know facts** (your docs, recent data, proprietary info)? → **RAG**. Facts change; retrieval updates instantly; sources are citable.
> - Need the model to **behave a certain way** (always output this JSON shape, adopt this tone/persona, follow a domain's style, do a narrow task reliably)? → **fine-tuning**. You're teaching a *skill*, not memorizing *facts*.

```
"answer questions about OUR 2026 policies"     → RAG (knowledge, changes often)
"always reply as a terse SQL generator"        → fine-tune (behavior/format)
"classify support tickets into our 12 labels"  → fine-tune (narrow skill, consistency)
"chat helpfully"                                → prompting (base behavior is enough)
```

---

## 3. Why "fine-tune to add knowledge" is usually wrong

A frequent mistake: fine-tuning a model on company documents to "make it know them."

- Fine-tuning **bakes facts into weights** — but facts go **stale**, and retraining is slow/expensive.
- It's prone to **forgetting** and can't **cite sources** (hurts trust/hallucination, §19).
- RAG does this **better**: update the index in seconds, cite sources, no training.

> [!WARNING]
> **Fine-tuning is a poor database**
> Don't fine-tune to inject knowledge that changes or needs attribution — that's RAG's job. Fine-tune to inject *consistent behavior* that prompting can't reliably achieve. (Edge case: highly stable, domain-specific *vocabulary/format* can be worth fine-tuning; volatile facts never are.)

---

## 4. When fine-tuning is actually the right call

| Reason to fine-tune | Why prompting/RAG falls short |
|---|---|
| **Consistent format/structure** | Few-shot helps but a fine-tuned model nails it every time |
| **Specific style/tone/persona** | Hard to fully pin down in a prompt |
| **Narrow, repeated task** | A small fine-tuned model can beat a big prompted one — cheaper + faster |
| **Latency/cost at scale** | Fine-tune a *small* model to match a big prompted one → cheaper inference (ties to §20 routing) |
| **Shorter prompts** | Behavior in the weights → no giant few-shot prompt every call (saves tokens) |
| **Domain language** | Legal/medical/code styles the base model handles awkwardly |

---

## 5. The decision ladder

```
1. PROMPT   → can good instructions + few-shot get it? (try first — free, instant)
        │ no / not consistent enough
        ▼
2. RAG      → is the gap missing KNOWLEDGE (facts, docs, fresh data)? → add RAG
        │ behavior/format/style still wrong or inconsistent, or cost/latency too high
        ▼
3. FINE-TUNE → teach the BEHAVIOR into the weights (needs a dataset + training)
```

> [!TIP]
> **Exhaust the cheap options first**
> Prompting and RAG are faster to build, cheaper, and easier to change. Most "we need to fine-tune" instincts are solved by better prompting or RAG. Fine-tune when you've **proven** (via eval, §17) that prompt+RAG can't hit the behavior/consistency/latency target — and you have (or can build) a quality dataset.

---

## 6. They combine

These aren't mutually exclusive:

```
fine-tuned small model (behavior/format)  +  RAG (knowledge)  +  good prompt (instructions)
```

A common production pattern: fine-tune a small model for your task's *style and format*, feed it *retrieved knowledge* via RAG, with a tight *prompt* — getting consistency, freshness, and low cost together.

---

## 7. Main takeaways

- Three adaptation levers, cheapest→costliest: **prompting → RAG → fine-tuning**.
- **RAG adds knowledge; fine-tuning shapes behavior/style/format.**
- "**Fine-tune to add knowledge**" is usually **wrong** — RAG is better for facts (fresh, citable).
- Fine-tune for **consistency, style, narrow tasks, lower cost/latency, shorter prompts, domain language**.
- Follow the **ladder**: prompt → RAG → fine-tune; exhaust cheap options first.
- **Eval (§17)** proves whether you actually need to fine-tune.
- They **combine**: fine-tuned small model + RAG + good prompt.

---

## 8. Things I still want to figure out

- How much data does fine-tuning actually need for a given task? (Next notes.)
- Where's the break-even where a fine-tuned small model beats a prompted big one on cost?
- Can fine-tuning + RAG conflict (model "fights" the retrieved context)?

---

## 9. Things to dig into

- OpenAI / provider **fine-tuning guides** (when-to-use sections).
- "RAG vs fine-tuning" comparison studies.
- Next: [[02 - How Fine-Tuning Works]].

---

## 10. Next up in this section

- [ ] [[02 - How Fine-Tuning Works]] — what training on examples actually does to a model.

---

## Related
- [[03 - What is RAG and the Naive Approach]] — the knowledge lever.
- [[02 - What is Prompting]] — the cheapest lever.
- [[05 - Model Routing and Optimization Strategies]] — fine-tuned small models as a cost play.

## Sources
- [OpenAI fine-tuning guide](https://platform.openai.com/docs/guides/fine-tuning)
- [Anthropic: when to fine-tune](https://docs.anthropic.com/)
