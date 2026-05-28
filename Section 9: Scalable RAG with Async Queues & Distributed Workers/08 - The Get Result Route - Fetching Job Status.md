---
title: The Get Result Route - Fetching Job Status
date: 2026-05-28
source: "Section 9 / Lecture 8"
type: lecture-notes
status: in-progress
section: "Section 9: Scalable RAG with Async Queues & Distributed Workers"
tags:
  - fastapi
  - rq
  - job-status
  - polling
  - get-route
  - async
  - hands-on
related:
  - "[[07 - The Chat Route - Enqueueing Jobs]]"
  - "[[05 - Creating the Worker (process_query)]]"
  - "[[09 - Running RQ Workers in Parallel]]"
---

# The Get Result Route — Fetching Job Status

> [!abstract] TL;DR
> Add **`GET /job_status?job_id=<uuid>`** that the client polls to check progress and eventually retrieve the LLM's answer. Body: `job = queue.fetch_job(job_id); return {"result": job.return_value}`. While the job is still queued or running, **`return_value` is `None`** — the client keeps polling. Once a worker completes the job, the return value becomes available. This **completes the two-route async API contract**: `POST /chat` submits → `GET /job_status` polls. Submitting multiple jobs (debugging in JS, arrow functions in JS) and polling them all returns `null` because no workers are running yet — the final piece is started in [[09 - Running RQ Workers in Parallel]].

> [!info] Where this fits
> Eighth note of **Section 9: Scalable RAG with Async Queues & Distributed Workers**. Completes the API surface. The final note ([[09 - Running RQ Workers in Parallel]]) actually starts workers, demonstrating the end-to-end flow.

---

## 1. The route's job

`GET /job_status` does **three** things:

1. Read `job_id` from query string.
2. Fetch the job from Valkey via RQ.
3. Return `{ "result": job.return_value }`.

`return_value` is:
- `None` while the job is queued / running / failed.
- The function's actual return string once finished.

The client polls repeatedly until `result != None`.

---

## 2. The route

```python
@app.get("/job_status")
def job_status(job_id: str = Query(..., description="The job ID")):
    """Fetch the current status / result of a queued job."""
    job = queue.fetch_job(job_id)
    return {
        "result": job.return_value if job else None,
    }
```

Updated imports:

```python
from fastapi import FastAPI, Body, Query
```

`Query(...)` declares a query-string parameter (vs `Body(...)` for request body).

---

## 3. RQ's `fetch_job` semantics

```python
job = queue.fetch_job(job_id)
```

| Job state | What `job` looks like | What `job.return_value` returns |
|---|---|---|
| Queued (waiting) | `Job` object | `None` |
| Started (running on a worker) | `Job` object | `None` |
| Finished (success) | `Job` object | The function's return value |
| Failed | `Job` object | `None` (use `job.exc_info` for traceback) |
| Doesn't exist | `None` | — |

For the polling client, only "finished" matters. Other states all look like `null` in the response.

> [!tip] Production refinement
> A more informative response includes the **state** explicitly:
> ```python
> return {
>     "status": job.get_status(),     # 'queued', 'started', 'finished', 'failed'
>     "result": job.return_value,
> }
> ```
> Lets the client distinguish "still running" from "failed silently."

---

## 4. Full updated `server.py`

```python
# server.py
from dotenv import load_dotenv
load_dotenv()

from fastapi import FastAPI, Body, Query

from client.rq_client import queue
from queues.worker import process_query

app = FastAPI()


@app.get("/")
def root():
    return {"status": "Server is up and running"}


@app.post("/chat")
def chat(query: str = Body(..., description="The chat message")):
    job = queue.enqueue(process_query, query)
    return {
        "status": "queued",
        "job_id": job.id,
    }


@app.get("/job_status")
def job_status(job_id: str = Query(..., description="The job ID")):
    job = queue.fetch_job(job_id)
    return {
        "result": job.return_value if job else None,
    }
```

About 25 lines. **The full API surface is now complete.**

---

## 5. Testing via Swagger

Restart server (Ctrl-C → `python main.py`). Visit `http://localhost:8000/docs`.

Now three routes are visible:

| Route | Purpose |
|---|---|
| `GET /` | Health |
| `POST /chat` | Enqueue |
| `GET /job_status` | Poll result |

### Step 1 — Submit a query
**POST /chat → Try it out** → enter `"Please explain arrow functions in JavaScript"` → Execute.

Response:
```json
{
  "status": "queued",
  "job_id": "a1b2c3d4-..."
}
```

### Step 2 — Poll
**GET /job_status → Try it out** → paste the job ID → Execute.

Response:
```json
{
  "result": null
}
```

Click Execute repeatedly. Always `null`. The processor function isn't running in the background — there's no worker draining the queue yet.

The job sits in Valkey forever (no TTL by default). Workers running in [[09 - Running RQ Workers in Parallel]] are what actually consume jobs and produce results.

---

## 6. Submitting multiple jobs

Submit **two more queries** to watch the queue build up:

```
POST /chat  "Explain debugging in JS"   → job_id: b2c3d4e5-...
POST /chat  "Explain arrow functions"   → job_id: c3d4e5f6-...
POST /chat  "How to use promises?"      → job_id: d4e5f6g7-...
```

