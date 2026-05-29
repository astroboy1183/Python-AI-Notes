---
title: What is LangGraph
date: 2026-05-29
source: "Section 11 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 11: Building Agentic Workflows with LangGraph"
tags:
  - langgraph
  - workflows
  - orchestration
  - agents
  - conditional-edge
  - foundations
related:
  - "[[01 - Section Intro - Welcome to LangGraph]]"
  - "[[03 - Installing LangGraph & Core Concepts]]"
---

# What is LangGraph

> [!abstract] TL;DR
> Real agents aren't a single LLM call — they're **multi-step workflows**: take user input → plan → maybe call a tool (web search) → loop the result back → finalize → maybe judge the answer with another LLM → retry if bad → end. Drawn as a **flowchart**, that's clear and obvious. Coded by hand in Python, it collapses into **nested `if/else` and `while` loops** that get messy and unmaintainable the moment I add one more step. **LangGraph** is a framework that lets me express that same flowchart **as a graph in code** — organize logic into nodes and edges, run it, debug it, and share it — so I never have to write the spaghetti. Its tagline captures the goal: *balance agent control with agency.*

> [!info] Where this fits
> Second note of **Section 11**. It makes the case *for* LangGraph by showing the pain of hand-coding a branching workflow. [[03 - Installing LangGraph & Core Concepts]] then introduces the actual building blocks (nodes, edges, state).

---

## 1. The core observation: an agent is a workflow

Coding an agent isn't one call — it's a **sequence of steps** with branches and loops:

1. Take a user query.
2. Do some **planning**.
3. Decide: do I need a **tool** (e.g. web search)?
   - If yes → run the search → feed the result **back** to the LLM.
   - If no → proceed straight to finalizing.
4. Do a completion to **finalize the response**.
5. Optionally, **judge** the response with another LLM (LLM-as-a-judge).
   - If the answer is **not good** → **retry** with extra context.
   - If the answer is **good** → **end**.

That's a real workflow with planning, conditional tool use, and a quality-control loop.

---

## 2. The same workflow as a flowchart

```
            ┌─────────────┐
            │  user query │
            └──────┬──────┘
                   ▼
            ┌─────────────┐
            │   planning  │
            └──────┬──────┘
                   ▼
            ◇ need web search? ◇───── no ──────┐
                   │                            │
                  yes                           │
                   ▼                            ▼
            ┌─────────────┐            ┌────────────────┐
            │  web search │            │  LLM: finalize │
            └──────┬──────┘            │   the response │
                   │  (return result   └───────┬────────┘
                   └───► back to LLM)           │
                                                ▼
                                       ◇ response good? ◇
                                          │          │
                                         yes         no
                                          │          │
                                          ▼          ▼
                                        (END)   retry w/ extra
                                                  │  (judge via
                                                  │   another LLM,
                                                  └─► e.g. Gemini)
```

The **diamonds** are decision points — *conditional edges* in LangGraph terms (covered in [[09 - Conditional Edges]]). Everything else is a step. As a picture, this is completely legible.

---

## 3. The problem: coding this by hand

Ask for this flowchart "just in Python" and the result is:

- A `while` loop to keep the agent going.
- Nested `if/else` for "need a tool?", "is the answer good?", "should I retry?".
- Back-and-forth jumps that don't map cleanly to structured code.

> [!warning] It rots fast
> Add **one more node** to the workflow and the hand-written version gains more nested conditionals and loop bookkeeping. Soon the code is a tangle — hard to read, hard to debug, hard to extend. The control flow no longer resembles the flowchart at all.

```python
# the kind of thing LangGraph saves me from
while True:
    plan = llm(plan_prompt)
    if needs_search(plan):
        results = web_search(...)
        answer = llm(finalize_prompt, results)
    else:
        answer = llm(finalize_prompt)
    if judge(answer) == "good":
        break
    else:
        # retry... with what state? where does this loop back to exactly?
        ...
```

The bug surface is huge: which variables carry state across iterations, where exactly does each branch jump back to, how do I add a step without rethinking the whole loop.

---

## 4. What LangGraph is

> [!note] Definition
> **LangGraph** is a framework that lets me organize agent logic into a **graph structure** — build the workflow, run it, debug it, and share it — instead of writing nested `if/else`/`while` loops.

In other words: the flowchart I drew in §2 becomes the actual program. Its design goal, in LangChain's words, is to **"balance agent control with agency"** — give the LLM room to decide (agency) while keeping the overall flow explicit and controllable (control).

```
flowchart (what I draw)  ≈  LangGraph graph (what I code)
```

The shape of the code matches the shape of the problem. That's the whole pitch.

---

## 5. From simple to complex — same framework

LangGraph scales from trivial to elaborate without changing the model:

| Workflow | Graph |
|---|---|
| Basic chatbot | `START → chatbot → END` |
| Chatbot + tools | `START → chatbot → ◇(need tool?) → tool → back to chatbot → … → END` |
| Full agent | planning, tool branches, judge loop, retries — all nodes + edges |

A tool-using loop is just `START → chatbot → (if tool needed) tool → chatbot → … → END`. Adding capability means adding **nodes and edges**, not rewriting control flow.

---

## 6. Why graphs win over loops

| Concern | Hand-coded loops | LangGraph |
|---|---|---|
| Readability | Degrades with each branch | Mirrors the flowchart |
| Adding a step | Touch the whole loop | Add a node + an edge |
| Debugging | Trace variables through iterations | Inspect state at each node |
| Sharing / reuse | Bespoke per project | Standard graph structure |
| Branching | Nested `if/else` | Conditional edges |
| Loops | `while` + flags | Edges back to earlier nodes |

---

## 7. Main takeaways

- A real agent is a **multi-step workflow** with planning, tool branches, and quality loops.
- As a **flowchart** it's clear; hand-coded it becomes **nested `if/else`/`while` spaghetti**.
- Adding nodes to the hand-coded version makes it **messy and unmaintainable**.
- **LangGraph** expresses the flowchart **as a graph in code**: nodes + edges.
- It scales from `START → chatbot → END` up to full agents with tools and judges.
- Decision points become **conditional edges** (the diamonds).
- Goal: **balance control with agency** — explicit flow, but the LLM still decides.

---

## 8. Things I still want to figure out

- How does LangGraph handle **loops** (e.g. retry) without infinite cycles — is there a recursion limit?
- What does "**share** a workflow" mean concretely — is the graph serializable?
- Where's the line where LangGraph is **overkill** vs a plain agent loop?
- How does it relate to **LangChain** — dependency, or independent?

---

## 9. Things to dig into

- **LangGraph overview**: https://langchain-ai.github.io/langgraph/
- **Prebuilt agents** (`create_react_agent`) vs hand-built graphs.
- The **conditional-edge** mechanism (full treatment in [[09 - Conditional Edges]]).

---

## 10. Next up in this section

- [ ] [[03 - Installing LangGraph & Core Concepts]] — install it, and meet nodes, edges, and state.

---

## Related
- [[01 - Section Intro - Welcome to LangGraph]] — the framing note.
- [[09 - Conditional Edges]] — the diamonds in the flowchart, implemented.

## Sources
- [LangGraph documentation](https://langchain-ai.github.io/langgraph/)
