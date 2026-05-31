---
title: Why Evaluation Matters
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 17: Evaluation & Observability"
tags:
  - evaluation
  - llmops
  - testing
  - foundations
related:
  - "[[02 - Evaluation Methods and Metrics]]"
  - "[[03 - LLM-as-a-Judge]]"
---

# Why Evaluation Matters

> [!NOTE]
> **TL;DR**
> Once an LLM app leaves the demo stage, the hardest question stops being "can I build it?" and becomes "**is it actually any good, and did my last change make it better or worse?**" LLMs are **non-deterministic** and **open-ended**, so I can't rely on the exact-match assertions normal software uses. Without evaluation, every prompt tweak, model swap, or RAG change is a **guess** — I'm flying blind. Evaluation turns subjective "feels better" into **measurable signal**: a fixed test set, defined metrics, and a score I can track over time. This is the discipline that separates a hobby demo from a shippable, maintainable AI product, and it's the foundation everything else in this section builds on.

> [!NOTE]
> **Where this fits**
> First note of **Section 17: Evaluation & Observability** — the gap-fill section that follows the course proper. It motivates *why* eval is non-negotiable; [[02 - Evaluation Methods and Metrics]] covers the *how*.

---

## 1. The core problem: LLMs aren't normal software

Traditional software is deterministic — given input X, function `f` returns exactly Y, every time. I test it with `assert f(2, 3) == 5`.

LLMs break that model:

| Property | Normal code | LLM |
|---|---|---|
| Determinism | Same input → same output | Same input → **different** outputs (temperature, sampling) |
| Correctness | One right answer | Many acceptable answers (and many subtly wrong ones) |
| Failure mode | Crash / exception | **Plausible-sounding but wrong** (the dangerous one) |
| Testing | Exact-match asserts | Needs semantic / judgment-based scoring |

```
assert summarize(article) == "..."   ← impossible: no single correct summary
```

So I need a different kind of testing — one that tolerates variation while still catching regressions.

---

## 2. What goes wrong without evaluation

> [!WARNING]
> **"Vibes-based" development doesn't scale**
> Early on, I judge quality by eyeballing a few outputs. That works for 5 examples and fails for 500. Symptoms of no eval:
> - A prompt change fixes one case and **silently breaks three others** I didn't re-check.
> - Swapping to a cheaper model "seems fine" — until users hit the cases where it isn't.
> - I can't answer "is v2 better than v1?" with anything but opinion.
> - Regressions ship to production and I find out from **user complaints**.

Evaluation replaces "I think it's better" with "**accuracy went from 71% → 84% on the 200-case test set.**"

---

## 3. The mental model: eval is the test suite for AI

Just as unit tests guard normal code against regressions, an **eval suite** guards an LLM app:

```
code change ─► run unit tests ─► pass/fail        (normal software)
prompt change ─► run eval suite ─► score 0.84     (LLM software)
```

Every prompt edit, model upgrade, RAG tweak, or temperature change should be **run against the eval set** before shipping. The score is the gate.

---

## 4. The three things every eval needs

| Ingredient | What it is | Example |
|---|---|---|
| **Dataset** | Fixed inputs (+ ideally reference outputs) | 200 real user questions with expected answers |
| **Metric** | How a single output is scored | exact match, similarity, LLM-judge rating, faithfulness |
| **Target** | The system under test | a prompt, a chain, an agent, a RAG pipeline |

Run the target over the dataset, score each output with the metric, aggregate → one number (or a few) I can compare across versions.

---

## 5. Offline vs online evaluation

Two complementary modes — I need both:

| | Offline eval | Online eval |
|---|---|---|
| When | Before shipping (CI, dev) | In production, on live traffic |
| Data | Fixed curated test set | Real user interactions |
| Purpose | Catch regressions pre-release | Measure real-world quality, drift |
| Signal | Score vs baseline | User feedback (👍/👎), implicit signals, sampled judging |

```
dev:  change → OFFLINE eval (fixed set) → ship if score holds
prod: live traffic → ONLINE eval (feedback + sampling) → feed failures back into the test set
```

> [!TIP]
> **Production failures are free test cases**
> The best eval datasets grow from real failures. When something goes wrong in production (online), add it to the offline test set so it's guarded forever. The two loops feed each other.

---

## 6. Where this connects to what I've built

Everything earlier in the course is now *testable*:

- **Prompting (§3–4):** which prompt actually performs best? Eval decides.
- **Agents (§7):** does the agent call the right tools and finish the task? Eval the trajectory.
- **RAG (§8–9):** is retrieval pulling the right context, and is the answer faithful? (Dedicated RAG eval in [[04 - Evaluating RAG with RAGAS]].)
- **Model choice / cost (§20):** can a cheaper model hold quality? Only eval can tell.

---

## 7. Main takeaways

- LLMs are **non-deterministic and open-ended** — exact-match testing doesn't apply.
- Without eval, every change is a **guess**; regressions ship silently.
- Eval = the **test suite for AI**: run changes against it before shipping.
- Three ingredients: a **dataset**, a **metric**, and the **target** system.
- Need both **offline** (curated set, pre-ship) and **online** (live traffic, feedback) eval.
- **Production failures** should be folded back into the offline test set.
- Eval makes "it feels better" into "the score went up."

---

## 8. Things I still want to figure out

- How big should a test set be to be **statistically meaningful**?
- How to handle metrics that **disagree** (one says better, another worse)?
- How much does eval **cost** when metrics themselves call an LLM (judges)?
- How to keep a test set from going **stale** as the product evolves?

---

## 9. Things to dig into

- **OpenAI Evals** framework: https://github.com/openai/evals
- **LangSmith / Langfuse** evaluation features (see [[05 - Tracing and Observability]]).
- **Hugging Face Evaluate** library.
- The eval methods and metrics catalog → [[02 - Evaluation Methods and Metrics]].

---

## 10. Next up in this section

- [ ] [[02 - Evaluation Methods and Metrics]] — the concrete ways to score LLM outputs.

---

## Related
- [[02 - Evaluation Methods and Metrics]] — how to actually score outputs.
- [[03 - LLM-as-a-Judge]] — using an LLM to grade open-ended answers.

## Sources
- [OpenAI Evals](https://github.com/openai/evals)
- [Hugging Face Evaluate](https://huggingface.co/docs/evaluate/)
