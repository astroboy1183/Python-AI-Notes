---
title: Setting up Qdrant with Docker
date: 2026-05-28
source: "Section 8 / Lecture 6"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - qdrant
  - vector-database
  - docker
  - docker-compose
  - rag
  - infrastructure
  - hands-on
related:
  - "[[04 - The Indexing Phase]]"
  - "[[02 - Docker Deep Dive]]"
  - "[[03 - Running Ollama in Docker]]"
---

# Setting up Qdrant with Docker

> [!NOTE]
> **TL;DR**
> First infrastructure step of the implementation: spin up a local **Qdrant** vector database via **Docker Compose**. Brief tour of the vector-DB landscape (Pinecone, Weaviate, Chroma, pgvector, Qdrant) and why this section picks **Qdrant** — open source, lightweight, fast, easy local setup. Create a `docker-compose.yml` declaring one service (`vector-db`) using the `qdrant/qdrant` image and exposing port **6333**. Bring it up with `docker compose up -d`. The Qdrant web UI becomes available at `localhost:6333/dashboard` showing collections, segments, and stored vectors. From here, the indexing code ([[10 - Creating Vector Embeddings and Storing in Qdrant]]) and retrieval code ([[11 - Building the Retrieval (chat.py)]]) connect to this database.

> [!NOTE]
> **Where this fits**
> Sixth lecture of **Section 8: Building Chat with PDF Project using RAG**. First hands-on step. The next four notes use LangChain to populate this database from a PDF. Note 11 queries it for retrieval.

---

## 1. The vector-DB landscape

Quick survey of options (covered in [[04 - The Indexing Phase]] but worth repeating):

| Database | Hosting | Open source | Notes |
|---|---|---|---|
| **Pinecone** | Managed only | ❌ | Easiest cloud option, $ |
| **Weaviate** | Self-host or cloud | ✅ | Strong hybrid search |
| **Qdrant** | Self-host or cloud | ✅ | **Lightweight, fast** ← section pick |
| **Chroma** | Self-host (embedded) | ✅ | Simplest, in-process |
| **Milvus** | Self-host or cloud | ✅ | Scale-out, big data |
| **pgvector** | Postgres extension | ✅ | Reuse Postgres infra |
| **Elasticsearch** | Self-host or cloud | Hybrid | Search-engine pedigree |
| **Redis** | Self-host or cloud | Hybrid | In-memory speed |

My pick: **Qdrant** — very easy to set up, lightweight, and fast. The knowledge is transferable too — at the end of the day these are just databases. Switching from Qdrant to Pinecone or Weaviate later changes maybe 20 lines of code. The architecture stays identical.

---

## 2. Why Qdrant specifically

