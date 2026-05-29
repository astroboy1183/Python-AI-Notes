---
title: Setting up Qdrant for Mem0
date: 2026-05-29
source: "Section 13 / Lecture 8"
type: lecture-notes
status: in-progress
section: "Section 13: The Memory Layer - Building Short, Long, and Semantic Memory in AI Agents"
tags:
  - qdrant
  - docker
  - vector-store
  - mem0
  - infrastructure
  - hands-on
related:
  - "[[07 - Configuring the Mem0 Memory Client]]"
  - "[[09 - Building a Memory-Aware Assistant]]"
---

# Setting up Qdrant for Mem0

> [!NOTE]
> **TL;DR**
> Mem0's config points at Qdrant on `localhost:6333`, so Qdrant has to be running. This is the same Qdrant-in-Docker setup from the RAG section — reuse the `docker-compose.yml`, drop it in the memory-agent folder, and `docker compose up -d`. That spins up Qdrant on **6333**. Open the dashboard at `http://localhost:6333/dashboard` to confirm it's live — right now it's **empty** (no collections, no memories), which is exactly right before any memories are added. With Qdrant up, the next note actually writes and reads memories through it.

> [!NOTE]
> **Where this fits**
> Eighth note of **Section 13**. It provisions the vector store the Mem0 config in [[07 - Configuring the Mem0 Memory Client]] expects. [[09 - Building a Memory-Aware Assistant]] then fills it with memories.

---

## 1. Why Qdrant is needed here

The `vector_store` block from [[07 - Configuring the Mem0 Memory Client]] said:

```python
"vector_store": {
    "provider": "qdrant",
    "config": {"host": "localhost", "port": 6333},
}
```

So Mem0 will try to connect to Qdrant at `localhost:6333` the moment it stores or searches a memory. If nothing's listening there, every `add`/`search` fails with a connection error. Qdrant must be up first.

```
Mem0 client ──(localhost:6333)──► Qdrant ──► stores memory vectors
```

---

## 2. Reusing the Docker Compose from RAG

This is the **same Qdrant container** used in the RAG section — no new config to invent. Copy the existing `docker-compose.yml` into the memory-agent folder:

```yaml
# docker-compose.yml
services:
  qdrant:
    image: qdrant/qdrant
    ports:
      - "6333:6333"
    volumes:
      - qdrant_data:/qdrant/storage

volumes:
  qdrant_data:
```

| Piece | Meaning |
|---|---|
| `image: qdrant/qdrant` | Official Qdrant image |
| `ports: "6333:6333"` | Expose Qdrant's REST/dashboard port |
| `volumes: qdrant_data` | Persist stored vectors across restarts |

> [!TIP]
> **Same pattern as every other service in this course**
> Provisioning infra is consistently: a small `docker-compose.yml`, `docker compose up -d`, then verify. Qdrant here, Valkey in the async-RAG section, MongoDB in the checkpointing section — same muscle memory.

---

## 3. Bringing it up

From the memory-agent folder (Docker engine running):

```bash
docker compose up -d
```

`-d` runs detached. Qdrant starts on port **6333**.

---

## 4. Verifying via the dashboard

Qdrant ships a web dashboard:

```
http://localhost:6333/dashboard
```

Opening it now shows **nothing** — no collections, no points, no memories. That's the correct state: I haven't added anything yet.

```
Qdrant dashboard (now)        Qdrant dashboard (after note 09)
──────────────────────        ───────────────────────────────
(empty — no collections)  ──► mem0 collection with memory points
```

Seeing it empty is useful — in the next note I'll add a memory, refresh, and watch a `mem0` collection appear with the extracted fact. That visual confirmation is half the point of using a real vector DB instead of the opaque default store.

---

## 5. Common gotchas

> [!WARNING]
> **Qdrant setup issues**

| Symptom | Cause | Fix |
|---|---|---|
| `Connection refused` from Mem0 | Qdrant not running | `docker compose up -d` |
| Port 6333 in use | Another Qdrant already up | Stop it, or remap the host port |
| Dashboard 404 | Wrong URL | Use `/dashboard` suffix |
| Memories vanish on restart | No volume | Add the `qdrant_data` volume |
| Wrong host/port in Mem0 | Config mismatch | Match `localhost:6333` in the config |

---

## 6. Main takeaways

- Mem0's config targets **Qdrant @ localhost:6333**, so Qdrant must be running.
- Reuse the **RAG section's `docker-compose.yml`** — same Qdrant container.
- Bring it up with `docker compose up -d` (port 6333).
- Verify at **`http://localhost:6333/dashboard`** — it's **empty** until memories are added.
- The persistent **volume** keeps stored vectors across restarts.
- Empty-now is the expected starting state.

---

## 7. Things I still want to figure out

- What **collection name** will Mem0 create, and what's its vector dimension?
- Can I browse individual **memory points** in the dashboard (payload + vector)?
- Does Qdrant need **auth** for anything beyond local dev?
- How does Mem0 handle the collection if the **embedding dimension** changes?

---

## 8. Things to dig into

- **Qdrant dashboard / quickstart**: https://qdrant.tech/documentation/
- Cross-link: the original Qdrant setup in Section 8 (RAG).
- How Mem0 maps a "memory" onto a Qdrant **point** (id + vector + payload).

---

## 9. Next up in this section

- [ ] [[09 - Building a Memory-Aware Assistant]] — add and retrieve memories through this Qdrant.

---

## Related
- [[07 - Configuring the Mem0 Memory Client]] — the config pointing here.
- [[09 - Building a Memory-Aware Assistant]] — filling Qdrant with memories.

## Sources
- [Qdrant documentation](https://qdrant.tech/documentation/)
- [Mem0 documentation](https://docs.mem0.ai/)
