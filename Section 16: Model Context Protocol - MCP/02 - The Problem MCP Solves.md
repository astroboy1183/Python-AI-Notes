---
title: The Problem MCP Solves
date: 2026-05-29
source: "Section 16 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 16: Model Context Protocol - MCP"
tags:
  - mcp
  - tools
  - agents
  - standardization
  - usb-c
  - foundations
related:
  - "[[01 - Section Intro - MCP]]"
  - "[[03 - MCP from the Docs]]"
  - "[[05 - Building a CLI Coding Assistant]]"
---

# The Problem MCP Solves

> [!NOTE]
> **TL;DR**
> An **agent = LLM + tools**. The **LLM is a constant** — OpenAI/Anthropic/Google build the models, and if two teams both use GPT-5.1 there's no advantage there. An agent's edge comes from its **tools** (and system prompt) and **how those tools are wired to the model**. But that wiring has always been **ad-hoc** — like the hand-rolled `run_command` tool in the earlier Cursor/weather agent, glued on via a custom system prompt. MCP standardizes it: think **USB-C for AI**. One universal "cable" so any tool plugs into any model. Companies (Google, Twitter/X, …) build **MCP tool servers** (read_email, post_tweet, …), and any agent — GPT, Gemini, Claude — connects to them through the same protocol. It's essentially **REST APIs, but for AI tools**: a universal interface so tools become reusable across every model.

> [!NOTE]
> **Where this fits**
> Second note of **Section 16**. It motivates MCP from the agent = LLM + tools idea. [[03 - MCP from the Docs]] then gives the formal definition and architecture.

---

## 1. Recap: what an agent really is

An LLM alone just predicts the next token — on its own it does nothing useful. Developers turn it into an **agent** by attaching **tools** for a use case (a coding agent, a cooking agent, …).

```
agent = LLM (the brain)  +  tools (the hands)
```

So an agent has **two components**: the **LLM** and the **tools**.

---

## 2. The LLM is the constant; tools are the differentiator

> [!IMPORTANT]
> **You can't out-build OpenAI's model — you differentiate on tools**
> The **LLM is a constant constraint**. OpenAI, Anthropic, Google work day and night on the models; if my agent and yours both use GPT-5.1, the brain is **identical** — no edge there. Where an agent *shines* is its **tools** and **system prompt**, and crucially **how the tools are connected to the model**. That connection is the real engineering surface.

```
LLM      ── constant  (same for everyone using the same model)
tools    ── your edge (what you build + how you wire it)
wiring   ── the hard, universal problem MCP targets
```

---

## 3. The status quo: ad-hoc wiring

Earlier in the course, the Cursor-style / weather agent ([[05 - Building a CLI Coding Assistant]]) had tools like `run_command` / `execute_command`. They were connected by **describing them in a system prompt** ("you have these two tools…") and hand-orchestrating the calls.

That **works** — but it isn't **standardized**:

```
my agent:    tools wired my way (custom prompt + custom loop)
your agent:  tools wired your way (different prompt, different loop)
```

Connecting tools to an agent is a **universal problem** everyone re-solves differently. That redundancy is exactly what MCP attacks.

> [!NOTE]
> **The question MCP asks**
> Every company builds tools and wires them to an LLM. Why should each reinvent that connection? **Standardize it once.**

---

## 4. The USB-C analogy

> [!TIP]
> **MCP is "USB-C for AI tools"**
> USB-C is a **universal cable** — iPhone, MacBook, Android, IoT, Alexa all charge and transfer data over the same connector, regardless of ecosystem. MCP aims to be that for tools: **bring your tools and plug them into any LLM through one common interface.**

```
        USB-C                          MCP
   ┌───────────────┐            ┌─────────────────┐
   │ phone ──┐     │            │ Gmail tools ──┐  │
   │ laptop ─┼─USB-C            │ X/Twitter ────┼─ MCP ── any LLM
   │ tablet ─┘     │            │ Postgres  ────┘  │   (GPT/Gemini/Claude)
   └───────────────┘            └─────────────────┘
   one cable, any device         one protocol, any tool↔model
```

---

## 5. How it plays out

Big companies build **tool servers** over the MCP protocol:

| Company | Example MCP tools |
|---|---|
| Google | `read_email`, `send_email` (Gmail) |
| Twitter/X | `post_tweet`, `repost_tweet`, `reply_to_tweet` |
| …any | whatever their product exposes (40–50+ tools) |

Then **any** agent connects to them through MCP:

```
my GPT-4.1 agent  ──MCP──►  [ Gmail tools, X tools, ... ]
friend's Gemini 2.5 agent ──MCP──►  same tools
```

> [!IMPORTANT]
> **Standardization is the whole point**
> Because MCP is a **common interface**, the same tool server works whether you're on GPT, Gemini, or Claude — just like USB-C is the same across Apple, Android, and Samsung. Tools become **build-once, use-from-any-model**, instead of being re-implemented per agent.

---

## 6. The mental model: REST APIs, but for AI

> MCP is **like REST APIs — a protocol — but for AI tools.**

Big companies already expose **REST APIs** (GET/POST endpoints) so anyone can access their services programmatically. MCP is the analogous idea for **AI agents**: a standard protocol through which an LLM can discover and call a provider's tools.

```
REST API:  apps  ──GET/POST──►  company endpoints
MCP:       LLMs  ──protocol──►  company tool servers
```

---

## 7. Main takeaways

- **Agent = LLM + tools.** The LLM alone is just a next-token predictor.
- The **LLM is a constant** (same model = same brain for everyone); **tools + wiring** are the differentiator.
- Today, tool↔model wiring is **ad-hoc** (e.g. the hand-prompted `run_command` agent).
- **MCP standardizes** that wiring — think **USB-C for AI**.
- Companies build **MCP tool servers** (Gmail, X, Postgres…); any LLM connects via the same protocol.
- It's **standardized** → tools are **build-once, reuse across models**.
- Mental model: **REST APIs, but a protocol for AI tools.**

---

## 8. Things I still want to figure out

- How does an LLM **discover** what tools an MCP server offers?
- What does the **wire format** look like (vs raw REST/JSON)?
- How is **auth** handled to a provider's MCP server?
- How does this compare to plain **function/tool calling** I've already used?

---

## 9. Things to dig into

- **MCP docs**: https://modelcontextprotocol.io/
- **Anthropic MCP announcement**: the origin & rationale.
- Cross-link: the ad-hoc tool wiring in [[05 - Building a CLI Coding Assistant]].

---

## 10. Next up in this section

- [ ] [[03 - MCP from the Docs]] — the formal definition and the Host/Client/Server architecture.

---

## Related
- [[01 - Section Intro - MCP]] — the section framing.
- [[05 - Building a CLI Coding Assistant]] — the ad-hoc tool wiring MCP standardizes.
- [[03 - MCP from the Docs]] — the formal model.

## Sources
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Anthropic: Introducing MCP](https://www.anthropic.com/news/model-context-protocol)