| Reason | Detail |
|---|---|
| **Open source** (Apache 2.0) | Free, hackable, no vendor lock |
| **Single binary** | No external dependencies (unlike Milvus's etcd + MinIO requirements) |
| **Fast** | Written in Rust; competitive on benchmarks |
| **Docker-friendly** | One-line setup |
| **Built-in web UI** | Visualize collections without writing code |
| **Good Python SDK** | First-class LangChain integration |
| **Cloud option** | Same engine on Qdrant Cloud if/when needed |

Trade-offs:
- Less mature than Pinecone in the SaaS / enterprise market.
- Smaller community than Pinecone or Weaviate.
- For really large scale (billions of vectors), Milvus or specialized services win.

For learning, prototyping, and small-to-medium prod loads → **Qdrant is great**.

---

## 3. Prerequisites

Already covered in earlier notes:

| Requirement | Where covered |
|---|---|
| Docker Desktop installed and running | [[02 - Docker Deep Dive]] |
| Familiarity with `docker compose up` | [[03 - Running Ollama in Docker]] |
| Basic CLI navigation | (general) |

Confirm Docker is running before proceeding:

```bash
docker --version
docker ps
```

If both work, Docker is good. The Docker Desktop GUI should also show "Engine: running."

---

## 4. The Docker Compose file

Create a project folder `rag/` and inside it create `docker-compose.yml`:

```yaml
services:
  vector-db:
    image: qdrant/qdrant
    ports:
      - 6333:6333
```

That's the minimum viable setup. Explanation:

| Line | What it does |
|---|---|
| `services:` | Docker Compose syntax — define services |
| `vector-db:` | Logical name for the service |
| `image: qdrant/qdrant` | Use the official Qdrant image from Docker Hub |
| `ports: - 6333:6333` | Map host port 6333 → container port 6333 (Qdrant's API) |

For a production setup, add **volume mount** for persistence:

```yaml
services:
  vector-db:
    image: qdrant/qdrant
    ports:
      - 6333:6333
      - 6334:6334     # gRPC port (optional)
    volumes:
      - qdrant_data:/qdrant/storage     # persist vectors across container restarts

volumes:
  qdrant_data:
```

Without the volume mount, all indexed vectors **disappear** when the container restarts. For learning, that's fine — re-index in 30 seconds. For real use, add persistence.

---

## 5. Bring it up

From the project folder:

```bash
cd rag
docker compose up
```

What happens:
- Docker pulls the `qdrant/qdrant` image (~150-200 MB, one-time).
- Container starts.
- Qdrant boots up.
- Console shows live logs.
- Port 6333 becomes reachable on the host.

First run takes a little longer because Docker has to pull the Qdrant image. Once that's done, Qdrant is up and running.

The terminal stays attached to the logs. Press **Ctrl-C** → container stops.

For background (detached) mode:

```bash
docker compose up -d
```

The `-d` flag = detached = runs in background, terminal frees up. Use this for actual work.

---

## 6. Verification

### Via CLI

```bash
docker ps
```

Should show `qdrant/qdrant` running with port 6333 exposed.

```bash
curl http://localhost:6333
```

Should return JSON metadata about the running Qdrant instance.

### Via the web UI

Visit:

```
http://localhost:6333/dashboard
```

The Qdrant web dashboard loads — useful for visual inspection:

| Tab | What's there |
|---|---|
| **Collections** | List of vector collections (empty until indexing happens) |
| **Cluster** | Cluster nodes (just one for local) |
| **Console** | Run API requests interactively |

The dashboard becomes much more interesting after the indexing notes (10+).

---

## 7. Common commands

For day-to-day use:

| Command | Purpose |
|---|---|
| `docker compose up -d` | Start in background |
| `docker compose down` | Stop and remove containers |
| `docker compose down -v` | Stop + remove containers + delete volumes (wipes data) |
| `docker compose logs -f` | Tail live logs |
| `docker compose restart` | Quick restart |
| `docker compose ps` | Show running services |
| `docker compose pull` | Pull latest images |

For development, **`up -d`** + occasional **`logs -f`** + **`down`** at end-of-session is the typical cycle.

---

## 8. Qdrant's API endpoints (preview)

Once running, the API exposes:

| Endpoint | Purpose |
|---|---|
| `GET /` | Health / version |
| `GET /collections` | List collections |
| `PUT /collections/{name}` | Create a collection |
| `DELETE /collections/{name}` | Delete a collection |
| `POST /collections/{name}/points` | Insert vectors |
| `POST /collections/{name}/points/search` | Similarity search |
| `GET /collections/{name}/points/{id}` | Get a specific point |

For this section, **LangChain's `QdrantVectorStore`** abstracts away the direct API calls. But knowing the endpoints exist is helpful for debugging.

---

## 9. Connecting from Python (preview)

Once running, Python code connects via:

```python
from langchain_qdrant import QdrantVectorStore
from langchain_openai import OpenAIEmbeddings

embedding_model = OpenAIEmbeddings(model="text-embedding-3-large")

vector_store = QdrantVectorStore.from_existing_collection(
    embedding=embedding_model,
    url="http://localhost:6333",
    collection_name="learning_rag",
)
```

The two pieces:
- **URL**: where Qdrant is reachable (`http://localhost:6333`).
- **Collection name**: a namespace inside Qdrant (multiple collections per Qdrant instance).

This pattern shows up in both [[10 - Creating Vector Embeddings and Storing in Qdrant]] and [[11 - Building the Retrieval (chat.py)]].

---

## 10. Common gotchas

> [!WARNING]
> **First-time setup issues**

| Symptom | Cause | Fix |
|---|---|---|
| `port 6333 already allocated` | Another service using it | Stop the other service or pick a different port: `- 6334:6333` |
| Container starts but `localhost:6333` returns nothing | Port mapping missing | Recheck `docker-compose.yml` |
| Dashboard 404 | URL typo | Use exactly `/dashboard` |
| Data disappears after restart | No volume mount | Add `volumes:` block |
| Out of memory crash | Many collections + large data | Increase Docker Desktop's RAM allocation |
| Slow first response | Container warm-up | Wait 5-10 seconds after start |
| Connection refused from Python | Wrong URL | Use `http://localhost:6333`, not `http://localhost` or `http://127.0.0.1:6333` (both should work but try the canonical form) |

---

## 11. State after this note

| Component | Status |
|---|---|
| Docker Desktop | ✅ Running |
| `docker-compose.yml` | ✅ Created |
| Qdrant container | ✅ Running on port 6333 |
| Qdrant web dashboard | ✅ Accessible at `localhost:6333/dashboard` |
| Collections | ❌ Empty (next notes will populate) |
| Indexing code | ❌ Not yet (next notes) |
| Retrieval code | ❌ Not yet |

The infrastructure is in place. The next notes populate it.

---

## 12. Main takeaways

- **Qdrant** = open-source, lightweight, fast vector DB.
- Setup: single `docker-compose.yml` declaring one service using the `qdrant/qdrant` image, port **6333**.
- Run with `docker compose up -d` (detached).
- Web UI at `http://localhost:6333/dashboard`.
- For persistence in real use, add a **volume mount**.
- All vector DBs are interchangeable at the architecture level — code changes are minimal when swapping.
- Knowledge transfers across **Pinecone, Weaviate, Chroma, pgvector, Milvus**.
- Confirm working with `docker ps` and a browser visit to the dashboard.

---

## 13. Things I still want to figure out

- How does Qdrant handle **horizontal scaling** if I ever need it?
- What's the **memory footprint** per 1M vectors?
- For **production**, what's the right combination of `qdrant/qdrant` flags (replication, snapshots, backup)?
- How does Qdrant compare to **Pinecone** in real benchmarks?
- What's the **upgrade path** to Qdrant Cloud if local outgrows?
- How does the Qdrant **filtering** language work for metadata queries?

---

## 14. Things to dig into

- **Qdrant docs**: https://qdrant.tech/documentation/
- **Qdrant benchmarks**: https://qdrant.tech/benchmarks/
- **LangChain Qdrant integration**: https://python.langchain.com/docs/integrations/vectorstores/qdrant/
- **Hands-on**: bring up Qdrant, hit `localhost:6333/dashboard`, explore the API console manually before the LangChain notes cover it.

---

## 15. Next up in this section

The vector DB is running. Time to start populating it. First, the glue library:

- [ ] [[07 - Introduction to LangChain]] — the AI utilities library used throughout the rest of the section.

---

## Related
- [[04 - The Indexing Phase]] — vector DBs in the conceptual architecture.
- [[02 - Docker Deep Dive]] — Docker fundamentals.
- [[03 - Running Ollama in Docker]] — same Docker pattern.
- [[02 - Long-Term Memory in LLMs]] — Qdrant also serves as the LTM backbone.

## Sources
- Qdrant docs — https://qdrant.tech/documentation/
- Qdrant benchmarks — https://qdrant.tech/benchmarks/
- LangChain Qdrant integration — https://python.langchain.com/docs/integrations/vectorstores/qdrant/
