---
title: Adding Neo4j Graph Store to Mem0
date: 2026-05-29
source: "Section 14 / Lecture 7"
type: lecture-notes
status: in-progress
section: "Section 14: Graph Memory and Knowledge Graphs In AI Agents"
tags:
  - mem0
  - neo4j
  - graph-store
  - configuration
  - hands-on
related:
  - "[[07 - Configuring the Mem0 Memory Client]]"
  - "[[06 - Cypher Queries]]"
  - "[[08 - Building the Knowledge Graph]]"
---

# Adding Neo4j Graph Store to Mem0

> [!NOTE]
> **TL;DR**
> Mem0 already had `embedder`, `llm`, and `vector_store` (Qdrant). To enable graph memory, add **one more block: `graph_store`**. Provider = `neo4j`, with a config carrying the **url** (the Aura connection URI), **username** (`neo4j`), and **password** (from Aura). After this, the same Mem0 client gains a **graph store alongside** the vector store — it can persist relationships in Neo4j, not just facts in Qdrant. Best practice: load url/user/password from env vars rather than hardcoding. No new client API — just an extra config block.

> [!NOTE]
> **Where this fits**
> Seventh note of **Section 14**. It extends the Mem0 config from [[07 - Configuring the Mem0 Memory Client]] with the Neo4j Aura instance from [[05 - Setting up Neo4j Aura]]. [[08 - Building the Knowledge Graph]] runs it and watches the graph populate.

---

## 1. The one addition: `graph_store`

The Section 13 config had three blocks. Graph memory adds a **fourth**:

```
embedder       (text → vectors)
llm            (extract facts / relationships)
vector_store   (Qdrant — stores facts)
graph_store    (Neo4j — stores relationships)   ◄── NEW
```

Nothing else changes — the embedder, llm, and vector_store stay exactly as they were.

---

## 2. The connection URI

From the Aura instance's connection details ([[05 - Setting up Neo4j Aura]]), copy the **connection URI** and stash it:

```
NEO4J_URI = neo4j+s://<id>.databases.neo4j.io
```

---

## 3. The `graph_store` block

```python
"graph_store": {
    "provider": "neo4j",
    "config": {
        "url": "neo4j+s://<id>.databases.neo4j.io",   # the Aura URI
        "username": "neo4j",                            # default Aura user
        "password": "<the-aura-password>",
    },
}
```

| Field | Value |
|---|---|
| `provider` | `"neo4j"` |
| `url` | the Aura connection URI |
| `username` | `neo4j` (Aura default) |
| `password` | the password copied at instance creation |

> [!TIP]
> **Load credentials from the environment**
> Hardcoding the url/username/password works for a quick test, but the right move is to read them from env vars (the same `.env` they were saved into). Keeps secrets out of code and out of the public repo.

```python
import os
"graph_store": {
    "provider": "neo4j",
    "config": {
        "url": os.environ.get("NEO4J_URI"),
        "username": os.environ.get("NEO4J_USERNAME"),
        "password": os.environ.get("NEO4J_PASSWORD"),
    },
}
```

---

## 4. The full config (vector + graph)

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
        "config": {"host": "localhost", "port": 6333},
    },
    "graph_store": {                                 # ← the new block
        "provider": "neo4j",
        "config": {
            "url": os.environ.get("NEO4J_URI"),
            "username": os.environ.get("NEO4J_USERNAME"),
            "password": os.environ.get("NEO4J_PASSWORD"),
        },
    },
}

memory = Memory.from_config(config)
```

The client construction is unchanged (`Memory.from_config(config)`) — it just now has **both** stores.

---

## 5. What the dual store does

```
              add a conversation
                     │
                     ▼
              ┌────────────┐  extracts...
              │  llm gpt-4.1│
              └─────┬───────┘
        facts ◄─────┴─────► relationships
          │                       │
          ▼                       ▼
   ┌──────────────┐        ┌──────────────┐
   │ Qdrant       │        │ Neo4j        │
   │ (vector_store)│       │ (graph_store)│
   │ "likes pizza"│        │ (User)-[:LIKES]->(pizza)
   └──────────────┘        └──────────────┘
```

The same extraction LLM now feeds **two** stores: facts as vectors into Qdrant, and **entities + relationships** as a graph into Neo4j. Recall can draw on both.

---

## 6. Common gotchas

> [!WARNING]
> **Graph store config issues**

| Symptom | Cause | Fix |
|---|---|---|
| Auth failure to Neo4j | Wrong url/user/password | Match the exact Aura URI + credentials |
| Connection refused/timeout | URI scheme wrong | Use `neo4j+s://...` (secure) |
| Import / provider error | Missing Neo4j integration package | Install it (see [[08 - Building the Knowledge Graph]]) |
| Secrets in repo | Hardcoded credentials | Load from env / `.env` (gitignored) |
| Free instance asleep | Aura free tier paused | Resume from the dashboard |

---

## 7. Main takeaways

- Graph memory = **one extra `graph_store` block** in the Mem0 config.
- `provider: "neo4j"` + `config` with **url** (Aura URI), **username** (`neo4j`), **password**.
- The other three blocks (embedder/llm/vector_store) are **unchanged**.
- Construction is the same: `Memory.from_config(config)` — now with **both** stores.
- **Load credentials from env vars**, don't hardcode.
- The extraction LLM now feeds **facts → Qdrant** and **relationships → Neo4j**.

---

## 8. Things I still want to figure out

- Does Mem0 **require both** stores, or can it run graph-only?
- How does Mem0 decide **what's a node vs a relationship** during extraction?
- Are graph writes **synchronous** with vector writes, or separate?
- What extra **packages** does the Neo4j provider need? (Next note.)

---

## 9. Things to dig into

- **Mem0 graph memory config**: https://docs.mem0.ai/
- **Neo4j connection URIs / drivers**: https://neo4j.com/docs/
- Next: install the integration packages and run it.

---

## 10. Next up in this section

- [ ] [[08 - Building the Knowledge Graph]] — install the Neo4j packages, run the client, watch the graph build itself.

---

## Related
- [[07 - Configuring the Mem0 Memory Client]] — the original 3-block config.
- [[05 - Setting up Neo4j Aura]] — where the URL/credentials come from.
- [[08 - Building the Knowledge Graph]] — running this config.

## Sources
- [Mem0 documentation](https://docs.mem0.ai/)
- [Neo4j drivers](https://neo4j.com/docs/)
