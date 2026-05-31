---
title: LLM-as-a-Judge
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 17: Evaluation & Observability"
tags:
  - evaluation
  - llm-as-judge
  - metrics
  - llmops
related:
  - "[[02 - Evaluation Methods and Metrics]]"
  - "[[04 - Evaluating RAG with RAGAS]]"
---

# LLM-as-a-Judge

> [!NOTE]
> **TL;DR**
> **LLM-as-a-judge** uses a strong model to grade another model's output — the practical middle ground between cheap-but-shallow metrics (BLEU) and accurate-but-expensive human eval. Three common modes: **reference-free** (score an output against a rubric, no gold answer needed), **reference-based** (compare output to a known good answer), and **pairwise** (which of A/B is better — the most reliable, since relative judgments beat absolute scores). The catch: judges have **biases** — position bias (favoring the first option), verbosity bias (longer = "better"), self-preference (favoring their own family's style), and inconsistency. Mitigate with clear rubrics, structured output, swapping A/B order, few-shot anchors, and calibrating against humans. It's powerful and scalable but **not ground truth** — validate it.

> [!NOTE]
> **Where this fits**
> Third note of **Section 17**, expanding the most useful method from [[02 - Evaluation Methods and Metrics]]. The RAGAS metrics in [[04 - Evaluating RAG with RAGAS]] are largely LLM-as-judge under the hood.

---

## 1. The idea

If a strong LLM can *write* a good answer, it can usually *recognize* one. So use one model (the **judge**) to score another model's output.

```
candidate output  ─┐
       criteria    ├─►  judge LLM  ─►  score + reasoning
   (+ reference)   ─┘
```

It's already shown up in this course: the LLM-as-judge retry loop in [[09 - Conditional Edges]]. This note makes it a proper discipline.

---

## 2. Why it's the practical default

| Method | Cost | Speed | Semantic quality | Scales? |
|---|---|---|---|---|
| BLEU/ROUGE | ~free | fast | low | yes |
| Human | high | slow | highest | no |
| **LLM-as-judge** | medium | medium | high | **yes** |

It captures meaning (unlike overlap metrics) and runs automatically on hundreds of cases (unlike humans). That combination is why it dominates modern LLM eval.

---

## 3. The three modes

### a) Reference-free (single-output scoring)
Grade an output against a **rubric**, with no gold answer.

```
Prompt to judge:
"Rate the following answer for {relevance, factual accuracy, clarity}
 on a 1-5 scale. Answer: {output}. Return JSON {scores, reasoning}."
```
✅ No reference needed. ⚠️ Absolute scores are noisier than relative ones.

### b) Reference-based
Compare the output to a **known good answer**.

```
"Here is the correct answer: {reference}.
 Does the candidate answer match it in meaning? Score 1-5. {candidate}"
```
✅ Grounded by the reference. ⚠️ Needs a curated gold set.

### c) Pairwise comparison (A vs B) — most reliable
Show the judge two outputs and ask **which is better**.

```
"Question: {q}. Answer A: {a}. Answer B: {b}.
 Which answer is better, and why? Return 'A' or 'B'."
```

> [!TIP]
> **Relative beats absolute**
> Models are far more consistent at "**which is better?**" than at "rate this 1–10." Pairwise comparison is the most reliable judge mode — ideal for comparing two prompt/model versions (v1 vs v2 → win rate).

---

## 4. The biases (and fixes)

> [!WARNING]
> **Judges are biased — design around it**

| Bias | What happens | Mitigation |
|---|---|---|
| **Position bias** | Favors whichever option is shown **first** | Run A/B in **both orders**, average |
| **Verbosity bias** | Rates **longer** answers as better | Add "ignore length; judge substance" + length penalty |
| **Self-preference** | Prefers outputs in its own family's style | Use a **different** model family as judge |
| **Inconsistency** | Different score on re-run | Low temperature; average multiple runs |
| **Leniency** | Everything scores 4–5 | Force a rubric with **explicit fail criteria** |

---

## 5. Making a judge reliable

```python
JUDGE_PROMPT = """You are a strict evaluator. Score the answer on each
criterion from 1-5. Be critical; reserve 5 for excellent.

Question: {question}
Answer: {answer}

Criteria:
- relevance: addresses the question
- faithfulness: grounded, no fabrication
- clarity: well-structured

Return JSON: {{"relevance": int, "faithfulness": int,
"clarity": int, "reasoning": str}}"""
```

Reliability checklist:
- **Clear rubric** with named criteria (decompose, don't ask "is it good?").
- **Structured output** (JSON / Pydantic) so scores are parseable.
- **Low temperature** for consistency; optionally **average N runs**.
- **Few-shot anchors** — show example outputs at score 1, 3, 5.
- **Ask for reasoning** before the score (chain-of-thought improves judgments).
- A **strong model** as judge (judging needs more capability than the task).

---

## 6. Calibrate against humans

> [!IMPORTANT]
> **An unvalidated judge is just another opinion**
> Before trusting a judge, check it **agrees with human ratings** on a sample (measure correlation / agreement). If the judge and humans disagree often, fix the rubric or swap the judge model. A judge is only as trustworthy as its agreement with the ground truth it stands in for.

```
sample 50 cases → human-rate them → judge-rate the same → measure agreement
high agreement → trust the judge at scale.  low → fix rubric / model.
```

---

## 7. Costs and caveats

- **Cost**: every eval run now spends tokens on the judge — material on large test sets (ties into [[01 - Why Evaluation Matters]] cost questions and §20).
- **Not ground truth**: a judge can be confidently wrong; it's a *proxy*.
- **Don't grade with the model under test** where avoidable (self-preference).

---

## 8. Main takeaways

- **LLM-as-a-judge** = a strong model grades outputs — scalable + semantic.
- Three modes: **reference-free** (rubric), **reference-based** (vs gold), **pairwise** (A/B).
- **Pairwise is most reliable** — relative judgments beat absolute scores.
- Watch for **position, verbosity, self-preference, inconsistency, leniency** biases.
- Reliability: clear rubric, structured output, low temp, reasoning-first, strong judge.
- **Calibrate against humans** before trusting it at scale.
- It costs tokens and is a **proxy**, not ground truth.

---

## 9. Things I still want to figure out

- How much does **swapping A/B order** actually change verdicts in practice?
- Best judge model when the task model is already top-tier?
- How many runs to average for stable scores vs cost?
- Can a **panel of diverse judges** (majority vote) beat one judge?

---

## 10. Things to dig into

- **MT-Bench / Chatbot Arena** (pairwise judging at scale).
- **DeepEval**, **Ragas**, **promptfoo** judge implementations.
- "Judging LLM-as-a-Judge" research on biases.
- Next: [[04 - Evaluating RAG with RAGAS]].

---

## 11. Next up in this section

- [ ] [[04 - Evaluating RAG with RAGAS]] — judge-based metrics specialized for retrieval pipelines.

---

## Related
- [[02 - Evaluation Methods and Metrics]] — the broader metric catalog.
- [[09 - Conditional Edges]] — an LLM-judge retry loop in LangGraph.

## Sources
- [MT-Bench / LLM-as-judge paper](https://arxiv.org/abs/2306.05685)
- [DeepEval](https://github.com/confident-ai/deepeval)
