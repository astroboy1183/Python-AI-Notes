---
title: Section Intro - Why Async
date: 2026-05-28
source: "Section 9 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 9: Scalable RAG with Async Queues & Distributed Workers"
tags:
  - rag
  - async
  - asynchronous-programming
  - production
  - scalability
  - section-overview
  - foundations
related:
  - "[[11 - Building the Retrieval (chat.py)]]"
  - "[[01 - Section Intro - RAG]]"
  - "[[05 - FastAPI Setup]]"
---

# Section Intro — Why Async

> [!abstract] TL;DR
> Section 8's RAG works — but only as a **synchronous script**. In a real product, that pattern breaks: every user request **blocks the server** while indexing or retrieval runs (10s of seconds), so one busy user makes everyone else wait. This section converts the synchronous pipeline into an **async, queue-driven architecture**: requests get pushed into a **Redis-backed queue (RQ + Valkey)**, returned immediately with a job ID, and processed by **background workers**. Server stays responsive. Workers scale horizontally — three workers = three concurrent jobs. The end result: production-shaped RAG infrastructure. The principle generalizes: **any slow operation behind a web server should be queued, not inline.**

> [!info] Where this fits
> First lecture of **Section 9: Scalable RAG with Async Queues & Distributed Workers**. The same RAG pipeline from [[Section 8]], re-architected for production. After Section 9, the chat-with-PDF system can handle real concurrent traffic.

---

## 1. The problem with Section 8's code

Section 8's pipeline works for one user, one query at a time. Two visible symptoms when scaling up:

### Indexing is slow and blocking

`python index.py` runs for 30+ seconds even on the small Node.js PDF. Scale to 1,000 PDFs → minutes. While it's running, nothing else happens — the script blocks the system because it's doing everything synchronously.

### Retrieval is slow under load

The chat call takes 1-5 seconds (embedding + similarity search + LLM call). If the FastAPI server processes that **inline**, every other user's request is blocked until the current one finishes. One slow query = everyone waits. Because of one user, every other user is sitting on a spinner.

---

## 2. The "rule of programming" tension

There's a well-known engineering principle: *if it works, don't touch it.* This section deliberately **violates that rule** for a good reason: Section 8's code works for *learning*, not for *production*. Production code:
- Handles concurrent requests.
- Doesn't block on slow operations.
- Scales horizontally.
- Recovers from failures.
- Provides progress feedback.

Section 8 has none of these. Section 9 adds them all.

---

## 3. Sync vs async — the conceptual shift

| | Synchronous (Section 8) | Asynchronous (Section 9) |
|---|---|---|
| **Caller behavior** | Wait for result | Get a job ID immediately, poll for result |
| **Server load** | Blocked while processing | Free between requests |
| **Concurrency** | One request at a time | Many concurrent jobs |
| **Failures** | Caller sees the error | Job marked failed; can retry |
| **Scaling** | One process can do one thing | Spawn more workers = more throughput |
| **Real-world examples** | School script | Stripe, Slack, every SaaS app |

Async is **the default architecture** for any web service whose backend work takes longer than a few hundred milliseconds.

---

## 4. The high-level architecture preview

Here's the picture Section 9 builds:

