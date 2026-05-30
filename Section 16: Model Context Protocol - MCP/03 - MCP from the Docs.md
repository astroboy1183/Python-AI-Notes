---
title: MCP from the Docs
date: 2026-05-29
source: "Section 16 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 16: Model Context Protocol - MCP"
tags:
  - mcp
  - architecture
  - mcp-host
  - mcp-client
  - mcp-server
  - foundations
related:
  - "[[02 - The Problem MCP Solves]]"
  - "[[01 - Section Intro - MCP]]"
---

# MCP from the Docs

> [!NOTE]
> **TL;DR**
> MCP was introduced by **Anthropic** (the company behind Claude) on **25 Nov 2024** as an open standard for **connecting AI assistants to where data lives** — content repositories, business tools, dev environments. The problem it names: even great models are **isolated from data**, and wiring up every new data source with a **custom implementation** doesn't scale (you can't retrain the model on everything). MCP is the **"USB-C port for AI applications"** — one standardized way to plug models into any data source (Postgres, MongoDB, Google Search, Snowflake, Kafka, …). Architecture = **three components**: the **MCP Host** (the AI app, e.g. your IDE), the **MCP Client** (lives inside the host, holds a 1:1 connection to a server), and the **MCP Server** (the remote tool/data provider, e.g. GitHub, Hugging Face, Notion, Figma, Playwright). A host runs multiple clients, each connected to one server.

> [!NOTE]
> **Where this fits**
> Third and final note of **Section 16** — the formal documentation view of the concept introduced in [[02 - The Problem MCP Solves]]. It closes out the course.

---

## 1. Origin

- **Who:** introduced by **Anthropic** (makers of Claude).
- **When:** **25 November 2024** — open-sourced.
- **What:** *"a new standard for connecting AI assistants to where data lives"* — a polished way of saying **tools and data sources**: content repositories, business tools, development environments.

---

## 2. The problem, in the docs' words

Even the most sophisticated models are **constrained by isolation from data**:

- Models are trained once; **new data sources appear constantly**.
- Each new source has historically needed its **own custom integration**.
- That makes systems **hard to scale** — you can't keep retraining the model on fresh data.

> [!IMPORTANT]
> **MCP = a universal open standard for connecting AI systems to data sources**
> Instead of N bespoke integrations, MCP gives **one** standard. Connect it to Postgres, MongoDB, a website, Snowflake, a data stream — and the model gains access to that source through the same protocol.

```
without MCP:  model ── custom glue ──► Postgres
              model ── custom glue ──► MongoDB     (N one-off integrations)
              model ── custom glue ──► Snowflake

with MCP:     model ──┬─MCP─► Postgres
                      ├─MCP─► MongoDB
                      ├─MCP─► Google Search
                      └─MCP─► Snowflake / Kafka     (one standard)
```

Connect a Postgres MCP → the LLM can query Postgres. Add a MongoDB MCP → it can query MongoDB. Add Google Search / Snowflake → those too. Each connection extends the model's reach without retraining.

---

## 3. The official one-liner

> MCP is an open protocol that **standardizes how applications provide context to LLMs.** Think of MCP like a **USB-C port for AI applications** — just as USB-C standardizes connecting devices to peripherals, MCP standardizes connecting AI models to different data sources.

The word that keeps repeating: **standardized** (the same theme as [[02 - The Problem MCP Solves]]).

---

## 4. The three core components

MCP has **three** parts:

| Component | What it is | Example |
|---|---|---|
| **MCP Host** | The **AI application** itself | An IDE running an agent; Claude Desktop |
| **MCP Client** | A connector **inside the host** that holds a **1:1** link to a server | The IDE's MCP client/setting |
| **MCP Server** | The **remote tool/data provider** | GitHub, Hugging Face, Notion, Figma, Playwright |

