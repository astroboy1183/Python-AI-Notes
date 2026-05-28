---
title: Setting up Valkey (Redis Alternative)
date: 2026-05-28
source: "Section 9 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 9: Scalable RAG with Async Queues & Distributed Workers"
tags:
  - valkey
  - redis
  - docker
  - docker-compose
  - infrastructure
  - hands-on
related:
  - "[[02 - Queues in System Design]]"
  - "[[06 - Setting up Qdrant with Docker]]"
  - "[[02 - Docker Deep Dive]]"
---

# Setting up Valkey (Redis Alternative)

> [!abstract] TL;DR
> Spin up a **Valkey** server via Docker Compose to act as the broker for **RQ (Redis Queue)**. Why Valkey instead of Redis: **Redis changed its open-source license** in 2024 — Valkey is the **drop-in BSD-licensed fork** maintained by the Linux Foundation and major cloud providers. Same wire protocol, same Python clients, zero code change. Add a second service block to the project's `docker-compose.yml` with the `valkey/valkey` image exposing port **6379**. After `docker compose up -d`, two services run in parallel: **Qdrant** (port 6333, vector DB) and **Valkey** (port 6379, queue broker). The infrastructure side of Section 9 is now in place.

> [!info] Where this fits
> Third lecture of **Section 9: Scalable RAG with Async Queues & Distributed Workers**. Infrastructure setup. The next lecture ([[04 - Installing RQ and Building the Queue Client]]) installs the Python client and connects to this Valkey instance.

---

## 1. Why a separate process

Quick recap from [[02 - Queues in System Design]]: the queue must live **out-of-process** so:
- Server crashes don't lose jobs.
- Multiple FastAPI processes can share the same queue.
- Workers can run on different machines.

That means: **a separate server** dedicated to holding the queue. Redis and Valkey are both purpose-built for this.

---

## 2. The Redis license drama (why Valkey exists)

In March 2024, **Redis Labs** changed Redis's license from BSD (true open source) to a more restrictive dual-license (RSAL / SSPL) that limits how cloud providers can resell it.

In response:
- The **Linux Foundation** forked Redis at its last BSD-licensed version.
- Named the fork **Valkey**.
- Backed by AWS, Google, Oracle, Alibaba, etc.
- Same wire protocol, same commands, same client libraries.

For users: **Valkey is a drop-in Redis replacement**. Any Python client connecting to "Redis" works against Valkey with zero changes — the wire protocol (RESP) is identical. If I prefer Redis, the same code works against Redis too — no change required.

---

## 3. Redis vs Valkey — when to use which

| Consideration | Redis | Valkey |
|---|---|---|
| **License** | RSAL / SSPL (restrictive) | BSD (true open source) |
| **Wire protocol** | RESP | RESP (identical) |
| **Command set** | Reference | Identical |
| **Python clients** | `redis-py` works | `redis-py` works |
| **Production maturity** | Years of battle-testing | Newer fork, but inherits Redis's codebase |
| **Cloud-provider support** | Some restrictions | Backed by all major clouds |
| **Use Redis if** | You're already on Redis Cloud / Enterprise | — |
| **Use Valkey if** | You want pure open source going forward | ✅ |

For learning, **either works**. Valkey is the open-source-friendly modern choice, so I'm going with that.

---

## 4. The current Docker Compose state

After [[06 - Setting up Qdrant with Docker]], `docker-compose.yml` looks like:

```yaml
services:
  vector-db:
    image: qdrant/qdrant
    ports:
      - 6333:6333
```

One service running on port 6333.

---

## 5. Adding Valkey to the compose file

Append a second service:

```yaml
services:
  vector-db:
    image: qdrant/qdrant
    ports:
      - 6333:6333

  valkey:
    image: valkey/valkey
    ports:
      - 6379:6379
```

Two services declared:

| Service | Image | Host port → Container port |
|---|---|---|
| `vector-db` | `qdrant/qdrant` | 6333 → 6333 |
| `valkey` | `valkey/valkey` | 6379 → 6379 |

Port **6379** is Redis's canonical port — Valkey inherits it.

> [!tip] Production hardening
> For real use, add a volume mount so data persists:
> ```yaml
>   valkey:
>     image: valkey/valkey
>     ports:
>       - 6379:6379
>     volumes:
>       - valkey_data:/data
> volumes:
>   valkey_data:
> ```
> Otherwise, **stopping the container loses all queued jobs**. For learning, ephemeral is fine.

---

## 6. Bringing it all up

```bash
cd rag_queue           # the project folder
docker compose up -d
```

What happens:
- Docker pulls `valkey/valkey` (~30 MB, fast).
- Qdrant container starts (already pulled).
- Valkey container starts.
- Both services run in background.

Verify:

