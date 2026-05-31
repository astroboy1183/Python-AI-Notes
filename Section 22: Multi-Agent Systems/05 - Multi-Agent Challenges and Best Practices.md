---
title: Multi-Agent Challenges and Best Practices
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 22: Multi-Agent Systems"
tags:
  - multi-agent
  - best-practices
  - reliability
  - evaluation
related:
  - "[[04 - Multi-Agent Frameworks]]"
  - "[[01 - Why Multi-Agent]]"
---

# Multi-Agent Challenges and Best Practices

> [!NOTE]
> **TL;DR**
> Multi-agent systems fail in characteristic ways: **error propagation** (one agent's mistake cascades), **runaway loops/cost** (agents hand off forever), **coordination breakdown** (agents talk past each other or duplicate work), **context loss** (info doesn't survive handoffs), **latency** (sequential hops add up), and **debuggability** (hard to tell which agent broke). Best practices counter each: keep agents **narrow and specialized**, pass **focused context** with clear **termination** conditions and **recursion/budget caps**, add a **critic/reviewer** to catch errors early, **trace everything** (§17) to localize failures, **evaluate the whole system *and* each agent**, and — most importantly — **don't go multi-agent unless a single agent genuinely can't cope**. The meta-lesson of the section: multi-agent is powerful but expensive and fragile; reach for the **simplest design that works**.

> [!NOTE]
> **Where this fits**
> Final note of **Section 22**. It collects the failure modes hinted throughout and pulls in evaluation (§17), cost/latency (§20), and security (§19) as the disciplines that keep multi-agent systems sane.

---

## 1. The characteristic failure modes

| Failure | What happens | Root cause |
|---|---|---|
| **Error propagation** | Agent A's wrong output → B builds on it → bad result | No verification between steps |
| **Runaway loops** | A→B→A→B... never stops | No termination / cap (note 03) |
| **Cost explosion** | Many agents × many calls × big contexts | More agents = more tokens (§20) |
| **Coordination breakdown** | Agents duplicate, conflict, or talk past each other | Unclear roles / shared goal |
| **Context loss** | Receiving agent lacks needed info | Bad handoff context (note 03) |
| **Latency** | Sequential handoffs stack up | Compounding round-trips (§20) |
| **Debuggability** | "Which agent caused this?" | No cross-agent tracing |

> [!WARNING]
> **Error propagation is the silent killer**
> In a chain, a small early error gets amplified downstream and is easy to miss because each agent *sounds* confident (hallucination, §19). A research agent that fabricates a fact poisons everything built on it. Without verification steps, multi-agent systems can be **confidently, compoundingly wrong**.

---

## 2. Best practices (mapped to the failures)

### Keep agents narrow
Each agent: a **focused role**, a **tight prompt**, and the **minimum tools** it needs. This is the whole reason to go multi-agent ([[01 - Why Multi-Agent]]) — don't recreate the overloaded single agent inside each node.

### Pass focused context
Hand over **what the next agent needs** (task + relevant inputs + summary), not full transcripts (note 03). Less bloat, less confusion, lower cost.

### Define termination + caps
Always set a **clear "done" condition**, a **recursion/iteration limit**, and ideally a **budget cap** (§20). The supervisor should own done-ness.

### Add a critic
A dedicated **reviewer/verifier** agent (fresh, skeptical prompt) checks workers' output before it propagates — the cheapest defense against error cascades (relates to LLM-as-judge, §17).

### Trace everything
Use observability (§17) to capture **every agent's** inputs/outputs/tool calls. When something breaks, the trace shows **which agent** and **which step** — otherwise debugging is hopeless.

### Evaluate at two levels
- **End-to-end**: did the *system* solve the task? (§17)
- **Per-agent**: is each agent good at its narrow job? (eval each in isolation)

A system can fail because one agent is weak — per-agent eval localizes that.

