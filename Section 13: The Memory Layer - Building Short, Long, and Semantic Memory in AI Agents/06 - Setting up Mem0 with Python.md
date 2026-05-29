---
title: Setting up Mem0 with Python
date: 2026-05-29
source: "Section 13 / Lecture 6"
type: lecture-notes
status: in-progress
section: "Section 13: The Memory Layer - Building Short, Long, and Semantic Memory in AI Agents"
tags:
  - mem0
  - memory
  - python
  - installation
  - hands-on
related:
  - "[[05 - Semantic Memory in LLMs]]"
  - "[[07 - Configuring the Mem0 Memory Client]]"
---

# Setting up Mem0 with Python

> [!NOTE]
> **TL;DR**
> Time to make the memory theory concrete. **Mem0** (`mem0ai`) is a memory layer for LLM apps — it extracts facts from conversations, stores them, and retrieves the relevant ones later. Install it with `pip install mem0ai`, then freeze. Basic usage is dead simple: `from mem0 import Memory`, set `OPENAI_API_KEY`, and `memory.add(messages, user_id=..., metadata=...)`. But the bare default isn't how this build will run — instead Mem0 gets configured to use **Qdrant** as the vector store so memories persist in a real vector DB. This note is just the install + a read-through of the Python SDK quickstart; the actual configuration comes next.

> [!NOTE]
> **Where this fits**
> Sixth note of **Section 13** and the start of the **hands-on** half. Notes 00–05 covered memory *concepts* (short/long-term, factual, episodic, semantic). From here on it's implementation with Mem0 + Qdrant. The full config is in [[07 - Configuring the Mem0 Memory Client]].

---

## 1. What Mem0 is

Mem0 is a drop-in **memory layer** for LLM applications. Instead of me hand-rolling fact extraction and vector storage, Mem0 does it:

```
conversation ──► Mem0 ──► extracts facts ──► stores as vectors ──► retrieves relevant ones later
```

It's the practical realization of the **semantic / factual memory** ideas from [[03 - Factual Memory in LLMs]] and [[05 - Semantic Memory in LLMs]] — distill durable facts about the user, store them, recall them on demand.

---

## 2. Installation

```bash
pip install mem0ai
pip freeze > requirements.txt
```

The package name is `mem0ai`; the import is `mem0`. Working in the same project as the LangGraph work (a `cd ..` up from the LangGraph folder is enough to reuse the environment).

> [!NOTE]
> **Package vs import name**
> Install **`mem0ai`** but import **`mem0`** (`from mem0 import Memory`). Easy mismatch to trip on.

---

## 3. The docs to skim

The Mem0 docs (`docs.mem0.ai`) include examples, memory types, and — the part that matters — the **Python SDK → Quickstart**. Worth reading the quickstart through once before configuring anything; there's nothing to code yet, just orientation.

| Doc section | Why |
|---|---|
| Memory types | Maps onto the concepts from notes 00–05 |
| Python SDK quickstart | The install + basic usage shown here |
| Configuration | The embedder / LLM / vector-store setup (next note) |

---

## 4. Basic usage (the simplest form)

The quickstart's minimal example:

```python
from mem0 import Memory

# OPENAI_API_KEY must be set in the environment
memory = Memory()

memory.add(
    messages,
    user_id="jayanth",
    metadata={...},
)
```

- `Memory()` — a memory client with sensible defaults.
- `add(messages, user_id=..., metadata=...)` — store a conversation; Mem0 extracts facts from it.

This works out of the box, but the defaults use an in-process store. For something real and inspectable, the build swaps in **Qdrant**.

---

## 5. Why not just use the default?

> [!IMPORTANT]
> **Default store vs Qdrant**
> The bare `Memory()` is fine for a quick test, but this section configures Mem0 to use **Qdrant** as the vector store. Reasons: memories live in a real, persistent vector DB; I can open the Qdrant dashboard and *see* the stored facts; and it mirrors a production setup. So the next note builds an explicit configuration rather than relying on defaults.

```
default Memory()          configured Memory.from_config(...)
────────────────          ─────────────────────────────────
quick, opaque             explicit embedder + LLM + Qdrant
fine for a demo           persistent, inspectable, prod-shaped
```

---

## 6. Main takeaways

- **Mem0** (`mem0ai`) is a memory layer that **extracts, stores, and retrieves** facts for LLM apps.
- Install `mem0ai`, **import `mem0`**.
- Minimal usage: `Memory()` + `memory.add(messages, user_id=..., metadata=...)`.
- Needs `OPENAI_API_KEY` in the environment.
- This build won't use the bare default — it configures Mem0 with **Qdrant** as the vector store.
- This note is just install + skim the **Python SDK quickstart**.

---

## 7. Things I still want to figure out

- What exactly does `add` **extract** — and how does it decide what's a "fact"?
- How does Mem0 handle **contradictions** (I say X, later say not-X)?
- What does a stored memory **document** look like in the vector DB?
- How is retrieval scored — pure vector similarity, or something more?

---

## 8. Things to dig into

- **Mem0 Python SDK quickstart**: https://docs.mem0.ai/
- **Mem0 memory types** — compare against notes 00–05.
- Cross-link: [[03 - Factual Memory in LLMs]], [[05 - Semantic Memory in LLMs]].

---

## 9. Next up in this section

- [ ] [[07 - Configuring the Mem0 Memory Client]] — the embedder / LLM / Qdrant configuration.

---

## Related
- [[05 - Semantic Memory in LLMs]] — the concept Mem0 implements.
- [[07 - Configuring the Mem0 Memory Client]] — the configuration step.

## Sources
- [Mem0 documentation](https://docs.mem0.ai/)
