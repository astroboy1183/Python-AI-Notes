---
title: Running RQ Workers in Parallel
date: 2026-05-28
source: "Section 9 / Lecture 9"
type: lecture-notes
status: in-progress
section: "Section 9: Scalable RAG with Async Queues & Distributed Workers"
tags:
  - rq
  - rq-worker
  - parallel-workers
  - scaling
  - macos-fork-fix
  - production
  - hands-on
related:
  - "[[08 - The Get Result Route - Fetching Job Status]]"
  - "[[05 - Creating the Worker (process_query)]]"
  - "[[02 - Queues in System Design]]"
---

# Running RQ Workers in Parallel

> [!abstract] TL;DR
> Final note in this section. Start RQ workers from the terminal — `rq worker` (run from project root, with venv activated). Each worker process **pulls jobs from Valkey one at a time** and runs them. Spawn **multiple workers in separate terminals** for parallelism: 3 worker processes = up to 3 concurrent jobs. Subtle macOS quirk: workers fail on macOS due to a fork+OpenAI client interaction — fix with `export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` before `rq worker`. With workers running, the chat-with-PDF system works **end-to-end async**: submit query → get job ID → workers process in background → poll → get answer. Section 9 closes with a demo of horizontal scaling: submit three queries at once and watch three workers process them in parallel.

> [!info] Where this fits
> Final note of **Section 9: Scalable RAG with Async Queues & Distributed Workers**. Closes the section. After this, the chat-with-PDF system is production-shaped. Next section pivots to **multi-modal agents**.

---

## 1. The missing piece

After [[08 - The Get Result Route - Fetching Job Status]]:

- ✅ API submits jobs.
- ✅ API polls jobs.
- ❌ Nothing **executes** jobs.

The fix: run **`rq worker`** in a separate terminal. That's a Python process that:
1. Connects to Valkey.
2. Listens on the queue.
3. Pulls jobs one at a time.
4. Imports the function (`process_query`).
5. Calls it with the stored arguments.
6. Writes the return value back to Valkey.
7. Loops.

---

## 2. Starting the first worker

In a **new terminal** (the FastAPI server should already be running in another):

```bash
# Activate venv if not already
source venv/bin/activate

# Navigate to project root
cd rag_queue

# Start an RQ worker
rq worker
```

Output:

```
22:47:01 Worker rq:worker:Mac.local.12345: started, version 1.16.0
22:47:01 Subscribing to channel rq:pubsub:Mac.local.12345
22:47:01 *** Listening on default...
```

The worker is now **subscribed to the default queue**. As jobs are enqueued, it picks them up.

---

## 3. The macOS fork bug — `OBJC_DISABLE_INITIALIZE_FORK_SAFETY`

On macOS, `rq worker` often fails when the worker tries to **fork** to handle a job, because the OpenAI client (or any library that uses Objective-C internals) crashes after fork. The bug shows up here as something like:

```
22:47:30 Moving job to FailedJobRegistry (...)
22:47:30 Worker died unexpectedly: ...
```

