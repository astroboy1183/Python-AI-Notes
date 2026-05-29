---
title: Configuring the Mem0 Memory Client
date: 2026-05-29
source: "Section 13 / Lecture 7"
type: lecture-notes
status: in-progress
section: "Section 13: The Memory Layer - Building Short, Long, and Semantic Memory in AI Agents"
tags:
  - mem0
  - configuration
  - embeddings
  - qdrant
  - vector-store
  - hands-on
related:
  - "[[06 - Setting up Mem0 with Python]]"
  - "[[08 - Setting up Qdrant for Mem0]]"
---

# Configuring the Mem0 Memory Client

> [!NOTE]
> **TL;DR**
> Build an explicit Mem0 config — a dict with **three** blocks plus a version. **`embedder`**: OpenAI, `text-embedding-3-small`, with the API key (read from the env). **`llm`**: OpenAI, `gpt-4.1`, used to *extract* facts/memories from conversations. **`vector_store`**: Qdrant at `localhost:6333`. Set `version: "v1.1"`. Then create the client with `memory = Memory.from_config(config)`. That single client object is what I'll use to `add` and `search` memories. The split is the key insight: an **embedding model** turns text into vectors, an **LLM** decides *what* is worth remembering, and a **vector store** holds the results.

> [!NOTE]
> **Where this fits**
> Seventh note of **Section 13**. It builds the Mem0 client configured for Qdrant (installed in [[06 - Setting up Mem0 with Python]]). [[08 - Setting up Qdrant for Mem0]] stands up the Qdrant container the config points at.

---

## 1. The file

A new agent file: `memory.py`. The goal is to create a configured **memory client**.

```python
import os
from mem0 import Memory
```

---

## 2. The config has three jobs

Mem0 needs to know three things, each its own config block:

```
┌─────────────┐   ┌─────────────┐   ┌──────────────┐
│  embedder   │   │     llm     │   │ vector_store │
│ text → vec  │   │ extract     │   │ store/recall │
│             │   │ facts       │   │ the vectors  │
└─────────────┘   └─────────────┘   └──────────────┘
```

| Block | Question it answers | Choice here |
|---|---|---|
| `embedder` | How to turn text into vectors? | OpenAI `text-embedding-3-small` |
| `llm` | What model extracts the memories? | OpenAI `gpt-4.1` |
| `vector_store` | Where to store the vectors? | Qdrant @ `localhost:6333` |

Plus a top-level `version: "v1.1"` (from the docs).

---

## 3. The embedder block

How text becomes vector embeddings:

```python
config = {
    "version": "v1.1",
    "embedder": {
        "provider": "openai",
        "config": {
            "api_key": os.environ.get("OPENAI_API_KEY"),
            "model": "text-embedding-3-small",
        },
    },
    # ... llm, vector_store below
}
```

- `provider: "openai"` — use OpenAI for embeddings.
- `api_key` — pulled from the environment via `os.environ.get("OPENAI_API_KEY")` (so it never sits in code).
- `model: "text-embedding-3-small"` — the embedding model.

---

## 4. The llm block

Which model **extracts memories** (facts) from a conversation:

```python
    "llm": {
        "provider": "openai",
        "config": {
            "api_key": os.environ.get("OPENAI_API_KEY"),
            "model": "gpt-4.1",
        },
    },
```

Same provider/config shape as the embedder — the only difference is `model: "gpt-4.1"`.

> [!IMPORTANT]
> **Two different models, two different jobs**
> The **embedder** (`text-embedding-3-small`) converts text into vectors for similarity search. The **LLM** (`gpt-4.1`) *reads* a conversation and decides which facts are worth remembering (e.g. "the user's name is Jayanth", "likes pizza"). They're not interchangeable — embeddings measure similarity; the LLM does the reasoning about *what* to store.

---

## 5. The vector_store block

Where the memory vectors live:

```python
    "vector_store": {
        "provider": "qdrant",
        "config": {
            "host": "localhost",
            "port": 6333,
        },
    },
```

