---
title: Reflection and Self-Critique
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 23: Advanced Reasoning & Prompting"
tags:
  - reasoning
  - reflection
  - reflexion
  - self-critique
  - prompting
related:
  - "[[01 - ReAct - Reasoning and Acting]]"
  - "[[03 - Tree of Thoughts and Search]]"
---

# Reflection and Self-Critique

> [!NOTE]
> **TL;DR**
> LLMs are often better at **critiquing** an answer than producing a perfect one first try — so make them do both. **Reflection** = generate an answer, then have the model (or a separate critic) **evaluate it against criteria**, then **revise** based on that feedback, looping until it's good enough. **Self-refine** is the single-model version (generate → self-critique → improve). **Reflexion** adds **memory of past failures**: after a failed attempt (e.g. a tool/agent task that didn't work), the model writes a reflection on *why*, stores it, and uses it to do better next time. This is essentially **LLM-as-a-judge (§17) turned inward** as an improvement loop, and it pairs naturally with **ReAct (note 01)** — act, observe failure, reflect, retry. The cost is extra LLM calls; the payoff is markedly higher quality on hard tasks.

> [!NOTE]
> **Where this fits**
> Second note of **Section 23**, building self-correction on top of the ReAct loop (note 01). It reuses the judging idea from [[03 - LLM-as-a-Judge]] (§17) as a generation-time mechanism.

---

## 1. The core insight: critiquing is easier than perfecting

A model's first answer is rarely its best. But ask it "**what's wrong with this answer?**" and it often spots real flaws. Reflection exploits this asymmetry:

```
generate → critique → revise → (repeat) → better answer
```

It's the same idea as a human drafting, then editing — the second pass catches what the first missed.

---

## 2. Self-refine (single model)

One model plays both author and editor:

```
1. GENERATE:  produce an initial answer
2. CRITIQUE:  "Review your answer. List specific problems / how to improve."
3. REFINE:    "Now rewrite it, fixing those problems."
4. repeat 2–3 until good enough (or a cap)
```

```python
# conceptual self-refine loop
answer = llm(f"Answer: {question}")
for _ in range(MAX_ROUNDS):
    critique = llm(f"Critique this answer for {criteria}:\n{answer}")
    if "no issues" in critique.lower():
        break
    answer = llm(f"Improve the answer using this critique:\n{critique}\n\n{answer}")
return answer
```

> [!TIP]
> **Give the critique concrete criteria**
> "Is this good?" yields vague self-praise. "Check for: factual errors, missing edge cases, unclear steps, unsafe code" yields actionable critique. Decompose quality into named axes — exactly like a judge rubric (§17). A vague critic barely helps; a specific one drives real improvement.

---

## 3. Separate critic (two roles)

Often better: a **distinct critic** with a fresh, skeptical prompt (and ideally a different model) reviews the author's output — avoiding the author's blind spots and self-preference (the bias from §17).

```
Author agent → answer → Critic agent (skeptical) → feedback → Author revises
```

This is the **critic pattern** from multi-agent systems (§22) applied as a reasoning technique. A separate critic is generally more honest than self-critique.

---

## 4. Reflexion — learning from failure

**Reflexion** extends reflection with **memory across attempts**, for agentic/tool tasks (note 01):

```
attempt task (ReAct) → FAIL
   ▼
reflect: "Why did it fail? What should I do differently?"
   ▼
store the reflection in memory
   ▼
retry the task WITH the reflection in context → more likely to succeed
```

> [!IMPORTANT]
> **Reflexion = verbal self-improvement without retraining**
> Instead of updating weights (fine-tuning, §21), Reflexion improves behavior by **writing lessons from failures into the context** for the next attempt. It turns a failed trajectory into useful guidance — a cheap, training-free way to get better at a task over repeated tries. Especially powerful for agents that can *check* success (code that runs, a task that completes).

---

## 5. When reflection pays (and when it doesn't)

| Pays off | Marginal |
|---|---|
| Hard reasoning / math / planning | Simple factual lookups |
| Code generation (critique → fix bugs) | One-shot trivial tasks |
| High-stakes outputs worth the extra calls | Latency-critical paths |
| Tasks with a **checkable** success signal (Reflexion) | Tasks with no clear success criterion |

> [!WARNING]
> **Reflection multiplies cost and latency**
> Each round is more LLM calls (§20) and more latency (§20). Use a **round cap** and stop when the critique says "good" or improvement plateaus. Reflection on every trivial request is wasteful; reserve it for outputs where quality justifies the extra spend. Also: a weak critic can make things *worse* (revising a correct answer into a wrong one) — validate with eval (§17).

---

## 6. Relationship to the rest

```
ReAct (note 01)      → reflection adds a self-correction loop around acting
LLM-as-judge (§17)   → the critique mechanism, used at generation time
multi-agent critic (§22) → the separate-critic version, as an agent
Tree of Thoughts (note 03) → explores many paths; reflection improves one path
```

Reflection is the "try, check, improve" loop; note 03 is the "explore many options" complement.

---

## 7. Main takeaways

- LLMs **critique better than they perfect first try** → generate, critique, revise.
- **Self-refine**: one model authors and edits in a loop.
- **Separate critic** (fresh/different model) avoids the author's blind spots — usually better.
- Give the critic **concrete criteria** (rubric), not "is this good?".
- **Reflexion**: store **reflections on failures** in memory and retry — verbal self-improvement, no retraining.
- Best for **hard reasoning, code, high-stakes**, or tasks with a **checkable** success signal.
- Costs extra **calls + latency** — cap rounds; a **weak critic can hurt** (eval it, §17).
- It's **LLM-as-judge (§17) turned inward**, layered on **ReAct (note 01)**.

---

## 8. Things I still want to figure out

- Self-critique vs separate-critic — how big is the quality gap in practice?
- How many refine rounds before diminishing returns?
- Detecting when a revision made the answer *worse*?

---

## 9. Things to dig into

- **Self-Refine** and **Reflexion** papers.
- **Chain-of-Verification (CoVe)** (§19 hallucination) as a reflection variant.
- LangGraph reflection loops (§11) + the multi-agent critic (§22).
- Next: [[03 - Tree of Thoughts and Search]].

---

## 10. Next up in this section

- [ ] [[03 - Tree of Thoughts and Search]] — explore *multiple* reasoning paths, not just refine one.

---

## Related
- [[01 - ReAct - Reasoning and Acting]] — the loop reflection wraps.
- [[03 - LLM-as-a-Judge]] — the critique mechanism (§17).

## Sources
- [Self-Refine paper](https://arxiv.org/abs/2303.17651)
- [Reflexion paper](https://arxiv.org/abs/2303.11366)