```bash
docker compose ps
```

Should show both services running.

```bash
docker ps
```

Same view from the broader Docker perspective.

After this, two services are up and running: the vector DB on 6333, and Valkey on 6379.

---

## 7. Quick smoke test

### CLI test
The `redis-cli` works against Valkey:

```bash
docker exec -it <valkey_container_id> redis-cli
```

Or from outside the container if `redis-cli` is installed locally:

```bash
redis-cli -h localhost -p 6379
```

Inside:
```
127.0.0.1:6379> PING
PONG
127.0.0.1:6379> SET hello world
OK
127.0.0.1:6379> GET hello
"world"
```

If `PONG` returns, Valkey is working.

### Python test
```python
from redis import Redis
r = Redis(host="localhost", port=6379)
print(r.ping())          # True
r.set("hello", "world")
print(r.get("hello"))    # b'world'
```

Both confirm: connection works, Valkey speaks Redis protocol.

---

## 8. Two-service architecture so far

After this lecture:

```
┌──────────────────────────────────────────────────────────┐
│                 Docker (host machine)                     │
│                                                          │
│   ┌─────────────────┐         ┌──────────────────┐       │
│   │  qdrant         │         │  valkey          │       │
│   │  (vector DB)    │         │  (queue broker)  │       │
│   │  port 6333      │         │  port 6379       │       │
│   └─────────────────┘         └──────────────────┘       │
│           ▲                            ▲                 │
└───────────┼────────────────────────────┼─────────────────┘
            │                            │
            │                            │
   ┌────────┴────────┐         ┌─────────┴────────┐
   │  Python:         │         │  Python:          │
   │  Vector search   │         │  RQ queue / RQ    │
   │  (existing RAG)  │         │  worker (new)     │
   └─────────────────┘         └──────────────────┘
```

Two databases (one for vectors, one for queues). Python code talks to both.

---

## 9. State after this lecture

| Component | Status |
|---|---|
| Docker | ✅ Running |
| `docker-compose.yml` | ✅ Updated |
| Qdrant container | ✅ Running, port 6333 |
| **Valkey container** | ✅ **Running, port 6379** |
| RQ Python client | ❌ Next lecture |
| Worker function | ❌ |
| FastAPI server | ❌ |

---

## 10. Common gotchas

> [!warning] Issues to watch

| Symptom | Cause | Fix |
|---|---|---|
| `port 6379 already allocated` | Local Redis already running | Stop local Redis or pick different port |
| Valkey container immediately exits | Wrong image name | Use `valkey/valkey`, not `valkey` |
| Can't connect from Python | Wrong host (Linux Docker vs Mac/Windows) | Use `localhost`; or `host.docker.internal` if connecting from another container |
| Data disappears after `docker compose down` | No volume mount | For prod, add `volumes:` |
| Cross-platform Docker issues | Compose v1 vs v2 syntax | Use `docker compose` (with space), modern syntax |

---

## 11. Main takeaways

- **Valkey** = BSD-licensed fork of Redis (post-2024 license change).
- **Drop-in replacement** — same wire protocol, same Python clients.
- Add to `docker-compose.yml`: `image: valkey/valkey`, port **6379**.
- Bring up alongside Qdrant: `docker compose up -d`.
- Verify with `redis-cli PING` → `PONG`.
- Two services now running: Qdrant (vectors) + Valkey (queue broker).
- For production: add volume mount for persistence.
- All standard Redis commands work — RQ Python client connects unchanged.

---

## 12. Things I still want to figure out

- For **production**, what's the right way to configure Valkey (memory limit, eviction policy)?
- How does **Valkey replication** work for HA setups?
- What's the **performance difference** (if any) between Valkey and Redis?
- How does **Valkey Cluster** compare to Redis Cluster?
- For **persistence**, AOF or RDB or both?
- What other Redis-compatible projects exist (KeyDB, Dragonfly)?

---

## 13. Things to dig into

- **Valkey project**: https://valkey.io/
- **Redis license change context**: search "Redis license change 2024".
- **`redis-py` docs**: https://redis-py.readthedocs.io/
- **Hands-on**: open `redis-cli`, play with `LPUSH` + `RPOP` to see FIFO behavior raw.

---

## 14. Next up in this section

- [ ] [[04 - Installing RQ and Building the Queue Client]] — Python client + connection setup.

---

## Related
- [[02 - Queues in System Design]] — why this exists.
- [[06 - Setting up Qdrant with Docker]] — same Docker pattern.
- [[02 - Docker Deep Dive]] — Docker fundamentals.

## Sources
- [Valkey project](https://valkey.io/)
- [redis-py documentation](https://redis-py.readthedocs.io/)
- [Docker Compose docs](https://docs.docker.com/compose/)