### Secure the expanded surface
More agents + more tools = more **prompt-injection** and **excessive-agency** surface (§19). Apply least privilege per agent; gate high-impact actions with human approval.

---

## 3. The cost/latency reality check

> [!IMPORTANT]
> **Multi-agent is expensive — justify it**
> A supervisor + 3 workers + a reviewer might be **5–10× the LLM calls** of a single agent for one task (§20). That's real money and real latency. Before committing, ask: does a **cleaner single agent** or a **deterministic LangGraph workflow** (§11) with one or two LLM nodes solve it? Often yes. Multi-agent should buy enough quality/capability to outweigh its multiplied cost.

---

## 4. The simplicity ladder (the meta-lesson)

```
1. single LLM call            → does a good prompt do it?
2. single agent + tools (§7)  → does one agent with the right tools do it?
3. deterministic workflow (§11) → fixed steps? use a graph with LLM nodes
4. multi-agent (this section) → genuinely needs specialists + coordination
```

> [!TIP]
> **Climb the ladder; stop at the first rung that works**
> Each rung adds power *and* complexity/cost/fragility. The best multi-agent system is often the one you **didn't** build because a simpler design sufficed. Reserve multi-agent for problems that truly need it — and even then, keep it as structured (supervisor/pipeline) as possible.

---

## 5. A pre-flight checklist

Before shipping a multi-agent system:
- [ ] Is each agent **narrow** (focused prompt, minimal tools)?
- [ ] Is **context passed** focused, not full transcripts?
- [ ] Is there a **termination condition** + recursion/budget cap?
- [ ] Is there a **critic/verification** step against error propagation?
- [ ] Is **every agent traced** (§17) for debugging?
- [ ] Is it evaluated **end-to-end and per-agent** (§17)?
- [ ] Is the expanded **tool/injection surface secured** (§19, least privilege)?
- [ ] Did I confirm a **simpler design** wouldn't do (the ladder)?

---

## 6. Main takeaways

- Failure modes: **error propagation, runaway loops, cost explosion, coordination breakdown, context loss, latency, debuggability**.
- **Error propagation** is the silent killer — early mistakes amplify; add **verification**.
- Best practices: **narrow agents, focused context, termination + caps, a critic, trace everything, eval end-to-end + per-agent, secure the surface**.
- Multi-agent can be **5–10× the cost/latency** of one agent — **justify it**.
- Climb the **simplicity ladder** (call → agent → workflow → multi-agent); stop at the first rung that works.
- The best multi-agent system is often the one you **didn't need to build**.

---

## 7. Things I still want to figure out

- Cheapest effective **verification/critic** placement in a pipeline?
- Auto-detecting "no progress" to break loops?
- Per-agent eval harness design (§17) for a multi-agent system?

---

## 8. Things to dig into

- Anthropic **"building effective agents"** (workflows vs agents, simplicity).
- Failure-analysis write-ups on multi-agent systems.
- Cross-links: eval (§17), cost/latency (§20), security (§19).

---

## 9. Section wrap-up

Section 22 covers **multi-agent systems**: why split a single agent ([[01 - Why Multi-Agent]]), the **architectures** (supervisor/pipeline/hierarchical/network), **handoffs & communication**, the **frameworks** (LangGraph/CrewAI/AutoGen/Agents SDK), and the **challenges + best practices** here. The throughline: specialization and coordination unlock harder tasks, but only pay off with focused agents, disciplined handoffs, verification, tracing, eval, and the restraint to keep things as simple as the problem allows.

---

## Related
- [[01 - Why Multi-Agent]] — the cost/benefit framing this reinforces.
- [[04 - Multi-Agent Frameworks]] — the tools these practices apply to.
- [[05 - Tracing and Observability]] — essential for multi-agent debugging.

## Sources
- [Anthropic: building effective agents](https://www.anthropic.com/research/building-effective-agents)
- [LangGraph multi-agent](https://langchain-ai.github.io/langgraph/concepts/multi_agent/)
