---
title: Reasoning Models
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 23: Advanced Reasoning & Prompting"
tags:
  - reasoning
  - reasoning-models
  - test-time-compute
  - prompting
related:
  - "[[03 - Tree of Thoughts and Search]]"
  - "[[06 - Chain of Thought Prompting]]"
---

# Reasoning Models

> [!NOTE]
> **TL;DR**
> A major recent shift: **reasoning models** (e.g. the OpenAI o-series, and "thinking" modes in other frontier models) are trained to **reason internally before answering** — they spend extra **test-time compute** generating a long hidden chain of thought, exploring and self-correcting, then output a final answer. In effect, the CoT/reflection/search techniques from notes 01–03 are **baked into the model** rather than prompted by you. This changes how you prompt them: **don't** add "think step by step" or few-shot CoT (they already reason, and it can hurt); instead give clear goals and constraints and **let them think**. The trade-off: reasoning models are **slower and more expensive** (you pay for the hidden "thinking" tokens) but far better at hard math, coding, planning, and logic. The new skill is **choosing**: a fast standard model for most tasks, a reasoning model for genuinely hard ones.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 23**. It's the "the model now does notes 01–03 for you" development — and it updates the prompting habits from §3 for this model class.

---

## 1. What a reasoning model is

A standard LLM answers in one pass — it predicts the answer tokens directly. A **reasoning model** is trained (often via RL on problems with verifiable answers) to first produce a long internal **reasoning trace** — trying approaches, checking itself, backtracking — and *then* give a polished answer.

```
standard model:   question → answer            (fast, one pass)
reasoning model:  question → [long hidden reasoning...] → answer   (slow, deliberate)
```

The hidden reasoning is the model doing — internally and automatically — the kind of deliberate thinking that ToT/self-consistency/reflection do externally (notes 01–03).

---

## 2. Test-time compute — paying to think

> [!IMPORTANT]
> **More thinking at inference = better answers (a new scaling axis)**
> The key idea is **test-time (inference-time) compute**: letting the model generate *more* reasoning tokens before answering reliably improves results on hard problems. It's a different lever from making the model bigger — you spend more compute *per query* instead. Some models even expose a **reasoning effort** setting (low/medium/high) that trades more thinking (better, slower, costlier) against less.

```
more reasoning tokens spent  →  higher accuracy on hard tasks  →  more cost + latency
```

---

## 3. How prompting changes

This is the practical part — reasoning models **invert** some §3 habits:

| §3 habit (standard models) | With reasoning models |
|---|---|
| "Let's think step by step" | **Don't** — they already reason; it's redundant/harmful |
| Few-shot CoT exemplars | Often **unnecessary** or counterproductive; zero-shot is fine |
| Decompose the problem for the model | **Let the model decompose** it |
| Detailed how-to instructions | Give the **goal + constraints**; trust its reasoning |

> [!TIP]
> **Reasoning models prefer "what," standard models need "how"**
> With a standard model you scaffold the *how* (CoT, examples, steps). With a reasoning model, over-scaffolding can interfere — state the **objective and constraints clearly** and let it work. Keep prompts clean and goal-oriented; reserve heavy prompt engineering for non-reasoning models.

---

## 4. When to use which

| Use a reasoning model | Use a standard model |
|---|---|
| Hard **math**, **logic**, **planning** | Simple Q&A, chat, extraction |
| Complex **coding** / debugging | Formatting, classification, routing |
| Multi-step problems needing deliberation | Latency-sensitive paths |
| Quality matters more than speed/cost | High-volume, cost-sensitive tasks |

> [!WARNING]
> **Reasoning models are slower and pricier — don't default to them**
> You pay (in tokens, latency, money) for all those hidden thinking tokens. Using one for "summarize this email" is wasteful overkill. The new core skill is **routing** (§20): send hard problems to the reasoning model, everything else to a fast standard model. Match the model to the task's difficulty.

---

## 5. Relationship to notes 01–03

```
note 01 ReAct        → reasoning models still use tools; reasoning happens around actions
note 02 Reflection   → built-in: they self-correct during the hidden trace
note 03 ToT/search   → built-in: they explore/backtrack internally
note 04 (this)       → the model does the above for you; you just set the goal
```

External techniques (notes 01–03) aren't obsolete — they still help standard models, and ReAct/tools still matter for reasoning models that need real-world data — but a reasoning model often makes **external** self-consistency/ToT unnecessary for pure reasoning.

---

## 6. Caveats

- **Cost/latency** (covered) — the main downside.
- **Hidden reasoning** isn't always shown (or is summarized) — less transparency.
- **Not always better** — for easy tasks they can over-think; for knowledge-gaps they still need RAG (§8) and can still hallucinate (§19).
- The space moves fast — specific model names/limits change; the **concepts** (internal reasoning, test-time compute, lighter prompting) are the durable part.

---

## 7. Main takeaways

- **Reasoning models** reason **internally** before answering — CoT/reflection/search **baked in**.
- They spend extra **test-time compute** (hidden reasoning tokens) → better on hard tasks; some expose a **reasoning effort** knob.
- **Prompt them differently**: *don't* add "step by step"/few-shot CoT; give **clear goals + constraints** and let them think.
- Use for **hard math/logic/planning/coding**; use **standard models** for simple/cheap/fast tasks.
- They're **slower + costlier** — **route** (§20), don't default to them.
- External notes 01–03 still help standard models; reasoning models often make external ToT/self-consistency unnecessary.
- Concepts are durable; specific model names change fast.

---

## 8. Things I still want to figure out

- How to decide the **reasoning effort** level per task?
- Cost/latency multiplier vs standard models in practice?
- Do reasoning models still benefit from **self-consistency**, or is it redundant?

---

## 9. Things to dig into

- OpenAI **reasoning models** guide (o-series, prompting advice).
- "**Let's Verify Step by Step**" / process-reward reasoning research.
- Test-time compute scaling discussions.
- Next: [[05 - Programmatic Prompting with DSPy]].

---

## 10. Next up in this section

- [ ] [[05 - Programmatic Prompting with DSPy]] — stop hand-tuning prompts; optimize them programmatically.

---

## Related
- [[03 - Tree of Thoughts and Search]] — external search the model now does internally.
- [[06 - Chain of Thought Prompting]] — the habit reasoning models invert.
- [[05 - Model Routing and Optimization Strategies]] — routing hard tasks to reasoning models.

## Sources
- [OpenAI reasoning models guide](https://platform.openai.com/docs/guides/reasoning)
- [Let's Verify Step by Step](https://arxiv.org/abs/2305.20050)
