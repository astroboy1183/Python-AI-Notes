---
title: Hallucination Mitigation
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 19: Safety, Security & Guardrails"
tags:
  - security
  - hallucination
  - grounding
  - reliability
related:
  - "[[04 - PII, Privacy and Content Moderation]]"
  - "[[04 - Evaluating RAG with RAGAS]]"
---

# Hallucination Mitigation

> [!NOTE]
> **TL;DR**
> A **hallucination** is a confident, plausible-sounding output that's **factually wrong or unsupported**. It's intrinsic to how LLMs work — they predict likely tokens, not verified facts, so they'll happily invent citations, APIs, dates, or numbers. It can't be eliminated, only **reduced and detected**. The biggest lever is **grounding**: give the model real context (RAG, §8) and instruct it to answer **only** from that context and say "I don't know" otherwise. Other mitigations: **citations** (force the model to point at sources, making fabrication checkable), **lower temperature**, **self-consistency** (sample several answers; disagreement signals uncertainty), **LLM-judge faithfulness checks** (RAGAS, §17) as an output guardrail, and **human review** for high-stakes outputs. The mindset: treat fluent output as a **claim to verify**, never as established fact.

> [!NOTE]
> **Where this fits**
> Final note of **Section 19**. It's the "overreliance" risk from [[01 - The AI Security Landscape]], and it ties safety to the RAG-faithfulness metric from [[04 - Evaluating RAG with RAGAS]].

---

## 1. Why hallucination happens

LLMs are **next-token predictors** (§1), optimized for *plausibility*, not *truth*. When the model lacks the fact, it doesn't stop — it generates the most likely-sounding continuation, which is often wrong but **fluent and confident**.

```
"What's the API method to do X?"  →  invents `client.do_x()`  (looks real, doesn't exist)
"Cite a paper on Y."              →  fabricates a plausible title + authors + year
```

> [!IMPORTANT]
> **Fluency is not accuracy**
> The danger isn't that the model is wrong — it's that it's wrong **confidently and convincingly**. There's no built-in "I'm unsure" signal in the text. Treat every factual claim as **unverified** until grounded or checked.

---

## 2. Grounding — the #1 mitigation

Give the model the facts and constrain it to them. This is exactly what **RAG (§8)** is for — but it only helps if the prompt *forces* reliance on the context:

```
System: "Answer ONLY using the provided context. If the answer is not in
the context, say 'I don't have that information.' Do not use prior knowledge."

Context: {retrieved docs}
Question: {user question}
```

> [!TIP]
> **Make "I don't know" an acceptable answer**
> Models hallucinate partly because they're implicitly pushed to always answer. Explicitly permitting (and rewarding) "I don't know / not in the context" is one of the cheapest, most effective anti-hallucination moves. Pair it with good retrieval — grounding fails if the right context was never retrieved (low RAGAS recall, §18).

---

## 3. Citations and attribution

Require the model to **cite which source** each claim comes from:

```
"For every statement, cite the source chunk id in [brackets]."
→ "The refund window is 30 days [doc_3]."
```

Benefits:
- **Verifiable** — a human (or a checker) can confirm the claim against the cited source.
- **Deterrent** — harder to fabricate when forced to point at a real source.
- **Trust/UX** — users can click through to verify.

If the model can't cite a source, that's a signal the claim may be ungrounded.

---

## 4. Detection techniques

| Technique | How it flags hallucination |
|---|---|
| **Faithfulness check (LLM judge)** | Verify each claim is supported by the context — RAGAS Faithfulness (§17), runnable as an **output guardrail** (§3) |
| **Self-consistency** | Sample N answers; if they **disagree**, the model is uncertain → flag/abstain |
| **NLI / entailment** | Check whether context *entails* the answer |
| **Uncertainty signals** | Low token probabilities / hedging language as a heuristic |
| **Cross-check tools** | For facts, verify with a real source (search, calculator, DB) |

```
self-consistency:
  ask 5×  → 4 say "30 days", 1 says "14 days"  → mostly consistent, modest confidence
          → 5 different answers → high uncertainty → don't trust / abstain
```

---

## 5. Generation-time knobs

- **Lower temperature** for factual tasks → less random invention (doesn't fix missing knowledge, but reduces drift).
- **Tool use** instead of recall — let the model **look it up** (search, DB query, calculator) rather than answer from parametric memory. An agent that *retrieves* the date won't hallucinate it.
- **Smaller, focused context** (reranking, §18) — less irrelevant text to get confused by, improving faithfulness.

---

## 6. Process & human factors

- **Human-in-the-loop** for high-stakes domains (medical, legal, financial) — the model drafts, a human verifies.
- **Set user expectations** — UI cues that output may be wrong; show sources.
- **Domain guardrails** — block confident answers outside the knowledge base scope.

> [!WARNING]
> **Overreliance is itself a risk (OWASP)**
> The failure mode isn't only the model hallucinating — it's *humans trusting it blindly*. Design the product so users can and do verify (citations, sources, confidence cues), especially where a wrong answer causes real harm.

---

## 7. The layered approach

```
retrieve good context (§18) → prompt: "answer only from context, else 'I don't know'"
  → require citations → generate (low temp / tools)
  → output guardrail: faithfulness check (§17) → human review if high-stakes
```

No single step removes hallucination; together they make it **rare and catchable**.

---

## 8. Main takeaways

- **Hallucination** = confident, plausible, **wrong/unsupported** output — intrinsic to next-token prediction.
- Can't be eliminated, only **reduced and detected**.
- **Grounding (RAG)** is the #1 lever — *and* instruct "answer only from context, else say I don't know."
- **Citations** make claims verifiable and deter fabrication.
- Detect with **faithfulness checks (RAGAS as a guardrail)**, **self-consistency**, entailment, uncertainty signals.
- Knobs: **lower temperature**, **use tools** (look it up vs recall), **rerank** for cleaner context.
- **Human-in-the-loop** for high-stakes; combat **overreliance** with verifiable UX.
- Treat fluent output as a **claim to verify**, never as fact.

---

## 9. Things I still want to figure out

- How reliable are **uncertainty/log-prob** signals as hallucination detectors?
- Cost/latency of running **faithfulness checks** on every response?
- Does **self-consistency** pay off vs its extra calls for factual QA?

---

## 10. Things to dig into

- **RAGAS Faithfulness** as a runtime guardrail (§17).
- **Self-consistency** and **chain-of-verification (CoVe)**.
- Grounded-generation / citation patterns in LangChain/LlamaIndex.

---

## 11. Section wrap-up

Section 19 covers the **trust layer**: the threat model (OWASP), the #1 attack (**prompt injection**), the enforcement mechanism (**guardrails**), **privacy/PII + moderation**, and **hallucination**. Combined with evaluation/observability (§17), this is what makes an AI app safe enough to put in front of real users — the difference between a demo and a deployable product.

---

## Related
- [[04 - Evaluating RAG with RAGAS]] — Faithfulness, reused as a guardrail.
- [[01 - The AI Security Landscape]] — hallucination = the "overreliance" risk.
- [[03 - What is RAG and the Naive Approach]] — grounding as the core fix.

## Sources
- [OWASP: Overreliance](https://owasp.org/www-project-top-10-for-large-language-model-applications/)
- [Chain-of-Verification (CoVe) paper](https://arxiv.org/abs/2309.11495)
