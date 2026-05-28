---
title: Installing RQ and Building the Queue Client
date: 2026-05-28
source: "Section 9 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 9: Scalable RAG with Async Queues & Distributed Workers"
tags:
  - rq
  - redis-queue
  - python
  - queue-client
  - infrastructure
  - hands-on
related:
  - "[[03 - Setting up Valkey (Redis Alternative)]]"
  - "[[05 - Creating the Worker (process_query)]]"
---

# Installing RQ and Building the Queue Client

> [!abstract] TL;DR
> Install **`rq`** — Redis Queue, a minimal Python job-queue library — with `pip install rq`. Lay out the project folder structure with `client/` (connection setup) and `queues/` (worker functions). Create `client/rq_client.py` that constructs the queue: `queue = Queue(connection=Redis(host="localhost", port=6379))`. This `queue` object exposes `.enqueue(...)` to submit jobs (used by the FastAPI server) and `.fetch_job(...)` to look up results. The Valkey container from [[03 - Setting up Valkey (Redis Alternative)]] is the backing store — no extra configuration needed because Valkey speaks Redis protocol. End state: a queue handle is ready, but nothing's been enqueued yet.

> [!info] Where this fits
> Fourth lecture of **Section 9: Scalable RAG with Async Queues & Distributed Workers**. Hands-on coding starts here. Next ([[05 - Creating the Worker (process_query)]]) defines the worker function that consumes from this queue.

---

## 1. What RQ is

**RQ (Redis Queue)** is a Python library — **"simple job queues for Python."** Documentation: https://python-rq.org/.

Properties:
- **Lightweight** — minimal API, easy to learn.
- **Uses Redis (or Valkey)** as the backing broker.
- **Python-native** — jobs are just Python functions called with arguments.
- **No daemon** — workers are regular Python processes.
- **Embedded job state** — Redis stores queues, results, failed jobs.

Compared to alternatives:
- **Celery** is RQ's bigger cousin — more features, more complexity.
- **Dramatiq** is RQ's spiritual cousin with broker-agnostic design.
- **Kafka** / **RabbitMQ** are orders of magnitude bigger systems.

For learning + small-to-medium production: **RQ is the right pick**. The whole pipeline here runs in <100 lines because of RQ's minimalism.

---

## 2. Installation

```bash
pip install rq
pip freeze > requirements.txt
```

`rq` pulls in `redis-py` as a transitive dependency — the Python client that talks Redis protocol to Valkey.

---

## 3. Project folder structure

A clean separation:

```
rag_queue/
├── docker-compose.yml          # Qdrant + Valkey services
├── requirements.txt
├── .env                         # OPENAI_API_KEY
├── client/
│   ├── __init__.py
│   └── rq_client.py            # ← this lecture
└── queues/
    ├── __init__.py
    └── worker.py               # ← next lecture
```

| Folder | Purpose |
|---|---|
| `client/` | Connection setup — knows about Redis/Valkey hosts |
| `queues/` | Worker functions — the actual work that runs |

This split keeps connection logic separate from business logic.

---

## 4. Writing `rq_client.py`

```python
# client/rq_client.py
from redis import Redis
from rq import Queue

queue = Queue(
    connection=Redis(
        host="localhost",
        port=6379,
    ),
)
```

That's all. Three lines of imports + a `Queue` instantiation.

### What happens
- `Redis(host=..., port=...)` opens a TCP connection to Valkey.
- `Queue(connection=...)` wraps that connection with RQ's queue API.
- The default queue name is `"default"` — sufficient for this section.

---

## 5. The queue object — what it can do

`queue` exposes a few methods that matter for this section:

| Method | Purpose | Used in |
|---|---|---|
| `queue.enqueue(func, *args, **kwargs)` | Submit a job | [[07 - The Chat Route - Enqueueing Jobs]] |
| `queue.enqueue_call(...)` | Lower-level enqueue | (not used) |
| `queue.fetch_job(job_id)` | Look up a job | [[08 - The Get Result Route - Fetching Job Status]] |
| `queue.count` | Pending jobs | (debugging) |
| `queue.empty()` | Clear all jobs | (debugging) |
| `queue.is_empty()` | Bool — anything queued? | (rare) |

`enqueue` is the key one. The signature:

```python
job = queue.enqueue(some_function, arg1, arg2, kwarg=value)
```

Returns a `Job` object with:

| Attribute | Meaning |
|---|---|
| `job.id` | UUID of this job |
| `job.return_value` | Function's return value once done; `None` otherwise |
| `job.is_queued`, `job.is_started`, `job.is_finished`, `job.is_failed` | State flags |
| `job.result` | Alias for `return_value` |
| `job.created_at`, `job.started_at`, `job.ended_at` | Timestamps |
| `job.exc_info` | Traceback if failed |

The two-route API ([[07 - The Chat Route - Enqueueing Jobs]] + [[08 - The Get Result Route - Fetching Job Status]]) revolves around these.

---

## 6. The `client/__init__.py` file

Needed for Python to treat `client/` as a module:

```python
# client/__init__.py
# (can be empty)
```

Same for `queues/__init__.py`. Both stay empty.

---

## 7. Mental model — what's where