```
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│   User browser                                               │
│        │                                                     │
│        │  POST /chat { "message": "..." }                    │
│        ▼                                                     │
│   ┌──────────────────────────┐                               │
│   │   FastAPI server         │  → returns { job_id: "..." }  │
│   │                          │   immediately (no waiting)    │
│   │   Pushes job into queue  │                               │
│   └──────────┬───────────────┘                               │
│              │                                               │
│              ▼                                               │
│   ┌──────────────────────────┐                               │
│   │   Valkey (Redis-compat)  │  ← the queue lives here       │
│   │   Holds queued jobs      │                               │
│   └──────────┬───────────────┘                               │
│              │                                               │
│              ▼                                               │
│   ┌──────────────────────────┐                               │
│   │   RQ worker(s)           │  ← can spawn 1, 3, 10, …      │
│   │   Pulls job from queue   │                               │
│   │   Runs process_query()   │                               │
│   │   Stores result back     │                               │
│   └──────────┬───────────────┘                               │
│              │                                               │
│              ▼                                               │
│   ┌──────────────────────────┐                               │
│   │   Valkey                 │  ← job result stored here too │
│   └──────────────────────────┘                               │
│                                                              │
│   User polls: GET /job_status?job_id=...                     │
│        │                                                     │
│        ▼                                                     │
│   FastAPI reads result from Valkey, returns to user          │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

Three new components compared to Section 8:
- **Valkey** — Redis-compatible queue + result store.
- **RQ (Redis Queue)** — Python library for managing jobs.
- **Worker processes** — separate from the FastAPI server.

---

## 5. The two-route API pattern

The async pattern restructures the API:

| Route | Purpose | Behavior |
|---|---|---|
| `POST /chat` | Submit a query | Enqueue + return job ID. **Doesn't wait.** |
| `GET /job_status?job_id=...` | Poll for result | Returns `null` if still processing, result if done |

This is the **submit-then-poll** pattern. Real apps add WebSockets / SSE / webhooks for push-based notifications, but polling is the simplest version and what this section uses.

---

## 6. Where async shows up in real products

The same pattern powers many familiar features:

| Product / feature | Pattern |
|---|---|
| Stripe payment processing | Submit charge → webhook on completion |
| Slack file upload | Upload → background thumbnail / virus scan |
| GitHub Actions | Trigger workflow → poll runs / webhook |
| OpenAI Assistants API | Create run → poll status |
| Email sending (Mailgun, SendGrid) | Submit → asynchronous delivery |
| Video transcoding | Upload → encode in background |
| Long-running search (Algolia, Elasticsearch) | Submit indexing → search later |
| LangSmith traces | Logs queued, processed async |

Section 9's RAG fits the same shape: **expensive operation triggered, server returns fast, work happens in background, result fetched later**.

---

## 7. What's NOT in this section

A few production concerns deliberately deferred:

| Topic | Where |
|---|---|
| Persistence / durability beyond Redis | Add Postgres / cloud storage |
| Job retry logic | RQ supports it; lecture doesn't enable |
| Job priority queues | RQ supports; not used |
| Distributed workers across machines | Same code works; just deploy on multiple hosts |
| Authentication / rate limiting | Standard FastAPI middleware |
| Monitoring / metrics | Prometheus, OpenTelemetry, etc. |
| WebSocket push notifications | Polling used instead |
| Containerizing the worker | Docker, K8s |
| Auto-scaling workers based on queue depth | Cloud-specific |

The section covers the **core async architecture**. Production-hardening is layered on after.

---

## 8. Tools introduced

| Tool | Role |
|---|---|
| **Valkey** | Redis-compatible message broker / result store |
| **RQ (Redis Queue)** | Python library for queuing function calls |
| **FastAPI** | Already used in [[05 - FastAPI Setup]] |
| **uvicorn** | The ASGI server FastAPI runs on |
| `python-dotenv` | Already used in [[02 - Using OpenAI API in Python]] |

Familiar Docker / docker-compose patterns from [[02 - Docker Deep Dive]] and [[06 - Setting up Qdrant with Docker]].

---

## 9. The section's progression

| # | Lecture | What it covers |
|---|---|---|
| 02 | [[02 - Queues in System Design]] | FIFO conceptual model, producer/consumer |
| 03 | [[03 - Setting up Valkey (Redis Alternative)]] | Add Valkey to Docker Compose |
| 04 | [[04 - Installing RQ and Building the Queue Client]] | `pip install rq` + connection setup |
| 05 | [[05 - Creating the Worker (process_query)]] | The processor function |
| 06 | [[06 - Setting up FastAPI Server]] | Web server scaffold |
| 07 | [[07 - The Chat Route - Enqueueing Jobs]] | POST endpoint, enqueue jobs |
| 08 | [[08 - The Get Result Route - Fetching Job Status]] | GET endpoint, fetch results |
| 09 | [[09 - Running RQ Workers in Parallel]] | Start workers, demo parallelism |

By Lecture 9, the system handles real concurrent traffic.

---

## 10. Main takeaways

- Section 8's sync code works for learning but **blocks under real load**.
- Async architecture: **submit job → get ID immediately → poll for result later**.
- Stack: **FastAPI** (web) + **RQ** (job queue) + **Valkey** (Redis-compatible store) + **workers** (background processes).
- The server **never does slow work inline** — it queues and returns.
- Workers scale **horizontally** — one worker = one concurrent job; three workers = three.
- This pattern powers most production SaaS backends (Stripe, Slack, OpenAI Assistants API).
- This section deliberately stops at "core async architecture" — retries, monitoring, K8s deferred to real deployment.

---

## 11. Things I want to come away with

- Understanding of when **sync is OK** vs when **async is required**.
- Mental model of the **producer / queue / consumer** triangle.
- Hands-on familiarity with **RQ** — Python's standard queue library.
- Knowing how to wire a **FastAPI route → enqueue → worker → result-fetch** flow.
- Recognition of this pattern in other products / contexts.

---

## 12. Next up in this section

- [ ] [[02 - Queues in System Design]] — the conceptual foundation.

---

## Related
- [[11 - Building the Retrieval (chat.py)]] — the sync code this section refactors.
- [[01 - Section Intro - RAG]] — Section 8 overview.
- [[05 - FastAPI Setup]] — Section 5 — FastAPI fundamentals.
- [[02 - Docker Deep Dive]] — Section 5 — Docker fundamentals.

## Sources
- [RQ documentation](https://python-rq.org/)
- [FastAPI documentation](https://fastapi.tiangolo.com/)
- [Valkey documentation](https://valkey.io/)
