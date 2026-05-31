---
title: Programmatic Prompting with DSPy
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 23: Advanced Reasoning & Prompting"
tags:
  - prompting
  - dspy
  - optimization
  - reasoning
related:
  - "[[04 - Reasoning Models]]"
  - "[[01 - Why Evaluation Matters]]"
---

# Programmatic Prompting with DSPy

> [!NOTE]
> **TL;DR**
> Hand-tuning prompts ("prompt engineering") is brittle — you tweak wording by trial and error, and a model change can break it. **DSPy** reframes prompting as **programming**: you declare *what* you want as **signatures** (typed input→output specs) and compose **modules** (e.g. a CoT module), then a DSPy **optimizer (compiler)** automatically **generates and tunes the actual prompts** — picking instructions and few-shot examples — to maximize a **metric** on your training examples. So instead of you crafting the string, you specify the task + a metric + some data, and DSPy *optimizes the prompt for you*. This connects directly to evaluation (§17): DSPy needs a metric to optimize against, which is exactly the eval discipline. It's especially valuable for **pipelines** (multi-step) where hand-tuning every prompt is intractable, and for **portability** (re-compile when you switch models).

> [!NOTE]
> **Where this fits**
> Final note of **Section 23**. It's the "stop hand-writing prompts" idea, and it depends on having a **metric/eval** (§17). It complements reasoning models (note 04) — you can optimize prompts *for* any model.

---

## 1. The problem with manual prompt engineering

```
write prompt → eyeball outputs → tweak wording → repeat (forever)
   → brittle: works for a few cases, breaks on others
   → fragile: a model upgrade can silently degrade it
   → unscalable: a 5-step pipeline = 5 prompts to hand-tune in concert
```

Manual prompting is **craft, not engineering** — hard to reproduce, optimize, or maintain. DSPy makes it systematic.

---

## 2. DSPy's reframe: declare, don't write

> [!IMPORTANT]
> **Specify the task and a metric; let DSPy write the prompt**
> The shift: you stop authoring the prompt **string** and instead declare the **task** (typed inputs → outputs) and a **metric** for success. DSPy's optimizer then searches for the prompt (instructions + few-shot examples) that maximizes that metric on your data — analogous to how you don't hand-tune neural net weights, you let an optimizer do it. Prompts become a *compiled artifact*, not a hand-crafted one.

```
you provide:   signature (what) + module (how, abstractly) + metric + examples
DSPy produces: an optimized prompt (instructions + selected few-shot) that scores well
```

---

## 3. The building blocks

| Concept | What it is |
|---|---|
| **Signature** | A typed spec of the task: `"question -> answer"`, `"context, question -> answer"` |
| **Module** | A reusable strategy: `Predict`, `ChainOfThought`, `ReAct` (note 01), etc. |
| **Optimizer (compiler)** | Searches instructions/few-shot to maximize the metric (e.g. bootstrapping examples) |
| **Metric** | How an output is scored (exact match, judge, custom) — from §17 |

```python
# conceptual DSPy
import dspy

class QA(dspy.Signature):
    """Answer the question using the context."""
    context = dspy.InputField()
    question = dspy.InputField()
    answer = dspy.OutputField()

program = dspy.ChainOfThought(QA)          # module wrapping the signature

optimized = optimizer.compile(             # optimizer tunes the prompt
    program, trainset=examples, metric=my_metric,
)
optimized(context=..., question=...)       # uses the optimized prompt
```

You wrote **no prompt string** — DSPy generated and tuned it from the signature, module, metric, and examples.

---

## 4. Why this matters for pipelines

Multi-step LLM programs (RAG, agents, multi-step reasoning) have **many** prompts that must work together. Hand-tuning them jointly is intractable — improving one can break another.

> [!TIP]
> **DSPy optimizes the whole pipeline, jointly**
> Because the pipeline is expressed as composed modules with one end-to-end metric, the optimizer tunes **all** the prompts toward the final objective at once — something manual prompting can't do well. This is the strongest argument for DSPy: complex, multi-step systems where prompt interactions matter.

---

## 5. Portability across models

A hand-tuned prompt is often **overfit to one model's quirks** — switch from GPT to Gemini/Claude (or to a reasoning model, note 04) and it may degrade. With DSPy, you **re-compile** the same program against the new model: the optimizer re-tunes the prompts for that model automatically. The *program* (signatures + modules + metric) is portable; the prompts are regenerated.

```
same DSPy program ──compile──► prompts tuned for GPT
                  ──compile──► prompts tuned for Gemini
                  ──compile──► prompts tuned for a local model (§5)
```

---

## 6. The dependency: you need a metric (and data)

> [!WARNING]
> **No metric, no optimization**
> DSPy can only optimize toward something measurable. It **requires** a metric and some training/validation examples — i.e., it sits squarely on the **evaluation discipline (§17)**. This is a feature: it forces you to define success precisely. But it means DSPy isn't a magic "make my prompt better" button — you must bring the eval. Garbage metric → garbage optimization.

---

## 7. When to use it

| Good fit | Overkill |
|---|---|
| Multi-step pipelines (RAG, agents) | A single simple prompt |
| You have/ can build eval data + metric (§17) | No way to measure success |
| Need to support **multiple models** | Locked to one model, simple task |
| Prompt tuning has become a maintenance burden | Quick prototype |

For a one-off simple prompt, hand-writing is fine. DSPy earns its keep on **complex, measurable, evolving** systems.

---

## 8. Main takeaways

- Manual **prompt engineering** is brittle, fragile to model changes, and unscalable for pipelines.
- **DSPy** reframes prompting as **programming**: declare **signatures** + compose **modules**, then an **optimizer** generates/tunes the actual prompts.
- You provide **task + metric + examples**; DSPy produces an **optimized prompt** — you don't write the string.
- Its superpower is **jointly optimizing multi-step pipelines** toward one end-to-end metric.
- **Portable**: re-compile to retune prompts when you **switch models** (incl. reasoning models, note 04).
- It **requires a metric + data** — it depends on the **eval discipline (§17)**.
- Best for **complex, measurable, multi-model** systems; overkill for a single simple prompt.

---

## 9. Things I still want to figure out

- Which DSPy **optimizer** to use for a given size of data?
- How much eval data is needed for DSPy to improve over a hand prompt?
- Does DSPy help with **reasoning models** (note 04), or is light prompting enough there?

---

## 10. Things to dig into

- **DSPy** docs + optimizers (bootstrap few-shot, instruction optimization).
- Building the **metric** (§17) DSPy optimizes against.
- Comparing a DSPy-compiled prompt vs a hand-tuned one on your eval.

---

## 11. Section wrap-up

Section 23 covers **advanced reasoning & prompting**: the **ReAct** loop behind agents (note 01), **reflection/self-critique** to improve answers (note 02), **search-based reasoning** (ToT/self-consistency, note 03), the rise of built-in **reasoning models** (note 04), and **programmatic prompt optimization** with DSPy (this note). The arc: reasoning moved from *prompt tricks you apply* → *capabilities baked into models* → *prompts you optimize with data and metrics* — all underpinned by **evaluation (§17)**.

---

## Related
- [[04 - Reasoning Models]] — DSPy can optimize prompts for any model.
- [[01 - Why Evaluation Matters]] — the metric DSPy needs.
- [[01 - ReAct - Reasoning and Acting]] — available as a DSPy module.

## Sources
- [DSPy](https://dspy.ai/)
- [DSPy paper](https://arxiv.org/abs/2310.03714)
