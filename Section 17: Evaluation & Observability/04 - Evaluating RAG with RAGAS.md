---
title: Evaluating RAG with RAGAS
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 17: Evaluation & Observability"
tags:
  - evaluation
  - rag
  - ragas
  - retrieval
  - metrics
related:
  - "[[03 - LLM-as-a-Judge]]"
  - "[[05 - The Retrieval Phase]]"
  - "[[01 - Beyond Naive RAG]]"
---

# Evaluating RAG with RAGAS

> [!NOTE]
> **TL;DR**
> A RAG pipeline has **two** failure points — **retrieval** (wrong/missing context) and **generation** (bad answer from good context) — so it needs metrics that isolate each. **RAGAS** is the standard framework, with four core LLM-judged metrics: **Context Precision** and **Context Recall** measure the *retriever* (is the retrieved context relevant, and did it find everything needed?), while **Faithfulness** (is the answer grounded in the context, no hallucination?) and **Answer Relevancy** (does it address the question?) measure the *generator*. Crucially, RAGAS is largely **reference-free** — most metrics need only question, context, and answer, not a gold answer — which makes it cheap to run continuously. Low faithfulness ⇒ generation problem; low context recall ⇒ retrieval problem. That diagnosis tells me *what to fix*.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 17**, applying [[03 - LLM-as-a-Judge]] to RAG. It evaluates the pipeline built in §8 ([[05 - The Retrieval Phase]]) and motivates the upgrades in [[01 - Beyond Naive RAG]] (§18).

---

## 1. RAG fails in two distinct places

```
question ─►[ RETRIEVER ]─► context ─►[ GENERATOR (LLM) ]─► answer
              │                            │
        could be wrong               could hallucinate even
        (missing/irrelevant)          from perfect context
```

A single "is the answer good?" score can't tell these apart. If the answer is wrong, was it because retrieval missed the right document, or because the LLM ignored the document it had? **RAGAS splits the metrics so I can localize the fault.**

---

## 2. The four core RAGAS metrics

| Metric | Measures | Component | Needs gold answer? |
|---|---|---|---|
| **Context Precision** | Are the retrieved chunks *relevant* (and ranked well)? | Retriever | No |
| **Context Recall** | Did retrieval find *all* the needed info? | Retriever | Yes (or reference) |
| **Faithfulness** | Is the answer grounded in the context (no hallucination)? | Generator | No |
| **Answer Relevancy** | Does the answer actually address the question? | Generator | No |

Most are **reference-free** — they only need `(question, retrieved_context, answer)`. That's what makes RAGAS cheap enough to run on every change.

---

## 3. Retriever metrics

### Context Precision
Of the chunks retrieved, how many are actually relevant — and are the relevant ones ranked near the top? Low precision = retriever pulling **noise**.

### Context Recall
Of the information *needed* to answer, how much did retrieval actually surface? Low recall = retriever **missing** key documents (the more dangerous failure — you can't generate what you never retrieved).

```
high precision, low recall  → retrieving clean but incomplete context
low precision, high recall  → retrieving everything + a lot of junk
```

> [!TIP]
> **Recall is usually the priority**
> If the right chunk never gets retrieved, no amount of generation skill recovers it. Fixing low recall (better chunking, hybrid search, reranking — all in §18) is often the highest-leverage RAG improvement.

---

## 4. Generator metrics

### Faithfulness
Are the answer's claims **supported by the retrieved context**? RAGAS breaks the answer into claims and checks each against the context. Low faithfulness = **hallucination** (the model is inventing or using parametric knowledge instead of the source).

### Answer Relevancy
Does the answer **address the question** (not wander or pad)? A faithful answer can still be irrelevant; this catches that.

```
faithful + relevant   → good RAG answer
faithful + irrelevant → grounded but off-topic
unfaithful            → hallucinating (ignore context) — the worst
```

---

## 5. How to read the diagnosis

> [!IMPORTANT]
> **The metric pattern tells me what to fix**

| Symptom | Likely cause | Where to fix |
|---|---|---|
| Low **Context Recall** | Retriever misses docs | chunking, hybrid search, reranking ([[01 - Beyond Naive RAG]]) |
| Low **Context Precision** | Too much irrelevant context | reranking, smaller top-k, better embeddings |
| Low **Faithfulness** | LLM hallucinating | stricter prompt ("only use context"), better model |
| Low **Answer Relevancy** | LLM not answering the question | prompt, query understanding |

This is the payoff of splitting metrics: a number per component → a clear next action.

---

## 6. Using RAGAS (shape of the code)

```python
from ragas import evaluate
from ragas.metrics import (
    context_precision, context_recall,
    faithfulness, answer_relevancy,
)
from datasets import Dataset

# each row: question, retrieved contexts, generated answer, (optional) ground_truth
data = Dataset.from_dict({
    "question": [...],
    "contexts": [[...], ...],     # list of retrieved chunks per question
    "answer": [...],
    "ground_truth": [...],        # needed for context_recall
})

result = evaluate(
    data,
    metrics=[context_precision, context_recall, faithfulness, answer_relevancy],
)
print(result)   # one score per metric
```

(API names/shape are approximate — check the current RAGAS docs; the framework evolves.) Under the hood, these metrics call an LLM judge, so the same biases/costs from [[03 - LLM-as-a-Judge]] apply.

---

## 7. Building the eval dataset

- **Real questions** from users/logs are best (online → offline loop from [[01 - Why Evaluation Matters]]).
- For **Context Recall**, a reference/ground-truth answer is needed; the others are reference-free.
- **Synthetic generation**: RAGAS (and similar tools) can *generate* Q&A pairs from your documents to bootstrap a test set when you have no labeled data.

---

## 8. Main takeaways

- RAG fails at **retrieval** or **generation** — eval must separate them.
- **RAGAS** core metrics: **Context Precision/Recall** (retriever), **Faithfulness/Answer Relevancy** (generator).
- Most metrics are **reference-free** (just question + context + answer) → cheap to run often.
- **Recall** is usually the priority: un-retrieved info can't be answered.
- **Faithfulness** catches hallucination (answer not grounded in context).
- The metric pattern **diagnoses** what to fix (retriever vs generator).
- RAGAS uses **LLM judges** internally → inherits their costs/biases.
- Can **synthesize** a test set from your docs when unlabeled.

---

## 9. Things I still want to figure out

- How stable are RAGAS scores run-to-run (judge variance)?
- How well does synthetic Q&A reflect **real** user questions?
- Cost of running full RAGAS on a large corpus?
- Combining RAGAS with classic retrieval metrics (recall@k, MRR)?

---

## 10. Things to dig into

- **RAGAS docs**: https://docs.ragas.io/
- Classic IR metrics: **recall@k, MRR, nDCG**.
- **TruLens** as an alternative RAG-eval framework.
- Cross-link: the retrieval pipeline in [[05 - The Retrieval Phase]] and upgrades in §18.

---

## 11. Next up in this section

- [ ] [[05 - Tracing and Observability]] — watching all of this run in production.

---

## Related
- [[03 - LLM-as-a-Judge]] — the engine behind RAGAS metrics.
- [[05 - The Retrieval Phase]] — the RAG pipeline being evaluated.
- [[01 - Beyond Naive RAG]] — fixes for the problems RAGAS surfaces.

## Sources
- [RAGAS documentation](https://docs.ragas.io/)
- [TruLens](https://www.trulens.org/)
