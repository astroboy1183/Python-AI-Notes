---
title: Multi-Agent Frameworks
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 22: Multi-Agent Systems"
tags:
  - multi-agent
  - frameworks
  - crewai
  - autogen
  - langgraph
related:
  - "[[03 - Agent Communication and Handoffs]]"
  - "[[05 - Multi-Agent Challenges and Best Practices]]"
---

# Multi-Agent Frameworks

> [!NOTE]
> **TL;DR**
> Several frameworks implement the architectures (note 02) and handoffs (note 03) so you don't build coordination from scratch. **LangGraph (§11)** — graph-based, maximum control, agents-as-nodes; best when you want explicit, debuggable, stateful flows. **CrewAI** — role-based; you define agents with roles/goals and tasks, and it orchestrates a "crew" (intuitive for role-playing teams). **AutoGen** (Microsoft) — conversation-based; agents talk to each other, strong for code-gen and research loops. **OpenAI Agents SDK** — a lightweight official primitive set (agents, tools, handoffs, guardrails) for OpenAI-centric apps. There's no single best — LangGraph for control, CrewAI for quick role-based crews, AutoGen for conversational collaboration. Or, for simple cases, **no framework**: a plain Python loop calling specialized agents is often enough.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 22** — the tooling for the concepts in notes 02–03. Pitfalls of using them are in [[05 - Multi-Agent Challenges and Best Practices]].

---

## 1. The landscape

| Framework | Model | Strength | Control level |
|---|---|---|---|
| **LangGraph** | Graph (nodes/edges/state) | Explicit, stateful, debuggable | **High** |
| **CrewAI** | Roles + tasks ("crew") | Fast to express role-based teams | Medium |
| **AutoGen** | Conversation (agents chat) | Emergent collaboration, code/research | Medium-low |
| **OpenAI Agents SDK** | Agents + tools + handoffs | Lightweight, official, OpenAI-native | Medium |
| **(none)** | Plain Python | Simplest; full control | Highest |

---

## 2. LangGraph — control and state (already known)

You've used it in §11–12. For multi-agent, agents become **nodes**, handoffs become **edges**, routing is **conditional edges**, and context flows through **shared state** (note 03) — with **checkpointing (§12)** for persistence.

```python
# conceptual: supervisor routing to worker nodes
graph.add_node("supervisor", supervisor)
graph.add_node("researcher", researcher)
graph.add_node("coder", coder)
graph.add_conditional_edges("supervisor", route_to_worker)  # picks next agent
```

> [!TIP]
> **Pick LangGraph when you need to *trust and debug* the flow**
> Because everything is an explicit graph with inspectable state, LangGraph is the best fit for production multi-agent systems where you must reason about, eval (§17), and secure (§19) exactly what happens. It's the lowest-magic, highest-control option.

---

## 3. CrewAI — role-based crews

Define agents by **role/goal/backstory** and give them **tasks**; CrewAI runs the crew (sequential or hierarchical process).

```python
# conceptual
researcher = Agent(role="Researcher", goal="find facts", tools=[search])
writer     = Agent(role="Writer", goal="write the report")
crew = Crew(agents=[researcher, writer],
            tasks=[research_task, write_task], process="sequential")
crew.kickoff()
```

- ✅ Very readable; great for "a team of personas" mental model; quick to prototype.
- ⚠️ Less fine-grained control over the exact flow than LangGraph.

---

## 4. AutoGen — conversational agents

Agents **converse** to solve tasks; e.g. an assistant agent proposes code, a user-proxy/executor agent runs it and reports back, iterating until done.

```
AssistantAgent ↔ UserProxyAgent (executes code, returns results) → loop until solved
```

- ✅ Strong for **code generation + execution** loops and research-style collaboration; emergent.
- ⚠️ Conversational/emergent flows can be harder to constrain and debug (note 05).

---

## 5. OpenAI Agents SDK — lightweight primitives

An official, minimal toolkit: define **agents** (instructions + tools), **handoffs** (agent-to-agent transfer as a first-class concept), built-in **guardrails** (§19) and tracing (§17).

- ✅ Clean, low-overhead, integrates tightly with OpenAI models/tools; handoffs are native.
- ⚠️ OpenAI-centric; less of an opinionated orchestration graph than LangGraph.

---

## 6. ...or no framework

> [!IMPORTANT]
> **A framework isn't mandatory**
> For a couple of specialized agents with a clear flow, a **plain Python script** that calls each agent (each = an LLM call with its own prompt + tools) and passes context is often the simplest, most debuggable choice. Frameworks earn their keep when coordination, state, persistence, or many agents make hand-rolling tedious. Start simple; adopt a framework when it removes real pain.

```python
# no-framework supervisor (conceptual)
plan = supervisor_llm(task)
research = researcher_llm(plan)
code = coder_llm(plan, research)
review = reviewer_llm(code)
return supervisor_llm.synthesize(task, code, review)
```

---

## 7. Choosing

```
need explicit control / state / production debugging → LangGraph
want quick role-based "team" prototypes             → CrewAI
conversational code/research collaboration          → AutoGen
OpenAI-native, lightweight, native handoffs         → OpenAI Agents SDK
2–3 agents, clear flow                              → plain Python
```

All of them sit on top of the same fundamentals (notes 02–03); the framework is a convenience, not the substance. And whatever you pick, the **challenges in note 05** still apply.

---

## 8. Main takeaways

- Frameworks implement architectures + handoffs so you don't build coordination from scratch.
- **LangGraph**: graph/state, **highest control**, best for debuggable production flows (you already know it).
- **CrewAI**: **role-based** crews — readable, quick to prototype.
- **AutoGen**: **conversational** agents — strong for code-exec/research loops.
- **OpenAI Agents SDK**: lightweight official primitives with **native handoffs** + guardrails.
- **No framework** (plain Python) is fine for a few agents with a clear flow.
- Choose by **control needs**; the underlying concepts are identical across tools.

---

## 9. Things I still want to figure out

- CrewAI vs LangGraph for a real supervisor system — which is less painful?
- How well does AutoGen's conversational model stay controllable at scale?
- Does the OpenAI Agents SDK lock me in vs LangGraph's portability?

---

## 10. Things to dig into

- **LangGraph** multi-agent (§11) · **CrewAI** docs · **AutoGen** docs · **OpenAI Agents SDK**.
- Build the same supervisor system in two frameworks to compare.
- Next: [[05 - Multi-Agent Challenges and Best Practices]].

---

## 11. Next up in this section

- [ ] [[05 - Multi-Agent Challenges and Best Practices]] — the failure modes and how to avoid them.

---

## Related
- [[03 - Agent Communication and Handoffs]] — what these frameworks implement.
- [[02 - What is LangGraph]] — the control-first option.

## Sources
- [CrewAI](https://docs.crewai.com/) · [AutoGen](https://microsoft.github.io/autogen/)
- [OpenAI Agents SDK](https://openai.github.io/openai-agents-python/)