Fix: set an environment variable **before** starting the worker:

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
rq worker
```

This is a macOS-specific issue. On Linux, the workaround isn't needed.

> [!example] Why this happens
> macOS Objective-C runtime is unhappy when initialized in a forked process. The OpenAI Python client uses HTTPS via `httpx`, which depends on system TLS — and that touches Objective-C-initialized libraries. Fork without re-initializing → crash.
>
> The env var tells the runtime: "don't enforce fork safety checks." It's a workaround, not a fix. For production, **use `--workers-pool eventlet`** or run workers in **Docker on Linux**.

---

## 4. With the worker running

Submit a query via Swagger (`POST /chat`):

```json
"Please explain debugging in JavaScript"
```

Get the `job_id`. Then in the worker's terminal:

```
22:47:45 default: queues.worker.process_query("Please explain debugging in JavaScript") (a1b2c3d4-...)
22:47:45 🔍 Searching chunks for: Please explain debugging in JavaScript
22:47:48 🤖 Here's how to debug Node.js: ...
22:47:48 default: Job OK (a1b2c3d4-...)
22:47:48 Result is kept for 500 seconds
```

The job ran. Poll `GET /job_status`:

```json
{
  "result": "Here's how to debug Node.js: ..."
}
```

🎉 **The full async pipeline works**.

---

## 5. Running multiple workers in parallel

The big payoff: **horizontal scaling**.

Open **two more terminals**. In each:

```bash
source venv/bin/activate
cd rag_queue
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
rq worker
```

Now **three workers** are listening on the same queue. Each one pulls a different job:

| Terminal 1 | Terminal 2 | Terminal 3 |
|---|---|---|
| rq worker | rq worker | rq worker |

Three workers running = three queries can be processed in parallel.

Submit three queries in quick succession via Swagger. Each worker grabs one. They run **in parallel**, not sequentially.

Demo with three queries:
- "Explain arrow functions in JavaScript"
- "Explain debugging in JavaScript"
- "How do promises work?"

All three start processing immediately. Total time = single-query time, not 3×.

---

## 6. The visible parallelism

Watching three terminals at once:

```
Terminal 1: 🔍 Searching chunks for: arrow functions
Terminal 2: 🔍 Searching chunks for: debugging in JavaScript
Terminal 3: 🔍 Searching chunks for: how do promises work

Terminal 1: 🤖 Arrow functions are...
Terminal 2: 🤖 Node.js provides...
Terminal 3: 🤖 Promises represent...
```

Three queries → ~3-5 seconds total (vs ~10-15 seconds sequential). **Throughput scales linearly with worker count** up to OpenAI API rate limits.

---

## 7. Scaling beyond one machine

The setup works **distributed** too:

- Server runs on Machine A.
- Valkey runs on Machine B (or accessible across the network).
- Workers run on Machines C, D, E.

As long as all of them can reach the same Valkey, the architecture works. **Workers don't know about each other** — they just pull from the shared queue.

For production:
- Run Valkey in cloud (AWS ElastiCache, Memorystore, Upstash).
- Run workers in Docker containers.
- Auto-scale worker count based on queue depth.
- Run FastAPI behind a load balancer (multiple instances).

Same architecture, just deployed at scale.

---

## 8. Worker process lifecycle

What `rq worker` does:

```
┌───────────────────────────────────────┐
│  rq worker starts                      │
│  - connects to Valkey                  │
│  - subscribes to "default" queue       │
└──────────────┬────────────────────────┘
               │
               ▼
       ┌───────────────┐
       │   Wait for    │
       │   a job       │
       └──────┬────────┘
              │
        job appears
              │
              ▼
┌───────────────────────────────────────┐
│  Worker forks a child process          │
│  Child imports queues.worker           │
│  Child runs process_query(args)        │
│  Child stores return_value in Valkey   │
│  Child exits                           │
└──────────────┬────────────────────────┘
               │
               ▼
       ┌───────────────┐
       │  Back to wait │
       └───────────────┘