After this lecture:

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│   Python process (FastAPI / worker)                          │
│                                                              │
│   ┌──────────────────────────┐                               │
│   │  client/rq_client.py     │                               │
│   │                          │                               │
│   │  queue = Queue(          │                               │
│   │    connection=Redis(...) │                               │
│   │  )                       │                               │
│   └──────────┬───────────────┘                               │
│              │                                               │
│              │ TCP                                           │
└──────────────┼───────────────────────────────────────────────┘
               │
               │ port 6379
               │
        ┌──────▼──────────┐
        │  Valkey         │  (Docker container)
        │  - "default"    │
        │    queue        │  ← stores job records
        └─────────────────┘
```

The `queue` object is the Python handle; Valkey is where the actual queue state lives.

---

## 8. Optional — environment variables

A production-ready version would read connection details from environment variables:

```python
# client/rq_client.py
import os
from redis import Redis
from rq import Queue

queue = Queue(
    connection=Redis(
        host=os.environ.get("REDIS_HOST", "localhost"),
        port=int(os.environ.get("REDIS_PORT", 6379)),
        password=os.environ.get("REDIS_PASSWORD"),
        db=int(os.environ.get("REDIS_DB", 0)),
    ),
)
```

For learning, hardcoded `localhost:6379` is fine. For production deployments, environment-driven config is essential.

---

## 9. Multiple queues — when to use

The default is one queue named `"default"`. For prioritization or routing, multiple queues are common:

```python
high = Queue("high", connection=Redis(...))
default = Queue("default", connection=Redis(...))
low = Queue("low", connection=Redis(...))
```

Workers can be configured to drain higher-priority queues first:

```bash
rq worker high default low
```

For Section 9's scope, one queue is enough. Worth knowing the pattern for production.

---

## 10. RQ Dashboard (optional but useful)

A web UI for monitoring queues / jobs:

```bash
pip install rq-dashboard
rq-dashboard
```

Opens at `localhost:9181`. Shows:
- Queue lengths.
- Job states (queued, started, finished, failed).
- Job results and errors.
- Worker activity.

Not wired in for this section, but extremely useful for debugging production setups.

---

## 11. State after this lecture

| Component | Status |
|---|---|
| Valkey container | ✅ Running |
| RQ installed | ✅ |
| Project folder structure | ✅ `client/`, `queues/` |
| `client/rq_client.py` | ✅ Defines `queue` object |
| `client/__init__.py` | ✅ (empty) |
| `queues/__init__.py` | ✅ (empty) |
| Worker function | ❌ Next lecture |
| FastAPI server | ❌ |

---

## 12. Common gotchas

> [!warning] First-time RQ + Valkey issues

| Symptom | Cause | Fix |
|---|---|---|
| `Connection refused` | Valkey container not running | `docker compose ps`; bring up if needed |
| Wrong host | Container vs host networking | Use `localhost` from host; `host.docker.internal` from another container |
| `redis.exceptions.AuthenticationError` | Valkey has password set | Pass `password=...` to `Redis()` |
| Imports fail | Wrong package | `pip install rq` (not `redis-queue`) |
| Multiple queue names confusion | Default vs named | Explicit name if not "default": `Queue("my_queue", ...)` |

---

## 13. Main takeaways

- **RQ (Redis Queue)** = minimal Python job-queue library.
- Install: `pip install rq`.
- Project structure: `client/` for connection, `queues/` for workers.
- `client/rq_client.py`: `queue = Queue(connection=Redis(host, port))`.
- Default queue name is `"default"`.
- `queue.enqueue(func, *args)` returns a `Job` with `.id`, `.return_value`, state flags.
- For production: env-driven config, multiple priority queues, RQ Dashboard.
- Valkey unchanged — it's Redis-protocol-compatible, RQ doesn't know the difference.
- Queue state lives in Valkey (out-of-process) — survives crashes, supports distributed workers.

---

## 14. Things I still want to figure out

- For **scheduled jobs** (run at 6 PM), how does RQ handle that?
- What's the right way to handle **job failures** in RQ?
- How does **RQ Scheduler** differ from plain RQ?
- For **priority queues**, what's the convention?
- How big a queue can RQ handle before hitting Redis limits?

---

## 15. Things to dig into

- **RQ docs**: https://python-rq.org/
- **RQ Dashboard**: https://github.com/Parallels/rq-dashboard
- **RQ Scheduler**: https://github.com/rq/rq-scheduler
- **Hands-on**: open a Python REPL, instantiate the queue, do `queue.enqueue(print, "hello")` → notice no print happens (no worker yet) → the job is queued in Valkey.

---

## 16. Next up in this section

Define the function workers will run:

- [ ] [[05 - Creating the Worker (process_query)]] — the RAG retrieval refactored into a function.

---

## Related
- [[03 - Setting up Valkey (Redis Alternative)]] — what RQ connects to.
- [[02 - Queues in System Design]] — conceptual foundation.
- [[05 - Creating the Worker (process_query)]] — what gets enqueued.

## Sources
- [RQ documentation](https://python-rq.org/)
- [RQ Dashboard](https://github.com/Parallels/rq-dashboard)
- [RQ Scheduler](https://github.com/rq/rq-scheduler)
- [redis-py documentation](https://redis-py.readthedocs.io/)
