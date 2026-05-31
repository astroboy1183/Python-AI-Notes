---
title: Why Multi-Agent
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 22: Multi-Agent Systems"
tags:
  - multi-agent
  - agents
  - orchestration
  - foundations
related:
  - "[[02 - What are AI Agents]]"
  - "[[02 - Multi-Agent Architectures]]"
---

# Why Multi-Agent

> [!NOTE]
> **TL;DR**
> A single agent (§7) is one LLM with a set of tools and one prompt. As you pile on more tools, more responsibilities, and a giant system prompt, it gets **confused, unreliable, and hard to maintain** — the model has too much to juggle in one context. **Multi-agent systems** decompose the problem into several **specialized agents** that each do one thing well (a researcher, a coder, a reviewer) and **coordinate**. Benefits: **separation of concerns** (each agent has a focused prompt + few tools), **specialization** (better at its narrow job), **modularity** (swap/extend agents independently), and **parallelism** (independent subtasks run concurrently). The costs are real too: more **complexity, latency, token cost** (more LLM calls), and **coordination/error-propagation** risk. Rule of thumb: start with one agent; go multi-agent only when one agent is genuinely overloaded.

> [!NOTE]
> **Where this fits**
> First note of **Section 22: Multi-Agent Systems**. It extends the single-agent loop from [[02 - What are AI Agents]] (§7). Architectures follow in [[02 - Multi-Agent Architectures]].

---

## 1. The limits of one agent

A single agent works great until it has to do **too much**:

```
one agent + 20 tools + 2000-token system prompt covering 6 responsibilities
  → picks the wrong tool, forgets instructions, mixes concerns, hard to debug
```

| Single-agent strain | Symptom |
|---|---|
| Too many tools | Picks wrong tool / ignores some |
| Overloaded prompt | Forgets/conflates instructions |
| Mixed responsibilities | Jack of all trades, master of none |
| One long context | Drifts, loses earlier goals |
| Hard to change | Touching the prompt breaks other behavior |

> [!IMPORTANT]
> **LLMs degrade when overloaded in one context**
> A model given one focused job with a few relevant tools is far more reliable than the same model asked to juggle everything. Multi-agent design is essentially **applying separation of concerns to LLMs** — the same principle that makes modular code better than one giant function.

---

## 2. What a multi-agent system is

Several agents, each **specialized**, that **coordinate** to solve a task one couldn't do well alone:

```
                 ┌── Researcher agent (search tools) ──┐
user task ─► Orchestrator ── Coder agent (file tools) ──┼─► result
                 └── Reviewer agent (no tools, critic) ─┘
```

Each agent = its own focused prompt + its own minimal toolset + its own role. They pass work/messages between each other under some coordination scheme (architectures in note 02).

---

## 3. The benefits

| Benefit | Why it helps |
|---|---|
| **Separation of concerns** | Each agent: focused prompt + few tools → more reliable |
| **Specialization** | A "SQL agent" beats a generalist at SQL |
| **Modularity** | Add/replace/upgrade one agent without touching others |
| **Parallelism** | Independent subtasks run concurrently (faster wall-clock) |
| **Diverse perspectives** | A separate **critic/reviewer** catches the worker's mistakes |
| **Scalability of complexity** | Tackle big workflows by composing small agents |

The **critic pattern** is especially powerful: one agent produces, another (with a fresh, skeptical prompt) reviews — catching errors the producer is blind to (relates to LLM-as-judge, §17).

---

## 4. The costs (don't ignore these)

> [!WARNING]
> **Multi-agent multiplies the failure surface**
> More agents = more LLM calls = more **cost** (§20) and **latency** (§20 — agent latency compounds). Worse, **errors propagate**: if the researcher returns wrong info, the coder builds on it and the reviewer may miss it. Coordination itself can fail (agents talk past each other, loop forever, or deadlock). A multi-agent system is harder to **debug**, **eval** (§17), and **secure** (§19 — more tools, more injection surface).

| Cost | Detail |
|---|---|
| Complexity | More moving parts, harder to reason about |
| Latency | Sequential handoffs add up (§20) |
| Token cost | Many calls + inter-agent messages (§20) |
| Error propagation | One agent's mistake cascades |
| Coordination failure | Loops, talking past each other, deadlock |
| Observability | Need tracing across agents (§17) |

---

## 5. When to go multi-agent (and when not)

> [!TIP]
> **Start single-agent; split only when forced to**
> Reach for multi-agent when **one agent is provably overloaded** — too many distinct tools/responsibilities, a prompt that can't hold it all, or genuinely independent subtasks that benefit from parallelism. Don't add agents for elegance; each one costs latency, tokens, and debugging effort. Many "multi-agent" problems are better solved by a **cleaner single agent** or a **deterministic workflow** (LangGraph, §11) with a few LLM nodes.

```
one focused job, few tools          → single agent (§7)
fixed multi-step pipeline           → LangGraph workflow (§11), maybe 1 agent inside
distinct specialties + coordination → multi-agent (this section)
```

---

## 6. Relationship to LangGraph and agentic RAG

Multi-agent systems are often **built on LangGraph (§11)** — agents become nodes, handoffs become edges, shared state flows between them. And **agentic RAG (§18)** is a mini multi-agent idea (a retriever "agent" serving a reasoning agent). The orchestration skills from §11 are the foundation here.

---

## 7. Main takeaways

- A **single agent overloaded** with tools/responsibilities becomes unreliable and unmaintainable.
- **Multi-agent** = several **specialized** agents that **coordinate**.
- Benefits: **separation of concerns, specialization, modularity, parallelism, critic/review**.
- Costs: **complexity, latency, token cost, error propagation, coordination failure, harder eval/security**.
- The **critic/reviewer** pattern catches the worker's blind spots.
- **Start single-agent**; go multi-agent only when one agent is genuinely overloaded.
- Often built on **LangGraph (§11)**; agentic RAG (§18) is a lightweight example.

---

## 8. Things I still want to figure out

- Concrete signals that an agent is "overloaded" enough to split?
- How much latency/cost does a typical multi-agent setup add vs one agent?
- How to cap inter-agent loops so they don't spiral?

---

## 9. Things to dig into

- **LangGraph multi-agent** patterns (§11).
- **CrewAI, AutoGen, OpenAI Agents SDK** (note 04).
- Anthropic / industry write-ups on multi-agent trade-offs.
- Next: [[02 - Multi-Agent Architectures]].

---

## 10. Next up in this section

- [ ] [[02 - Multi-Agent Architectures]] — how to wire multiple agents together.

---

## Related
- [[02 - What are AI Agents]] — the single-agent baseline.
- [[02 - What is LangGraph]] — the orchestration substrate.

## Sources
- [LangGraph multi-agent](https://langchain-ai.github.io/langgraph/concepts/multi_agent/)
- [Anthropic: building effective agents](https://www.anthropic.com/research/building-effective-agents)