```

The **fork-per-job** model gives clean isolation: a crashing job doesn't take down the worker.

---

## 9. RQ worker CLI options

Some useful flags:

| Flag | Purpose |
|---|---|
| `--burst` | Process current jobs and exit (no listen loop) |
| `--max-jobs N` | Exit after N jobs (useful for memory leak mitigation) |
| `--worker-class WORKER_CLASS` | Use a different worker (e.g., `rq.SimpleWorker` for no-fork) |
| `--name NAME` | Custom worker name for logs |
| `--logging-level LEVEL` | `DEBUG`, `INFO`, etc. |
| `queue1 queue2 ...` | Listen to multiple queues |

For this section: bare `rq worker` is plenty.

---

## 10. The final state

After this:

| Component | Status |
|---|---|
| Valkey container | ✅ |
| Qdrant container | ✅ |
| RQ client | ✅ |
| Worker function | ✅ |
| FastAPI server | ✅ |
| Chat route | ✅ |
| Job-status route | ✅ |
| **Workers running** | ✅ **End-to-end async pipeline complete!** |

The chat-with-PDF system can now handle **real concurrent traffic**. Throughput scales horizontally with worker count.

---

## 11. End of Section 9

This closes out **Section 9: Scalable RAG with Async Queues & Distributed Workers**:

| # | Topic |
|---|---|
| 01 | Section Intro — Why Async |
| 02 | Queues in System Design |
| 03 | Setting up Valkey (Redis Alternative) |
| 04 | Installing RQ and Building the Queue Client |
| 05 | Creating the Worker (process_query) |
| 06 | Setting up FastAPI Server |
| 07 | The Chat Route — Enqueueing Jobs |
| 08 | The Get Result Route — Fetching Job Status |
| 09 | Running RQ Workers in Parallel (this note) |

**Production-shaped chat-with-PDF system delivered.**

What was built across Section 8 + Section 9:

| Section 8 | Section 9 |
|---|---|
| Single-process RAG (sync) | Distributed RAG (async + queue) |
| Direct user input | FastAPI routes |
| Inline retrieval | Worker-based retrieval |
| ~80 lines | ~150 lines |
| Toy demo | Production-shaped |

**Next**: **Section 10 — Multi Modal Agents** — agents that handle images, audio, video.

---

## 12. Production deployment preview

For real deployment, the pattern extends to:

```
┌──────────────────────────────────────────────────────────────┐
│   Load balancer (nginx / ALB)                                │
└─────────────────────┬────────────────────────────────────────┘
                      │
       ┌──────────────┼──────────────┐
       ▼              ▼              ▼
   FastAPI #1     FastAPI #2     FastAPI #3      ← horizontal API scaling
       │              │              │
       └──────────────┼──────────────┘
                      │
                      ▼
              ┌───────────────┐
              │  Valkey       │      ← shared broker
              │  (managed)    │
              └───────────────┘
                      │
       ┌──────────────┼──────────────┐
       ▼              ▼              ▼
   Worker #1      Worker #2      Worker #3       ← horizontal worker scaling
                                                   (auto-scaled on queue depth)
```

Add: monitoring, logging, retries, DLQ, rate limiting, authentication. Same core architecture.

---

## 13. Main takeaways

- **`rq worker`** in a separate terminal pulls jobs and runs them.
- Multiple workers in **separate terminals** = parallel processing.
- 3 workers = up to **3 concurrent jobs**.
- **macOS fork bug** needs `export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES`.
- Workers can run on **different machines** — Valkey is the shared coordination point.
- Worker process model: **listen → fork → child runs job → child exits → repeat**.
- Crashing job ≠ crashed worker (fork isolation).
- **End-to-end async pipeline complete**: submit → enqueue → worker → result → poll.
- Production: managed Valkey + Dockerized workers + auto-scaling.
- Section 9 closes. Next: **multi-modal agents**.

---

## 14. Things I still want to figure out

- For **production**, what's the right **worker:CPU ratio** for OpenAI-bound work?
- How to **auto-scale workers** based on queue depth?
- For **failed jobs**, what's the right retry + alert pattern?
- How to **avoid duplicate processing** if a job is retried?
- What's the right way to **graceful-shutdown** workers (drain in-flight jobs)?
- For **cost tracking**, log token usage per job how?
- How does **gunicorn worker class** for FastAPI interact with RQ workers?

---

## 15. Things to dig into

- **RQ worker docs**: https://python-rq.org/docs/workers/
- **Docker for RQ workers**: standard pattern; one container per worker.
- **Horizontal Pod Autoscaling for RQ on Kubernetes**: production scaling pattern.
- **Hands-on**: deploy this stack to a free tier (Render, Railway, Fly.io). End-to-end production deployment.

---

## 16. Next up

End of Section 9. Next:

- [ ] **Section 10: Multi Modal Agents** — agents that handle images, audio, video.

---

## Related
- [[08 - The Get Result Route - Fetching Job Status]] — the route this note makes work.
- [[05 - Creating the Worker (process_query)]] — what the workers run.
- [[02 - Queues in System Design]] — why this scales.
- [[01 - Section Intro - Why Async]] — section motivation.

## Sources
- [RQ worker docs](https://python-rq.org/docs/workers/)
- [OBJC_DISABLE_INITIALIZE_FORK_SAFETY background](https://github.com/rq/rq/issues/1418)
- [Valkey documentation](https://valkey.io/)
