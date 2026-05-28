---
title: The Chat Route - Enqueueing Jobs
date: 2026-05-28
source: "Section 9 / Lecture 7"
type: lecture-notes
status: in-progress
section: "Section 9: Scalable RAG with Async Queues & Distributed Workers"
tags:
  - fastapi
  - rq
  - chat-route
  - enqueue
  - post-route
  - async
  - hands-on
related:
  - "[[06 - Setting up FastAPI Server]]"
  - "[[05 - Creating the Worker (process_query)]]"
  - "[[08 - The Get Result Route - Fetching Job Status]]"
---

# The Chat Route — Enqueueing Jobs

> [!abstract] TL;DR
> Add a **`POST /chat`** route to `server.py` that accepts a `query` parameter, calls **`queue.enqueue(process_query, query)`**, and returns **immediately** with `{ "status": "queued", "job_id": "<uuid>" }`. The user sees an instant response — the server never blocks waiting for retrieval. Workers (started later) will pick up the job and run `process_query`. This is the **producer side** of the producer-consumer architecture. Two key insights: (1) the server is **completely free** between requests, and (2) the job ID is the **contract** between submission and result-fetching. Subtle bug to watch for: `load_dotenv()` must be the **first thing** in `server.py` (before any imports that need API keys at module-import time).

> [!info] Where this fits
> Seventh lecture of **Section 9: Scalable RAG with Async Queues & Distributed Workers**. The producer side is now complete. The next lecture ([[08 - The Get Result Route - Fetching Job Status]]) adds the consumer-facing polling route.

---

## 1. The route's job

`POST /chat` does **three** things:

1. Read the user's query from the request body.
2. Enqueue `process_query(query)` via RQ.
3. Return `{ status, job_id }` immediately.

Notably **does NOT**:
- Call the LLM.
- Wait for the result.
- Return the answer.

The answer comes via the **separate result route** ([[08 - The Get Result Route - Fetching Job Status]]).

---

## 2. Adding the imports

In `server.py`:

```python
from fastapi import FastAPI, Body

from client.rq_client import queue          # the RQ Queue handle
from queues.worker import process_query     # the function to enqueue
```

Two new imports:
- `Body` — FastAPI's way to declare request-body parameters.
- `queue` — the RQ queue from [[04 - Installing RQ and Building the Queue Client]].
- `process_query` — the worker function from [[05 - Creating the Worker (process_query)]].

> [!warning] Import order matters
> Both `queue` (which connects to Valkey) and `process_query` (whose module connects to OpenAI / Qdrant) need their dependencies at **import time**. If `OPENAI_API_KEY` isn't loaded yet, `worker.py`'s module-level `OpenAI()` call fails.
>
> Fix: `load_dotenv()` at the **top** of `server.py`:
>
> ```python
> from dotenv import load_dotenv
> load_dotenv()
>
> from fastapi import FastAPI, Body
> ...
> ```
>
> If you skip this, the import-time `OpenAI()` call inside `worker.py` blows up before any route ever runs. Catching it once is enough — `load_dotenv()` belongs above the imports for good.

---

## 3. The route

```python
@app.post("/chat")
def chat(query: str = Body(..., description="The chat message")):
    """Enqueue a chat query for async processing."""
    job = queue.enqueue(process_query, query)
    return {
        "status": "queued",
        "job_id": job.id,
    }
```

Breakdown:

| Piece | Purpose |
|---|---|
| `@app.post("/chat")` | Register as POST /chat |
| `query: str = Body(..., description="...")` | Read a `str` field called `query` from the request body |
| `queue.enqueue(process_query, query)` | Push the function call into Valkey |
| Returns | A `Job` object with `.id` (UUID) |
| Response | `{ status, job_id }` — instant |

The `Body(...)` syntax declares a request-body field. The `...` (Ellipsis) means **required**.

---

## 4. What `queue.enqueue` actually does

```python
job = queue.enqueue(process_query, query)
```

Behind the scenes:
1. RQ inspects `process_query` to get its import path (`queues.worker.process_query`).
2. RQ serializes the arguments (`(query,)`) using `pickle` (by default).
3. RQ wraps everything in a `Job` record with a unique UUID.
4. RQ writes the record into Valkey under the queue's key.
5. Returns the `Job` object — but **doesn't wait** for it to execute.

The function **has not run yet** when `enqueue` returns. It's just sitting in Valkey, waiting for a worker.

> [!important] What you get back is a ticket, not a result
> `process_query` may take 10, 20, 30 seconds. The return value of `enqueue` is **not the answer** — it's the **job ID**. You've effectively said "get in line." The actual result is fetched later via the result route.

---

## 5. The full updated `server.py`

```python
# server.py
from dotenv import load_dotenv
load_dotenv()                                # ← MUST be first

from fastapi import FastAPI, Body

from client.rq_client import queue
from queues.worker import process_query

app = FastAPI()


@app.get("/")
def root():
    return {"status": "Server is up and running"}


@app.post("/chat")
def chat(query: str = Body(..., description="The chat message")):
    """Enqueue a chat query for async processing."""
    job = queue.enqueue(process_query, query)
    return {
        "status": "queued",
        "job_id": job.id,
    }
```

About 20 lines total. The producer side is **complete**.

---

## 6. Testing via Swagger UI

Restart the server (Ctrl-C → `python main.py`).

Visit `http://localhost:8000/docs`. The Swagger UI now shows:

```
GET   /          root
POST  /chat      chat
```

Click **POST /chat → Try it out**. Enter:
```json
"Please explain arrow functions in JavaScript"
```

Click **Execute**. Response (instant — no waiting!):
```json
{
  "status": "queued",
  "job_id": "a1b2c3d4-e5f6-7890-..."
}
```

