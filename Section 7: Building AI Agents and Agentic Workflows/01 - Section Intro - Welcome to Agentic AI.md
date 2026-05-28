---
title: Section Intro - Welcome to Agentic AI
date: 2026-05-28
source: "Section 7 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 7: Building AI Agents and Agentic Workflows"
tags:
  - agentic-ai
  - agents
  - llm-tools
  - section-overview
  - foundations
related:
  - "[[06 - Chain of Thought Prompting]]"
  - "[[07 - Automating Chain of Thought]]"
  - "[[01 - What is an LLM]]"
---

# Section Intro — Welcome to Agentic AI

> [!abstract] TL;DR
> The course's biggest pivot — moving from **"LLM as text predictor"** to **"LLM as agent that takes actions in the world."** Agentic AI = an LLM connected to tools (functions, APIs, databases, file systems, browsers, code interpreters) so it can not just reply but actually **do things**: book flights, modify files, query databases, send emails. A favorite section, because **all major businesses are moving toward agentic AI** — it's where real-world business value materializes. This section converts an LLM into an agent step-by-step through three hands-on builds: a weather agent (with tool calling), a structured-output upgrade (Pydantic for reliability), and a CLI coding assistant (vibe-coded apps).

> [!info] Where this fits
> First lecture of **Section 7: Building AI Agents and Agentic Workflows**. The course has covered everything needed: model APIs (Section 2), prompts (Section 3), structured I/O (Section 3), prompt styles (Section 4), local models (Section 5), Hugging Face (Section 6). Now those pieces combine into agents. After Section 7, the course moves into **RAG** (Section 8–9), **multimodal** agents (Section 10), and **LangGraph** orchestration (Section 11+).

---

## 1. Why this section matters

Agentic AI is where the field is going. Every major business and big tech company is moving toward agents — it's how AI starts producing real-world value and profits, not just chat replies.

The shift in framing:

| Era | What LLMs do | Example product |
|---|---|---|
| **Chat era** (2022-2023) | Reply to text prompts | ChatGPT |
| **Tool-use era** (late 2023) | Call functions / APIs | ChatGPT plugins, GPT-4 function calling |
| **Agent era** (2024+) | Multi-step autonomous task completion | Devin, Claude Computer Use, Cursor, ChatGPT operator mode |

Section 7 lands the course in the agent era.

---

## 2. The fundamental distinction

| | Plain LLM call | Agent |
|---|---|---|
| Input | Prompt | Prompt + tools |
| Output | Text reply | Tool calls + reasoning + text |
| Iterations | Single forward pass | **Multi-step loop** |
| Side effects on the world | None | Modifies files, sends emails, executes code |
| Knowledge cutoff | Hard limit | **Tools fill the gap** (real-time data, fresh APIs) |
| Reliability of output | "Best guess" | Verified by tool outputs |
| Example | "What's the weather in Goa?" → vague pre-2024 answer | "What's the weather in Goa?" → calls weather API → returns *actual current weather* |

---

## 3. What gets built in this section

| Lecture | Build |
|---|---|
| 02 | Conceptual: what an agent **is**, with diagrams and analogies |
| 03 | Hands-on: a **weather agent** that calls a real weather API |
| 04 | Upgrade: **Pydantic structured outputs** for reliability |
| 05 | Hands-on: a **CLI coding assistant** that creates files, runs commands, debugs |

By the end: a working agent that takes a single prompt like *"build me a todo app"* and produces a working todo app on disk by issuing real Linux commands.

---

## 4. Connection to prior sections

Section 7 doesn't introduce **new** concepts — it **combines** previously-introduced ones:

| Prior concept | How Section 7 uses it |
|---|---|
| [[06 - Chain of Thought Prompting\|CoT prompting]] | The `start → plan → tool → observe → output` loop is just CoT with tool steps added |
| [[07 - Automating Chain of Thought\|CoT loop automation]] | The `while True` dispatcher pattern becomes the agent loop |
| [[05 - Structured Output with Few-Shot Prompting\|Structured output]] | Tool calls are JSON objects the model emits; structured output enforces shape |
| [[02 - What is Prompting\|System prompts]] | Agent identity, allowed tools, behavior rules all live in the system prompt |
| [[02 - Using OpenAI API in Python\|OpenAI API]] | The underlying LLM call |

