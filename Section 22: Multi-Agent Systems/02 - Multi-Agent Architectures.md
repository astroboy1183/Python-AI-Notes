---
title: Multi-Agent Architectures
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 22: Multi-Agent Systems"
tags:
  - multi-agent
  - architecture
  - orchestration
  - langgraph
related:
  - "[[01 - Why Multi-Agent]]"
  - "[[03 - Agent Communication and Handoffs]]"
---

# Multi-Agent Architectures

> [!NOTE]
> **TL;DR**
> There are a few standard ways to wire multiple agents together. **Network (peer-to-peer)**: any agent can hand off to any other — flexible but chaotic. **Supervisor (orchestrator-worker)**: one coordinator agent routes work to specialist workers and assembles results — the most common, controllable pattern. **Hierarchical**: supervisors of supervisors, for large systems. **Sequential pipeline**: agents in a fixed chain (A→B→C), basically a workflow. And **planner-executor**: one agent plans steps, another executes them. The trade-off axis is **autonomy vs control**: more agent-driven routing = more flexible but less predictable; more fixed structure = more reliable but less adaptive. In practice, **supervisor** and **pipeline** dominate because they're debuggable, and they map cleanly onto **LangGraph (§11)** — agents as nodes, routing as (conditional) edges.

> [!NOTE]
> **Where this fits**
> Second note of **Section 22**, following the motivation in [[01 - Why Multi-Agent]]. How agents actually pass work is in [[03 - Agent Communication and Handoffs]].

---

## 1. The spectrum: control vs autonomy

```
more CONTROL  ◄───────────────────────────────►  more AUTONOMY
sequential    supervisor      hierarchical       network
pipeline      (orchestrator)                     (peer-to-peer)
(predictable, rigid)                             (flexible, chaotic)
```

Every architecture is a choice on this axis. More structure = more reliable/debuggable; more agent-driven routing = more adaptive but harder to predict and test.

---

## 2. Network (peer-to-peer)

Any agent can decide to hand off to any other agent.

```
   ┌──► Agent A ◄──┐
   │      ▲        │
   ▼      │        ▼
Agent C ◄─┴──► Agent B
```

- ✅ Maximally flexible; agents self-organize.
- ❌ Hard to predict/debug; risk of **loops** and agents talking past each other; token cost balloons.
- Use only when the task genuinely needs open-ended collaboration.

---

## 3. Supervisor (orchestrator-worker) — the workhorse

One **supervisor** agent receives the task, **routes** subtasks to specialist **workers**, collects their outputs, and decides what's next / when done.

```
              ┌──────────────┐
   task ─────►│  SUPERVISOR  │◄──── results
              └──────┬───────┘
        ┌────────────┼────────────┐
        ▼            ▼            ▼
   Researcher     Coder       Reviewer
   (search)      (files)      (critic)
```

- ✅ Clear control flow, easy to reason about and debug, easy to add a worker.
- ✅ The supervisor is the single place that decides routing → predictable.
- ❌ Supervisor is a bottleneck / single point of failure; extra hop adds latency.
- **Most common** production pattern.

> [!TIP]
> **Default to supervisor**
> For most multi-agent needs, the orchestrator-worker pattern is the right starting point: specialists stay focused, the supervisor owns coordination, and you can trace exactly who did what. It's the multi-agent shape that's easiest to **eval (§17)** and **secure (§19)**.

---

## 4. Hierarchical (teams of teams)

Supervisors managing **sub-supervisors**, each with their own workers — for large systems where one supervisor would be overloaded (the same overload problem from [[01 - Why Multi-Agent]], one level up).

```
            Top Supervisor
           /              \
  Research Lead         Eng Lead
   /      \             /     \
 web    docs        coder   tester
```

Powerful but heavy — only for genuinely large workflows.

---

## 5. Sequential pipeline

Agents in a **fixed chain**, each transforming and passing forward.

```
Outline agent → Draft agent → Edit agent → Format agent → output
```

- ✅ Dead simple, fully predictable, easy to debug.
- ❌ No adaptivity (can't skip/loop based on content).
- This is essentially a **workflow** — often better expressed directly in **LangGraph (§11)** with LLM nodes, no "agent autonomy" needed.

---

## 6. Planner-executor

One agent **plans** (decompose into steps), another (or several) **executes** each step; optionally re-plan based on results.

```
task → PLANNER → [step1, step2, step3] → EXECUTOR runs each → (replan if needed) → done
```

Good for tasks where the steps aren't known upfront. Relates to decomposition in query transformation (§18) and reasoning (§23).

---

## 7. Choosing an architecture

| Need | Architecture |
|---|---|
| Fixed, known steps | **Sequential pipeline** (or plain LangGraph workflow) |
| Specialists + a coordinator | **Supervisor** (default) |
| Very large / many specialties | **Hierarchical** |
| Steps unknown upfront | **Planner-executor** |
| Open-ended collaboration | **Network** (use sparingly) |

```
predictable ──► pipeline / supervisor
adaptive    ──► planner-executor / network
```

Pick the **most structured** option that still solves the problem — structure buys debuggability, eval-ability, and safety.

---

## 8. They map onto LangGraph

> [!IMPORTANT]
> **Multi-agent = a graph (§11)**
> Each architecture is a graph: **agents are nodes**, **handoffs are edges**, **routing decisions are conditional edges**, and inter-agent messages flow through **shared state**. A supervisor is a node with conditional edges to worker nodes; a pipeline is a linear edge chain. So everything from §11 (and checkpointing §12 for state) directly applies — LangGraph is the natural way to *build* these.

---

## 9. Main takeaways

- Architectures sit on a **control ↔ autonomy** spectrum.
- **Network**: peer-to-peer, flexible but chaotic (loops, cost) — use sparingly.
- **Supervisor (orchestrator-worker)**: a coordinator routes to specialists — **the default**, controllable, debuggable.
- **Hierarchical**: supervisors of supervisors for large systems.
- **Sequential pipeline**: fixed chain — simple, predictable (often just a workflow).
- **Planner-executor**: plan steps, then execute — for unknown-upfront tasks.
- Choose the **most structured** option that works.
- All map onto **LangGraph**: agents=nodes, handoffs=edges, routing=conditional edges, messages=state.

---

## 10. Things I still want to figure out

- When does supervisor's bottleneck/latency justify going hierarchical?
- How to prevent **infinite loops** in network architectures?
- Supervisor routing via tool-calling vs a dedicated router model?

---

## 11. Things to dig into

- **LangGraph multi-agent** docs (supervisor, network, hierarchical).
- **CrewAI** (role-based) vs **AutoGen** (conversational) patterns (note 04).
- Anthropic "building effective agents" (workflow vs agent).
- Next: [[03 - Agent Communication and Handoffs]].

---

## 12. Next up in this section

- [ ] [[03 - Agent Communication and Handoffs]] — how agents actually pass work and context.

---

## Related
- [[01 - Why Multi-Agent]] — why split at all.
- [[02 - What is LangGraph]] — the graph substrate these map onto.

## Sources
- [LangGraph multi-agent architectures](https://langchain-ai.github.io/langgraph/concepts/multi_agent/)
- [Anthropic: building effective agents](https://www.anthropic.com/research/building-effective-agents)