Three things to notice:
- **Response is immediate** — no LLM latency.
- **`job_id` is a UUID** the client must save.
- **No actual answer yet** — that's the next route's job.

What just happened: the job has been pushed into the queue and a job ID came back. The processor function hasn't actually run — without a worker process pulling from the queue, the job is sitting quietly in Valkey.

---

## 7. Where the job sits

After enqueueing, the job lives in Valkey:

```
Valkey
├── rq:queue:default              ← list of pending job IDs
│   └── ["a1b2c3d4-..."]
├── rq:job:a1b2c3d4-...           ← job details
│   ├── function: queues.worker.process_query
│   ├── args: ("Please explain arrow functions in JavaScript",)
│   ├── status: queued
│   └── created_at: 2026-05-28T22:00:00Z
```

(Approximate — RQ's internal schema is more complex, but conceptually this is what's stored.)

If you inspect Valkey via `redis-cli` after enqueueing, you can see these keys directly.

---

## 8. The server is now free

A key test: enqueue 10 jobs rapidly. The server returns 10 job IDs **near-instantly** — well under a second total. Because:

- Each `enqueue` is a single Redis write (~5ms).
- No LLM calls happen inline.
- No vector searches happen inline.
- The server is doing essentially nothing slow.

Throughput goes from ~1 req / 3.5 sec (Section 8's sync approach) → ~1000 req / sec (only limited by Valkey's write throughput).

The actual **work** happens in workers, on their own time.

---

## 9. What's missing without the result route

Right now, jobs go in but **nothing comes back to the user**. The chat route is half the contract; the result route completes it. That's next.

For now, jobs accumulate in Valkey, waiting for either:
- The result route to be added.
- A worker to be started (covered in [[09 - Running RQ Workers in Parallel]]).

Without workers, jobs just sit there. Without the result route, even after workers run, the user can't access the result.

---

## 10. Pydantic alternative (production-ready)

For real production, use a Pydantic model instead of raw `Body(...)`:

```python
from pydantic import BaseModel

class ChatRequest(BaseModel):
    query: str

@app.post("/chat")
def chat(req: ChatRequest):
    job = queue.enqueue(process_query, req.query)
    return {"status": "queued", "job_id": job.id}
```

Advantages:
- Strongly typed.
- Auto-validates.
- Schema visible in OpenAPI docs.
- Adds metadata fields naturally (e.g., user ID, session, options).

For learning, `Body(...)` is fine. For real APIs, Pydantic is the standard.

---

## 11. State after this lecture

| Component | Status |
|---|---|
| All infra (Valkey, Qdrant, RQ, worker, server) | ✅ |
| `POST /chat` route | ✅ Enqueues jobs |
| Jobs land in Valkey | ✅ |
| **Workers running** | ❌ Final note in section |
| **`GET /job_status` route** | ❌ Next note |
| End-to-end working | ❌ Still missing pieces |

---

## 12. Common gotchas

> [!warning] Chat route issues

| Symptom | Cause | Fix |
|---|---|---|
| `OPENAI_API_KEY missing` on server startup | `load_dotenv()` not first | Move it to top of `server.py` |
| `redis.exceptions.ConnectionError` | Valkey not running | `docker compose ps` |
| `ImportError: client.rq_client` | Project structure wrong | Check `__init__.py` files exist |
| `422 Unprocessable Entity` | Request body shape wrong | Send raw string, not JSON object — or switch to Pydantic |
| Job IDs returned but never processed | No workers running | See note 09 |
| `Body(...)` parses weirdly | Trying to send a JSON object | `Body` for raw string types; Pydantic for objects |

---

## 13. Main takeaways

- `POST /chat` enqueues `process_query` and returns immediately.
- `queue.enqueue(func, *args)` returns a `Job` — doesn't wait.
- The response is `{ status: "queued", job_id: "<uuid>" }`.
- Server stays **fast and free** — no LLM calls inline.
- The **job ID is the contract** between submission and result-fetching.
- `load_dotenv()` **must** be the first line in `server.py`.
- For production: use **Pydantic models** instead of raw `Body(...)`.
- Without workers, jobs just sit in Valkey forever.
- Throughput goes from ~1 req/sec (sync) to ~1000 req/sec (async).

---

## 14. Things I still want to figure out

- How to **prevent abuse** — rate-limit per IP?
- For **multi-tenant** apps, how to scope jobs to users?
- What's the right way to **track cost per job** for billing?
- How to **cancel a queued job** before it runs?
- For **idempotency** — if the same query is submitted twice, share the result?

---

## 15. Things to dig into

- **RQ enqueue docs**: https://python-rq.org/docs/
- **FastAPI Body docs**: https://fastapi.tiangolo.com/tutorial/body/
- **Pydantic models for request bodies**: https://fastapi.tiangolo.com/tutorial/body-multiple-params/
- **Hands-on**: submit 100 requests in a loop with `httpx`. Watch the response time — should stay near-zero. Check `redis-cli` to see Valkey filling up.

---

## 16. Next up in this section

Add the route that lets clients fetch job results:

- [ ] [[08 - The Get Result Route - Fetching Job Status]] — GET endpoint to poll for completion.

---

## Related
- [[05 - Creating the Worker (process_query)]] — the function this route enqueues.
- [[04 - Installing RQ and Building the Queue Client]] — the queue.
- [[06 - Setting up FastAPI Server]] — the server this route lives in.
- [[08 - The Get Result Route - Fetching Job Status]] — the matching consumer route.

## Sources
- [RQ documentation](https://python-rq.org/docs/)
- [FastAPI Body docs](https://fastapi.tiangolo.com/tutorial/body/)
- [FastAPI request bodies with Pydantic](https://fastapi.tiangolo.com/tutorial/body-multiple-params/)
