---
title: Tree of Thoughts and Search
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 23: Advanced Reasoning & Prompting"
tags:
  - reasoning
  - tree-of-thoughts
  - self-consistency
  - search
  - prompting
related:
  - "[[02 - Reflection and Self-Critique]]"
  - "[[06 - Chain of Thought Prompting]]"
---

# Tree of Thoughts and Search

> [!NOTE]
> **TL;DR**
> Chain-of-thought (§3) follows **one** reasoning path — if it goes wrong early, the answer is wrong. **Search-based reasoning** explores **multiple** paths and picks the best. **Self-consistency** is the simple version: sample several independent CoT chains, then take a **majority vote** on the answer (different reasoning, same answer → high confidence). **Tree of Thoughts (ToT)** is the powerful version: treat reasoning as a **tree** of partial "thoughts," **evaluate** each branch, **explore** promising ones and **prune/backtrack** on dead ends — i.e., apply classic search (BFS/DFS) to reasoning steps. **Graph of Thoughts** generalizes further. These dramatically help on problems with **search structure** (puzzles, planning, math) but cost **many** LLM calls — so they're worth it only for hard problems where one-shot CoT fails.

> [!NOTE]
> **Where this fits**
> Third note of **Section 23**. Where reflection (note 02) **improves one** path, this **explores many** paths. Both extend CoT (§3).

---

## 1. The limit of single-path reasoning

```
CoT:  Q → step1 → step2 → step3 → A     (one path; an early wrong step dooms it)
```

A single chain commits to one line of thought. If step 1 takes a wrong turn, every later step builds on the mistake. For problems with many possible approaches, exploring **only one** is fragile.

---

## 2. Self-consistency — sample and vote

The cheapest upgrade: run CoT **several times** (with temperature > 0 for diversity), then **majority-vote** the final answers.

```
Q ─┬─ chain A → answer: 42
   ├─ chain B → answer: 42
   ├─ chain C → answer: 17
   └─ chain D → answer: 42
   → majority = 42  (3/4 agree → confident)
```

> [!TIP]
> **Agreement across diverse reasoning ≈ confidence**
> Different valid reasoning paths converging on the same answer is strong evidence it's right; wide disagreement signals the model is unsure (also a hallucination signal, §19). Self-consistency needs no special structure — just sample N and vote — making it the easiest reliability boost for reasoning tasks. Cost = N× the calls.

---

## 3. Tree of Thoughts (ToT)

ToT treats reasoning as a **search tree**:

```
                      [problem]
                     /    |     \
              thought1  thought2  thought3      ← generate candidate next steps
                |          |  (evaluate each: promising? dead end?)
            thought1a   thought2a               ← expand promising branches
                |          | (prune bad branches, backtrack)
             ...        solution                ← continue until solved
```

The loop, per node:
1. **Generate** several candidate "next thoughts" (possible next reasoning steps).
2. **Evaluate** each (the model rates how promising each partial path is — self-evaluation, like a judge §17).
3. **Search**: expand the promising branches (BFS/DFS), **prune** dead ends, **backtrack** when stuck.
4. Repeat until a solution emerges.

> [!IMPORTANT]
> **ToT = classic search applied to reasoning steps**
> Instead of one greedy chain, ToT does deliberate **exploration with backtracking** — the way a human tackles a puzzle (try an approach, hit a wall, back up, try another). It uses the LLM both to **propose** steps and to **evaluate** them. This shines on problems with real search structure (games, planning, constraint puzzles, hard math) where the first idea often fails.

---

## 4. Graph of Thoughts (and beyond)

**Graph of Thoughts** generalizes the tree to a **graph** — thoughts can **merge** (combine partial results) and form arbitrary dependencies, not just branch. More expressive for problems where sub-solutions recombine. Same core idea: structured exploration + evaluation over reasoning units, just a richer topology.

---

## 5. The cost reality

| Method | Relative calls | When worth it |
|---|---|---|
| CoT (§3) | 1× | default reasoning |
| Self-consistency | N× (e.g. 5–40×) | moderate-hard, want reliability |
| Tree of Thoughts | many× (generate + evaluate per node) | **hard** search-structured problems |
| Graph of Thoughts | most | research / complex combinatorial tasks |

> [!WARNING]
> **These are expensive — reserve them for hard problems**
> ToT can cost **orders of magnitude** more calls than a single CoT (§20). It's not for everyday queries. Use it only when (a) the problem has genuine search structure and (b) one-shot CoT demonstrably fails (verify with eval, §17). For most tasks, CoT or self-consistency is the right cost/quality point. Also note: powerful **reasoning models** (note 04) now do much of this *internally*, often making external ToT unnecessary.

---

## 6. Choosing a reasoning strategy

```
simple task            → direct answer
needs reasoning        → chain-of-thought (§3)
want more reliability  → self-consistency (sample + vote)
improve a draft        → reflection (note 02)
hard, search-structured→ Tree / Graph of Thoughts
already have a reasoning model → let it reason internally (note 04)
```

---

## 7. Main takeaways

- CoT follows **one** path — fragile if it goes wrong early.
- **Self-consistency**: sample N CoT chains, **majority vote** — agreement ≈ confidence; cheapest reliability boost.
- **Tree of Thoughts (ToT)**: reasoning as a **search tree** — generate candidate thoughts, **evaluate**, **explore/prune/backtrack**.
- ToT = **classic search applied to reasoning**, using the LLM to propose *and* evaluate steps.
- **Graph of Thoughts** generalizes to merging/recombining thoughts.
- These help most on **search-structured** problems (puzzles, planning, hard math).
- They cost **many** calls (§20) — reserve for hard problems where CoT fails.
- Modern **reasoning models** (note 04) do much of this internally.

---

## 8. Things I still want to figure out

- How many samples for self-consistency before diminishing returns?
- How reliable is the LLM's **self-evaluation** of branches in ToT?
- When do reasoning models (note 04) make external ToT obsolete?

---

## 9. Things to dig into

- **Self-Consistency**, **Tree of Thoughts**, **Graph of Thoughts** papers.
- LangGraph (§11) as a substrate for implementing search/branching.
- Next: [[04 - Reasoning Models]].

---

## 10. Next up in this section

- [ ] [[04 - Reasoning Models]] — models that do this kind of deliberate reasoning built-in.

---

## Related
- [[02 - Reflection and Self-Critique]] — improve one path (vs explore many here).
- [[06 - Chain of Thought Prompting]] — the single-path baseline.

## Sources
- [Self-Consistency paper](https://arxiv.org/abs/2203.11171)
- [Tree of Thoughts paper](https://arxiv.org/abs/2305.10601)