All return instantly. Polling each → `null` for all.

Three jobs queued. Server is serving requests fine. **Nothing is processing them** until workers start.

This vividly demonstrates the **decoupling**: producer happily produces; consumer absence doesn't break anything.

---

## 7. The polling pattern from the client side

A real client polls like:

```python
import time
import httpx

# Submit
resp = httpx.post(
    "http://localhost:8000/chat",
    json="What's the weather like in Bangalore?",     # raw string body
)
job_id = resp.json()["job_id"]

# Poll
while True:
    poll = httpx.get(
        "http://localhost:8000/job_status",
        params={"job_id": job_id},
    )
    result = poll.json()["result"]
    if result is not None:
        print(result)
        break
    time.sleep(1)            # don't hammer the server
```

Polling interval is a trade-off:
- **Too frequent** (100ms) → wastes bandwidth.
- **Too slow** (10s) → user perceives delay.
- **1-2 seconds** → reasonable for chat-style UX.

> [!tip] Better than polling — WebSockets / SSE
> For production, push-based options beat polling:
> - **WebSockets** — bidirectional, persistent connection.
> - **Server-Sent Events (SSE)** — server pushes to client.
> - **Webhooks** — server POSTs to client URL on completion.
>
> Polling is the simplest pattern. This section stays simple.

---

## 8. What's still missing

At this point, the **API is complete** but workers are still not running. So:

- POST /chat → ✅ queues jobs.
- GET /job_status → ✅ returns null forever.

The next (and last) note in this section fixes this by **starting `rq worker`** in a separate terminal.

---

## 9. Common gotchas

> [!warning] Job status route issues

| Symptom | Cause | Fix |
|---|---|---|
| `job_status` returns null forever | No workers running | Run `rq worker` (next note) |
| `result` field is `None` even after worker ran | Worker crashed; check `job.exc_info` | Add explicit `status` field |
| `fetch_job` returns `None` | Job ID typo or expired | Verify ID; check job TTL |
| `KeyError` accessing `job.return_value` on a None job | Job doesn't exist | Use `if job else None` guard |
| Polling too fast | Hammering server | Add `time.sleep(1)` client-side |
| Old jobs accumulate in Valkey | No expiry policy | RQ has `result_ttl=...` to control |

---

## 10. State after this lecture

| Component | Status |
|---|---|
| All infra | ✅ |
| `POST /chat` route | ✅ |
| **`GET /job_status` route** | ✅ |
| Jobs queue up in Valkey | ✅ |
| End-to-end works (jobs get processed) | ❌ **Workers needed (final note in section)** |

The **API is feature-complete**. The only thing left is to actually run a worker.

---

## 11. The two-route async contract

The pattern is general — applies to any async API:

```
Producer (client/server)          Consumer (workers)
─────────────────────────         ──────────────────

POST /work
   │
   ▼
{ "job_id": "..." }   ◄────────── Worker picks up
                                  Runs process_query
                                  Writes result to Valkey
                                  
                                  
                                  
GET /work_status?job_id=...
   │
   ▼
{ "result": "..." }
```

Two routes. One contract. Infinitely scalable on the consumer side.

---

## 12. Main takeaways

- `GET /job_status?job_id=<uuid>` returns `{ result: job.return_value }`.
- `result` is `None` while the job is queued/running; the actual string once finished.
- `queue.fetch_job(job_id)` returns the `Job` object or `None`.
- Production refinement: include explicit `status` field too.
- Without workers, the result is `null` forever — but the architecture is correct.
- The **two-route contract** (submit + poll) is a universal async pattern.
- Client-side: poll every 1-2 seconds, not faster.
- For production UX: WebSockets / SSE / webhooks beat polling.

---

## 13. Things I still want to figure out

- What's the best **polling backoff** strategy?
- For **multiple concurrent jobs** by the same client, manage IDs how?
- How to handle **job expiration** (TTL on results)?
- For **failed jobs**, what's the right way to surface the error?
- How to **show progress** (e.g., "running similarity search...") to the client mid-job?
- WebSockets pattern in FastAPI for push-based updates?

---

## 14. Things to dig into

- **RQ job docs**: https://python-rq.org/docs/jobs/
- **FastAPI WebSockets**: https://fastapi.tiangolo.com/advanced/websockets/
- **Server-Sent Events in FastAPI**: `sse-starlette` library.
- **Hands-on**: write a small client script that submits + polls. Run it before starting workers — observe forever-null. Then start a worker → watch result appear.

---

## 15. Next up in this section

The API is complete. Time to start workers to actually do the work:

- [ ] [[09 - Running RQ Workers in Parallel]] — `rq worker` command + parallel workers demo.

---

## Related
- [[07 - The Chat Route - Enqueueing Jobs]] — the submission counterpart.
- [[05 - Creating the Worker (process_query)]] — what produces the `return_value`.
- [[09 - Running RQ Workers in Parallel]] — what makes results appear.

## Sources
- [RQ job docs](https://python-rq.org/docs/jobs/)
- [FastAPI WebSockets](https://fastapi.tiangolo.com/advanced/websockets/)
- [sse-starlette](https://github.com/sysid/sse-starlette) for Server-Sent Events in FastAPI