- `provider: "qdrant"` — use Qdrant as the store.
- `host: "localhost"`, `port: 6333` — where Qdrant runs (stood up in [[08 - Setting up Qdrant for Mem0]]).

---

## 6. The complete config + client

```python
import os
from mem0 import Memory

config = {
    "version": "v1.1",
    "embedder": {
        "provider": "openai",
        "config": {
            "api_key": os.environ.get("OPENAI_API_KEY"),
            "model": "text-embedding-3-small",
        },
    },
    "llm": {
        "provider": "openai",
        "config": {
            "api_key": os.environ.get("OPENAI_API_KEY"),
            "model": "gpt-4.1",
        },
    },
    "vector_store": {
        "provider": "qdrant",
        "config": {
            "host": "localhost",
            "port": 6333,
        },
    },
}

memory = Memory.from_config(config)
```

`Memory.from_config(config)` returns the **memory client**. With it I can `add` memories and `search` them — the subject of [[09 - Building a Memory-Aware Assistant]].

---

## 7. How the pieces work together

```
add a conversation
        │
        ▼
   ┌─────────┐  "what's worth remembering?"
   │  llm    │  (gpt-4.1 extracts facts)
   └────┬────┘
        ▼  fact: "user's name is Jayanth"
   ┌──────────┐  text → vector
   │ embedder │  (text-embedding-3-small)
   └────┬─────┘
        ▼  [0.12, -0.04, ...]
   ┌──────────────┐
   │ vector_store │  Qdrant stores the vector + fact
   └──────────────┘
```

On retrieval the flow reverses: a query is embedded and matched against the stored vectors to pull back the most **relevant** memories.

---

## 8. Common gotchas

> [!WARNING]
> **Config issues**

| Symptom | Cause | Fix |
|---|---|---|
| `api_key` is `None` | Env not loaded / var missing | Load `.env`; check `OPENAI_API_KEY` |
| Connection refused to Qdrant | Qdrant not running | `docker compose up -d` (note 08) |
| Wrong embedding dimensions | Model mismatch vs existing collection | Keep the embedder model consistent |
| Version error | Missing/old `version` | Set `"version": "v1.1"` |
| Import error | Imported `mem0ai` not `mem0` | `from mem0 import Memory` |

---

## 9. Main takeaways

- Mem0 config = `version` + **three blocks**: `embedder`, `llm`, `vector_store`.
- `embedder`: OpenAI `text-embedding-3-small` — text → vectors.
- `llm`: OpenAI `gpt-4.1` — **extracts** facts/memories from conversations.
- `vector_store`: Qdrant at `localhost:6333` — holds the vectors.
- API keys read from the env via `os.environ.get(...)` — not hardcoded.
- Set `version: "v1.1"`.
- Create the client: `memory = Memory.from_config(config)`.
- Embedder ≠ LLM: one measures similarity, the other decides *what* to remember.

---

## 10. Things I still want to figure out

- Can the embedder/LLM/store providers be **mixed** (e.g. Gemini LLM + OpenAI embeddings)?
- What collection name does Mem0 create in **Qdrant**, and can I set it?
- How does the **LLM cost** of extraction add up over a long chat?
- Are there **local** provider options (Ollama embeddings/LLM) for offline use?

---

## 11. Things to dig into

- **Mem0 configuration docs**: https://docs.mem0.ai/
- **Qdrant + Mem0 integration** specifics.
- Cross-link: RAG embedding/Qdrant work from Section 8.

---

## 12. Next up in this section

- [ ] [[08 - Setting up Qdrant for Mem0]] — spin up the Qdrant container this config points at.

---

## Related
- [[06 - Setting up Mem0 with Python]] — installing Mem0.
- [[08 - Setting up Qdrant for Mem0]] — the vector store backend.
- [[09 - Building a Memory-Aware Assistant]] — using this client.

## Sources
- [Mem0 configuration](https://docs.mem0.ai/)
- [Qdrant documentation](https://qdrant.tech/documentation/)
