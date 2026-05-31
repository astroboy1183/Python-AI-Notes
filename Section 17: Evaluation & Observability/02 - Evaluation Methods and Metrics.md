---
title: Evaluation Methods and Metrics
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 17: Evaluation & Observability"
tags:
  - evaluation
  - metrics
  - testing
  - llmops
related:
  - "[[01 - Why Evaluation Matters]]"
  - "[[03 - LLM-as-a-Judge]]"
---

# Evaluation Methods and Metrics

> [!NOTE]
> **TL;DR**
> There's a spectrum of ways to score LLM output, trading off cost, speed, and how well they capture quality. **Reference-based** metrics compare against a known answer: exact/fuzzy match for closed tasks, and overlap metrics like BLEU/ROUGE for text (cheap but shallow). **Semantic similarity** uses embeddings to score "close in meaning" rather than exact words. **Human evaluation** is the gold standard but slow and expensive. **LLM-as-a-judge** uses a strong model to grade outputs — the practical sweet spot for open-ended tasks (its own note). On top of these sit **task metrics** (did the agent call the right tool? is the JSON valid?) and a **rubric/criteria** approach for nuanced quality. The right choice depends on whether the task has a single correct answer or is open-ended.

> [!NOTE]
> **Where this fits**
> Second note of **Section 17**. It catalogs scoring methods; [[03 - LLM-as-a-Judge]] zooms into the most useful one for open-ended tasks, and [[04 - Evaluating RAG with RAGAS]] applies them to retrieval.

---

## 1. The decision: closed vs open-ended task

The first question for any eval: **does the task have a single correct answer?**

```
closed task   (classification, extraction, math) → reference-based metrics work great
open-ended    (summaries, chat, code, creative)  → need semantic / judge / human
```

Picking a metric that doesn't match the task is the most common eval mistake.

---

## 2. Reference-based: comparing to a known answer

### Exact / fuzzy match
For closed tasks where there's a ground-truth label.

```python
score = (prediction.strip().lower() == reference.strip().lower())
```

Fuzzy variants allow minor differences (normalization, edit distance). Great for classification, entity extraction, multiple-choice.

### Overlap metrics: BLEU & ROUGE
Word/n-gram overlap between output and reference text.

| Metric | Origin | Measures |
|---|---|---|
| **BLEU** | machine translation | precision of n-gram overlap |
| **ROUGE** | summarization | recall of n-gram overlap |

> [!WARNING]
> **Overlap metrics are shallow**
> BLEU/ROUGE only see surface words, not meaning. "The cat sat on the mat" vs "A feline rested on the rug" score near-zero overlap despite being equivalent. They're cheap and fast but a weak proxy for quality on modern generative tasks — use with caution.

---

## 3. Semantic similarity (embedding-based)

Embed both the output and the reference, then compare with cosine similarity. Captures *meaning*, not just word overlap.

```python
sim = cosine_similarity(embed(prediction), embed(reference))
```

- ✅ Robust to paraphrase ("feline rested on the rug" ≈ "cat sat on the mat").
- ⚠️ Still needs a reference answer; can't judge correctness of facts the reference doesn't contain.

This reuses the embedding ideas from §1/§8 — same tool, applied to scoring.

---

## 4. Human evaluation — the gold standard

Humans rate outputs (thumbs up/down, 1–5 ratings, or pick-the-better A/B).

| Pros | Cons |
|---|---|
| Captures nuance no metric does | **Slow, expensive, hard to scale** |
| The ultimate ground truth | Subjective; needs clear rubrics + multiple raters |

Used to **calibrate** automated metrics (does the LLM judge agree with humans?) and for high-stakes final checks — not for every CI run.

---

## 5. LLM-as-a-judge — the practical default

Use a strong LLM to grade an output against a rubric or reference. It's the workhorse for open-ended tasks: far cheaper/faster than humans, far more semantic than BLEU. Full treatment in [[03 - LLM-as-a-Judge]].

```
output + criteria ─► judge LLM ─► score (+ reasoning)
```

---

## 6. Task-specific / functional metrics

Often the most reliable signal is **did it do the job?** — checkable with plain code:

| Task | Functional metric |
|---|---|
| Structured output | Is the JSON valid? Does it match the Pydantic schema? |
| Tool-calling agent | Did it call the **right tool** with the right args? |
| Code generation | Does the code **run** / pass unit tests? |
| Classification | Accuracy, precision, recall, F1 |
| Retrieval | Hit rate, MRR, recall@k (see [[04 - Evaluating RAG with RAGAS]]) |

> [!TIP]
> **Prefer deterministic checks where possible**
> If correctness can be verified by code (valid JSON, code runs, exact label), do that — it's free, fast, and unambiguous. Save LLM-judge / human eval for the genuinely subjective parts.

---

## 7. Rubric / criteria-based scoring

For nuanced quality, define explicit **criteria** and score each:

```
- Relevance:    does it answer the question?        (1-5)
- Faithfulness: is it grounded in the source?       (1-5)
- Coherence:    is it well-structured?              (1-5)
- Safety:       free of harmful content?            (pass/fail)
- Conciseness:  no padding?                         (1-5)
```

A judge (or human) scores each criterion; aggregate into an overall. Decomposing quality into named axes is far more reliable than asking for one vague "is this good?" score.

---

## 8. Choosing a metric — quick guide

```
single correct answer? ──► exact/fuzzy match, F1
text with a reference? ──► semantic similarity (+ ROUGE as a cheap proxy)
open-ended quality?    ──► LLM-as-a-judge with a rubric
"did it work"?         ──► functional check (valid JSON, code runs, right tool)
highest stakes / calibration? ──► human eval
```

Most real eval suites **combine several**: e.g. functional check (valid output) + judge (quality) + similarity (vs reference).

---

## 9. Main takeaways

- First decide: **closed** (single answer) vs **open-ended** task.
- **Reference-based**: exact/fuzzy match (closed); BLEU/ROUGE (text, but shallow).
- **Semantic similarity** (embeddings) handles paraphrase but needs a reference.
- **Human eval** = gold standard, but slow/expensive — use to calibrate.
- **LLM-as-a-judge** = practical default for open-ended tasks.
- **Functional metrics** (valid JSON, right tool, code runs) are cheap and unambiguous — prefer them.
- **Rubric-based** scoring decomposes quality into named criteria.
- Real suites **combine** functional + judge + similarity.

---

## 10. Things I still want to figure out

- How well do **automated metrics correlate** with human judgment per task?
- When is **ROUGE/BLEU** still worth reporting vs pure noise?
- How many criteria is too many in a rubric?
- How to weight/aggregate multiple metrics into one decision?

---

## 11. Things to dig into

- **Hugging Face Evaluate** (BLEU, ROUGE, etc.): https://huggingface.co/docs/evaluate/
- **DeepEval** / **promptfoo** — eval frameworks with many built-in metrics.
- **scikit-learn** metrics for classification (precision/recall/F1).
- Next: [[03 - LLM-as-a-Judge]].

---

## 12. Next up in this section

- [ ] [[03 - LLM-as-a-Judge]] — using an LLM to grade open-ended outputs reliably.

---

## Related
- [[01 - Why Evaluation Matters]] — why this matters.
- [[03 - LLM-as-a-Judge]] / [[04 - Evaluating RAG with RAGAS]] — applying these methods.

## Sources
- [Hugging Face Evaluate](https://huggingface.co/docs/evaluate/)
- [promptfoo](https://www.promptfoo.dev/)