> [!tip] What makes Section 7 click
> If [[07 - Automating Chain of Thought]] was the "**loop pattern**" and [[05 - Structured Output with Few-Shot Prompting]] was the "**JSON output**" — Section 7 is what happens when those two combine: **structured output where one of the JSON fields means 'go run this tool and tell me the result'**.

---

## 5. The deeper "why" of agents

Agents matter because they unlock **two new capabilities**:

### Capability 1 — Real-time information
LLMs are frozen at training time. They don't know:
- Today's weather.
- Today's stock price.
- This morning's news.
- The contents of your specific database.
- The current state of your file system.

Tools give the LLM access to the **live world**.

### Capability 2 — Taking actions
LLMs by default only emit text. They can't:
- Send an email.
- Modify a file.
- Place an order.
- Push a commit.
- Book a meeting.

Tools turn the LLM's "text output" into **executable actions**.

Both together = LLM as a participant in actual workflows, not just a chatbot.

---

## 6. Why businesses care

The economic argument:

| Use case | What an agent unlocks |
|---|---|
| Customer support | Replace tier-1 agents; handle 80% of routine tickets autonomously |
| Coding | Pair-programmer, code-reviewer, debugger (Cursor, Devin) |
| Research | Literature review, data extraction, summarization across thousands of papers |
| Sales | Auto-personalized outreach, follow-up scheduling |
| Operations | Run reports, alert on anomalies, escalate intelligently |
| Personal productivity | Calendar management, email triage, travel booking |

Each is a real product market with billions in TAM. That's why hosted-LLM providers (OpenAI, Anthropic, Google) all shipped tool-calling APIs in 2023-2024.

---

## 7. What this section won't (yet) cover

A few advanced agent topics deliberately deferred to later sections:

| Topic | Where covered |
|---|---|
| Persistent memory across sessions | [[00 - Types of Memory in LLMs|Section 13]] |
| Knowledge-grounded answers via RAG | Section 8-9 |
| Multi-modal (vision, audio) agents | Section 10 |
| Multi-agent orchestration | Section 11-12 (LangGraph) |
| Production agent serving infrastructure | Various later sections |
| MCP (Model Context Protocol) | Section 16 |

Section 7 keeps things **small and complete** — one agent loop, real tools, real outputs — without bringing in extra abstractions.

---

## 8. Mindset to bring

A few things to internalize:

| Mindset | Why |
|---|---|
| Agents are **loops, not single calls** | One prompt may produce 10+ API calls before a final answer |
| Tools are **just Python functions** the model can invoke | No magic — `def get_weather(city: str) -> str` is a tool |
| The model **decides** which tool to call and when | That's the "agentic" part — autonomy in tool selection |
| Output reliability comes from **structured schemas** | JSON parse failures = broken agents |
| **Cost** scales with steps | A 10-step agent is ~10× the tokens of a single call |
| **Observability matters** | Print every step; agents fail invisibly without good logging |

---

## 9. Main takeaways

- **Agentic AI** = LLM + tools + a loop = capability to take actions in the world.
- Pivots the course from "LLM as text predictor" to "LLM as worker."
- Builds on **everything covered so far** — CoT, structured output, system prompts, API calling.
- Section will produce a **weather agent**, then a **CLI coding assistant**.
- The pattern that emerges (system prompt + tools + JSON dispatch loop) is **universal** — used in every production agent system.
- This is where AI starts producing real business value.

---

## 10. Next up in this section

- [ ] [[02 - What are AI Agents]] — conceptual deep-dive with diagrams and the brain/body analogy.
- [ ] [[03 - Building a Weather Agent]] — first hands-on agent.
- [ ] [[04 - Structured Outputs with Pydantic]] — make the agent reliable.
- [ ] [[05 - Building a CLI Coding Assistant]] — agent that writes code on disk.

---

## Related
- [[06 - Chain of Thought Prompting]] — the prompting pattern agents extend.
- [[07 - Automating Chain of Thought]] — the loop pattern agents reuse.
- [[05 - Structured Output with Few-Shot Prompting]] — the JSON foundation.
- [[01 - What is an LLM]] — the underlying model.

## Sources
- Section 7, Lecture 1 — section intro on agentic AI.