```
┌──────────────────────── MCP Host (the AI app, e.g. IDE) ─────────────────────┐
│                                                                              │
│   ┌────────────┐        ┌────────────┐        ┌────────────┐                 │
│   │ MCP Client │        │ MCP Client │        │ MCP Client │                 │
│   └─────┬──────┘        └─────┬──────┘        └─────┬──────┘                 │
└─────────┼─────────────────────┼────────────────────┼────────────────────────┘
          │ 1:1                  │ 1:1                 │ 1:1
          ▼                      ▼                     ▼
   ┌─────────────┐        ┌─────────────┐       ┌─────────────┐
   │ MCP Server  │        │ MCP Server  │       │ MCP Server  │
   │ (file system)│       │ (database)  │       │ (GitHub)    │
   └─────────────┘        └─────────────┘       └─────────────┘
```

### Host
The AI application — e.g. an IDE with an agent running, or Claude Desktop. **You interact with the host.**

### Client
Lives **inside** the host. An IDE typically has an **MCP setting** where you *add a server* / *browse MCP servers*. Each client maintains a **one-to-one connection** to a single server.

### Server
The thing you connect **to** — a remote provider of tools/data. Could be GitHub's server, Hugging Face's, Notion's, or any MCP server you choose.

> [!TIP]
> **One host, many clients, many servers**
> A single host runs **multiple MCP clients**, each holding a **1:1** connection to a different MCP server (file system, database, GitHub, …). That's how one AI app can simultaneously reach many tool/data providers.

---

## 5. The growing server ecosystem

Modern IDEs/hosts ship a **registry** of MCP servers to install — GitHub, Hugging Face, Figma, Playwright, Linear, Notion, DeepWiki, and more. Companies are increasingly **exposing their own MCP servers**.

```
browse servers → pick one (e.g. GitHub) → install → agent now has its tools
                                                       (PRs, issues, …)
```

Install GitHub's MCP and the agent can see pull requests, issues, etc.; install another and it gains that provider's capabilities — all through the same client interface.

---

## 6. The full picture

```
You ──► MCP Host (AI app / IDE)
            │  contains
            ▼
        MCP Client(s)  ──1:1──►  MCP Server(s)  ──►  tools + data
                                  (GitHub, DB,        (PRs, queries,
                                   file system, …)     files, …)
```

- **Host** = where you work (the AI app).
- **Client** = the connector inside it.
- **Server** = the tool/data provider you plug into.

---

## 7. Main takeaways

- MCP was introduced by **Anthropic** on **25 Nov 2024** as an open standard.
- It connects AI assistants to **where data lives** (repos, business tools, dev envs).
- Problem: models are **isolated from data**; per-source **custom integrations don't scale**.
- MCP = a **universal open standard** — the **"USB-C port for AI applications."**
- Three components: **Host** (AI app), **Client** (connector inside the host, 1:1 to a server), **Server** (remote tool/data provider).
- **One host → many clients → many servers** (each client 1:1 with a server).
- A **growing registry** of MCP servers exists (GitHub, Hugging Face, Notion, Figma, Playwright…).

---

## 8. Things I still want to figure out

- The actual **transport** (stdio vs HTTP/SSE) between client and server?
- Beyond tools, MCP also exposes **resources** and **prompts** — how do those work?
- How does an agent **decide which** MCP tool to call (vs normal tool calling)?
- **Security** — how is access to a server's tools/data scoped and authorized?
- How to **build my own** MCP server for a custom tool/data source?

---

## 9. Things to dig into

- **MCP docs / architecture**: https://modelcontextprotocol.io/
- **Anthropic announcement**: https://www.anthropic.com/news/model-context-protocol
- **Example servers** (reference implementations): file system, GitHub, Postgres.
- **Hands-on**: install an MCP server (e.g. GitHub) in an MCP-capable host and let an agent use it.

---

## 10. Section & course wrap-up

Section 16 closes the course: MCP is the **standardization layer** for connecting tools and data to LLMs — the natural endpoint after building agents, RAG, memory, graphs, and voice. With **Host / Client / Server** and the **USB-C** mental model, MCP turns the ad-hoc tool wiring from [[02 - The Problem MCP Solves]] into a reusable, cross-model standard — tools you (or whole companies) build once and any agent can use.

---

## Related
- [[02 - The Problem MCP Solves]] — the motivation this formalizes.
- [[01 - Section Intro - MCP]] — the section opener.

## Sources
- [Model Context Protocol docs](https://modelcontextprotocol.io/)
- [Anthropic: Introducing MCP](https://www.anthropic.com/news/model-context-protocol)
