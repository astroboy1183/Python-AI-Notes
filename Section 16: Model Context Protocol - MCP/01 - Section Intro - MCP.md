---
title: Section Intro - MCP
date: 2026-05-29
source: "Section 16 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 16: Model Context Protocol - MCP"
tags:
  - mcp
  - model-context-protocol
  - tools
  - agents
  - section-intro
related:
  - "[[02 - The Problem MCP Solves]]"
---

# Section Intro — MCP

> [!NOTE]
> **TL;DR**
> This section is about **MCP — the Model Context Protocol**: a standard for *how you provide context (tools, data) to a model*. MCP is relatively new in AI but already heavily adopted by big companies. The plan: understand **what MCP is**, **what problem the protocol solves**, and **how AI agents leverage MCP to make tool calling standardized** — instead of every developer wiring tools to their LLM in their own ad-hoc way.

> [!NOTE]
> **Where this fits**
> First note of **Section 16: Model Context Protocol (MCP)** — the final section of the course. It frames MCP; [[02 - The Problem MCP Solves]] digs into the motivation, and [[03 - MCP from the Docs]] covers the formal architecture.

---

## 1. The one-line idea

> MCP **standardizes the way you provide context to a model** — most importantly, the way you connect **tools** and **data sources** to an LLM.

Everything in this course so far built agents by hand-wiring tools to a model. MCP asks: *why does everyone reinvent that wiring?* — and proposes a **common protocol** for it.

```
before MCP:  every team wires tools → LLM their own custom way
with MCP:    one standard protocol to connect tools/data → any LLM
```

---

## 2. Why it matters

- **New but widely adopted** — major companies already expose MCP integrations.
- **Standardization** — a shared way to connect tools means tools become **reusable** across agents and models.
- **Agent-relevant** — it directly upgrades how the agents from earlier sections do **tool calling**.

---

## 3. What the section covers

| Topic | Note |
|---|---|
| The problem MCP solves (and the USB-C analogy) | [[02 - The Problem MCP Solves]] |
| MCP from the official docs — Host / Client / Server | [[03 - MCP from the Docs]] |

---

## 4. What I want to remember

- **MCP = Model Context Protocol** — a standard for feeding context/tools to models.
- It's **new but heavily used** in industry.
- The goal: make **tool calling standardized** instead of bespoke per project.
- This section = *what it is* + *what problem it solves* + *how agents use it*.

---

## 5. Things to dig into

- **MCP spec / docs**: https://modelcontextprotocol.io/
- **Anthropic's MCP announcement** (origin).
- How MCP relates to the **tool-calling** agents already built.

---

## 6. Next up in this section

- [ ] [[02 - The Problem MCP Solves]] — the motivation, via the agent = LLM + tools framing.

---

## Related
- [[02 - The Problem MCP Solves]] — the deeper motivation.

## Sources
- [Model Context Protocol](https://modelcontextprotocol.io/)
