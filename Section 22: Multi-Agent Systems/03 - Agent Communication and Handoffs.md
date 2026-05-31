---
title: Agent Communication and Handoffs
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 22: Multi-Agent Systems"
tags:
  - multi-agent
  - handoffs
  - communication
  - state
related:
  - "[[02 - Multi-Agent Architectures]]"
  - "[[04 - Multi-Agent Frameworks]]"
---

# Agent Communication and Handoffs

> [!NOTE]
> **TL;DR**
> Once there are multiple agents, the central question is **how they pass work and context to each other**. Two broad models: **shared state** (all agents read/write a common scratchpad — clean, the LangGraph way) and **message passing** (agents send each other messages, conversation-style — the AutoGen way). A **handoff** is the act of one agent transferring control (and relevant context) to another — often implemented as a special "tool call" (`transfer_to_researcher`). The hard problems: **how much context to pass** (everything = token bloat + confusion; too little = the next agent lacks info), avoiding **infinite loops** (A hands to B hands back to A...), and keeping a **shared goal** so agents don't drift. Good handoff design — pass focused, relevant context and define clear termination — is what makes multi-agent systems actually work rather than spiral.

> [!NOTE]
> **Where this fits**
> Third note of **Section 22**, the mechanics behind the architectures in [[02 - Multi-Agent Architectures]]. Frameworks (note 04) implement these patterns for you.

---

## 1. The two communication models

| Model | How agents share | Style | Used by |
|---|---|---|---|
| **Shared state** | Read/write a common state object | Blackboard / scratchpad | **LangGraph** (§11) |
| **Message passing** | Send messages to each other | Conversation | **AutoGen** |

### Shared state (LangGraph-style)
All agents operate on one **state** (like §11's graph state). An agent reads what it needs, writes its output, and the next agent picks it up.

```
state = { task, research_notes, code, review_comments }
researcher → writes research_notes → coder reads it, writes code → reviewer reads code
```

Clean, inspectable, no "messages flying around." This is the §11/§12 model extended to multiple agents.

### Message passing (conversation-style)
Agents literally **talk** — each sends messages others read, like a group chat. More flexible/emergent, but harder to control and trace.

---

## 2. Handoffs — transferring control

A **handoff** = one agent decides another should take over, and passes along the relevant context.

```
supervisor: "this needs code" → HANDOFF to coder (with the spec) → coder works → HANDOFF back
```

Common implementation: a **handoff-as-tool-call**. The agent has tools like `transfer_to_coder(context)`; calling it routes control (and the chosen context) to that agent. This reuses the tool-calling machinery from §7 — a handoff is just a tool whose "action" is "switch active agent."

> [!IMPORTANT]
> **A handoff is just routing + context transfer**
> Don't overthink it: handing off = (1) decide which agent is next, (2) give it the context it needs. In a supervisor architecture the supervisor decides; in a network any agent can. The decision is an LLM choice (tool call); the context transfer is the part that needs care (below).

---

## 3. The context problem — the crux

> [!WARNING]
> **How much context to pass is the make-or-break decision**
> - **Pass everything** (full history of every agent) → token bloat (§20), and the receiving agent gets **confused** by irrelevant detail (overload, the §22.01 problem).
> - **Pass too little** → the next agent **lacks** what it needs and does the wrong thing.
>
> The art is passing **focused, relevant context**: the task, the specific inputs that agent needs, and a summary of prior work — not raw transcripts of everything. Often a handoff includes a **summary** rather than full history.

```
bad:  hand the coder the ENTIRE researcher+supervisor conversation
good: hand the coder { spec, key findings (summarized), constraints }
```

This mirrors context engineering elsewhere: give each LLM call exactly what it needs, no more.

---

## 4. Avoiding loops and runaway cost

Multi-agent systems can **spiral**: A hands to B, B hands back to A, forever — burning tokens (§20).

| Safeguard | How |
|---|---|
| **Max iterations / recursion limit** | Hard cap on total handoffs (LangGraph has one) |
| **Clear termination condition** | Define explicitly when the task is "done" |
| **Supervisor owns done-ness** | One agent decides completion (supervisor pattern) |
| **State progress check** | Detect "no progress" and stop |
| **Budget cap** | Stop at a token/cost ceiling (§20) |

> [!TIP]
> **Always define termination**
> The most common multi-agent failure is **never stopping** (or stopping too early). Make "done" explicit — a condition the supervisor checks, or a step/budget cap — so the system converges instead of looping.

---

## 5. Keeping a shared goal

Each agent has a narrow role, but they must serve **one overall goal**. Techniques:
- Put the **top-level task/goal** in shared state so every agent sees it.
- Have the supervisor **re-state the goal** in each handoff.
- A final **synthesis** step (supervisor or a dedicated agent) assembles workers' outputs into the answer to the original task.

Without this, agents optimize their local subtask and the combined result drifts from what was actually asked.

---

## 6. Putting it together (supervisor example)

```
1. user task → supervisor (goal stored in shared state)
2. supervisor → handoff (transfer_to_researcher, with focused context)
3. researcher → writes findings to state → handoff back
4. supervisor → handoff to coder (spec + summarized findings)
5. coder → writes code to state → handoff back
6. supervisor → handoff to reviewer → review comments to state
7. supervisor → checks termination → synthesize → return to user
   (recursion limit + budget cap guard the whole loop)
```

---

## 7. Main takeaways

- Two communication models: **shared state** (LangGraph; clean, inspectable) and **message passing** (AutoGen; conversational, flexible).
- A **handoff** = transfer control + context; commonly a **tool call** (`transfer_to_X`).
- The crux is **how much context to pass**: too much = bloat/confusion, too little = the agent lacks info → pass **focused, summarized** context.
- **Avoid loops**: max iterations/recursion limit, explicit **termination**, supervisor owns done-ness, budget cap (§20).
- **Keep a shared goal** in state; re-state it on handoff; **synthesize** at the end.
- Handoffs reuse §7 tool-calling and §11/§12 state machinery.

---

## 8. Things I still want to figure out

- Best way to **summarize** context for a handoff without losing key info?
- Detecting "no progress" to break loops automatically?
- Shared-state vs message-passing — which scales better with agent count?

---

## 9. Things to dig into

- **LangGraph** handoffs / `Command` + shared state (§11/§12).
- **AutoGen** conversational message passing.
- **OpenAI Agents SDK** handoff primitives (note 04).
- Next: [[04 - Multi-Agent Frameworks]].

---

## 10. Next up in this section

- [ ] [[04 - Multi-Agent Frameworks]] — the tools that implement all this (CrewAI, AutoGen, LangGraph, Agents SDK).

---

## Related
- [[02 - Multi-Agent Architectures]] — the structures these handoffs realize.
- [[04 - Creating the State and Graph Builder]] — shared-state mechanics (§11).

## Sources
- [LangGraph: handoffs & multi-agent](https://langchain-ai.github.io/langgraph/concepts/multi_agent/)
- [Microsoft AutoGen](https://microsoft.github.io/autogen/)
