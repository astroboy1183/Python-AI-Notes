---
title: Queues in System Design
date: 2026-05-28
source: "Section 9 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 9: Scalable RAG with Async Queues & Distributed Workers"
tags:
  - queues
  - system-design
  - fifo
  - producer-consumer
  - async
  - message-broker
  - foundations
related:
  - "[[01 - Section Intro - Why Async]]"
  - "[[03 - Setting up Valkey (Redis Alternative)]]"
---

# Queues in System Design

> [!abstract] TL;DR
> A **queue** is a **FIFO (First-In, First-Out)** data structure: jobs enter at the back, processors take them from the front. In system design, queues sit between a **producer** (the FastAPI server accepting user requests) and one or more **consumers** (background workers running the actual work). Why this matters: the producer can stay **fast and responsive** while slow work happens behind the scenes. Without a queue, every long task blocks the request thread. With a queue, the server **pushes the job and returns immediately**; workers process at their own pace. This is the architecture behind nearly every modern web service that does anything beyond serving static pages.

> [!info] Where this fits
> Second lecture of **Section 9: Scalable RAG with Async Queues & Distributed Workers**. Pure concept — no code yet. The next lecture ([[03 - Setting up Valkey (Redis Alternative)]]) installs the technology that implements this queue.

---

## 1. The FIFO data structure

A queue:

```
                  ┌─────────────────────────────────┐
   In  ──────────►│ J7  J6  J5  J4  J3  J2  J1     │──────────► Out
                  └─────────────────────────────────┘
                                                ▲
                                                │
                              Oldest job (J1) leaves first
```

Properties:
- **First in, first out** — order preserved.
- **Producer** adds to one end.
- **Consumer** removes from the other.
- Independent — producers and consumers don't know about each other.

Contrast with a **stack** (LIFO — last in, first out), used for things like undo history or function call frames.

For job processing, FIFO matches intuition: jobs submitted earlier get processed earlier (mostly — see priority queues below).

---

## 2. The producer-consumer pattern

```
┌────────────────┐      ┌──────────────┐      ┌────────────────┐
│   PRODUCER     │      │    QUEUE     │      │   CONSUMER     │
│                │      │              │      │                │
│  FastAPI       │      │   Valkey /   │      │  Worker        │
│  server        │ ───► │   Redis      │ ───► │  process_query │
│                │      │   (broker)   │      │                │
│                │      │              │      │                │
└────────────────┘      └──────────────┘      └────────────────┘
        │                                              │
        │                                              │
        ▼                                              ▼
   Stays fast,                                   Slow work happens
   serves more                                   in background,
   requests                                      independent rate
```

Each role decouples from the others:
- **Producer** doesn't know how many consumers exist or how busy they are.
- **Consumer** doesn't know who submitted the job.
- **Queue** has no business logic — just stores and dispatches.

This **decoupling** is what makes the system scalable. Add more consumers → throughput increases. Producer code stays the same.

---

## 3. Concrete scenario

### Without a queue
```
User submits: "Tell me about Node.js debugging"
       │
       ▼
FastAPI server runs the full RAG pipeline inline:
   1. Embed query (~300ms)
   2. Vector search (~50ms)
   3. LLM call (~3000ms)
       │
   Server thread is BLOCKED for ~3.5 seconds
       │
       │  ← other users hit the server here, get nothing
       │
       ▼
Returns the answer
```

Bad UX: while the server is busy resolving one user's query, every other user is stuck waiting.

### With a queue
```
User submits: "Tell me about Node.js debugging"
       │
       ▼
FastAPI server:
   1. Push job into queue (~5ms)
   2. Return job_id
       │
       │  ← server is FREE, can handle more requests
       │
       ▼
Returns { "job_id": "abc123", "status": "queued" }

Meanwhile, in background:
   - Worker process pulls job from queue
   - Runs the full RAG pipeline
   - Writes result back to queue store

User polls later:
   GET /job_status?job_id=abc123
   → returns the result
```

Same total compute, much better UX. Server throughput goes from "1 request every 3.5 seconds" to "thousands per second".

---

## 4. Why this is universal

The pattern is everywhere. A non-exhaustive list:

| System | Producer | Queue | Consumer |
|---|---|---|---|
| **Email sending** | Web app submits email | SMTP queue | Mail server |
| **Stripe payments** | Checkout button | Stripe's queue | Payment processor |
| **Video encoding** | Upload | FFmpeg queue | Encoder farm |
| **Slack file scan** | File upload | Internal queue | Virus scanner |
| **GitHub Actions** | Push event | Action queue | Runner |
| **Train tickets** | Booking request | Reservation queue | Allocator |
| **Doctor's clinic** | Patient arrives | Waiting room | Doctor |
| **Restaurant** | Order placed | Kitchen ticket rail | Chef |
| **Phone support** | Call comes in | "All agents are busy" hold | Agent |

The model is so general that "queues" appear in every CS curriculum. Production systems just lift the pattern from textbooks.

---

## 5. Producer-consumer benefits (decoupling)

| Benefit | What it means |
|---|---|
| **Asynchronous** | Producer doesn't wait for consumer |
| **Scalable** | Add consumers → throughput grows |
| **Resilient** | Crashed consumer doesn't lose jobs (queue persists) |
| **Decoupled** | Producer doesn't know about consumers |
| **Rate-limiting** | Queue acts as buffer during traffic spikes |
| **Retry-friendly** | Failed jobs can be re-queued |
| **Auditable** | Queue logs the entire job history |
| **Cross-language** | Producer and consumer can be different languages |

The last one is huge in real architectures: Python producer, Go consumer, both speaking through Redis. The queue is the **language-agnostic interface**.

---

## 6. Queue technologies — the landscape

This section uses **RQ + Valkey** (Python-friendly, simple). Production-scale alternatives:

| System | Language ecosystem | Strengths |
|---|---|---|
| **RQ (Redis Queue)** | Python | Simple, lightweight, learning-friendly |
| **Celery** | Python | Mature, many features |
| **Sidekiq** | Ruby | Industry standard for Ruby |
| **Bull / BullMQ** | Node.js | TypeScript-first |
| **RabbitMQ** | Polyglot | Advanced routing, AMQP protocol |
| **Apache Kafka** | Polyglot | Distributed, very high throughput |
| **AWS SQS** | Polyglot | Managed, infinitely scalable |
| **Google Pub/Sub** | Polyglot | Managed, push delivery |
| **Temporal / Cadence** | Polyglot | Workflow orchestration on top |

All have the same conceptual model: **producer pushes, consumer pulls (or gets pushed), queue persists in between**. APIs differ.

For learning RAG-with-queues, **RQ** is the right pick — minimal setup, Python-native. For really high-scale or cross-service production, Kafka / RabbitMQ / Temporal are common upgrades.

---

## 7. Vocabulary worth knowing

When reading about queue-based architectures, this vocabulary appears:

| Term | Meaning |
|---|---|
| **Producer / publisher** | The thing putting items in |
| **Consumer / subscriber / worker** | The thing taking items out |
| **Broker** | The queue server itself (Redis, RabbitMQ, etc.) |
| **Job / message / task** | The thing in the queue |
| **Topic** | A named queue (for fan-out — Kafka, Pub/Sub) |
| **Acknowledgment (ack)** | Consumer confirms it processed the message |
| **Visibility timeout** | Time before unacked message becomes visible again |
| **Dead-letter queue (DLQ)** | Where failed messages go after N retries |
| **Backpressure** | Slowing producers when consumers can't keep up |
| **Idempotency** | Same message processed twice → same result |

"Producer" and "consumer" are the core vocab; the rest become relevant in production-scale setups.

---

## 8. Pull vs push consumers

Two ways consumers receive jobs:

| Mode | How it works | Used by |
|---|---|---|
| **Pull** | Consumer polls queue: "any job?" | RQ, Celery, SQS |
| **Push** | Queue pushes job to subscribed consumer | RabbitMQ, Kafka, Pub/Sub |

Pull = simpler to reason about, slightly less efficient.
Push = better latency, more complex protocol.

This section uses RQ → pull. Consumers run a polling loop.

---

## 9. Priority queues — a wrinkle

Strict FIFO breaks down when some jobs matter more:

- VIP customer's request should jump the line.
- Refund cancellation should beat new orders.
- System health checks should preempt user requests.

**Priority queues** are FIFO **within each priority level**, with higher-priority jobs taken first.

RQ supports multiple queues (`high`, `default`, `low`) — workers can be configured to drain higher-priority queues first. For Section 9's scope, single queue is plenty.

---

## 10. Why the queue lives outside the FastAPI process

A subtle but important architectural detail:

The queue **isn't** an in-process data structure (`queue.Queue` from Python's standard library). It lives in an **external process** (Valkey / Redis).

Why:
- Server crash → jobs persist (in Redis).
- Multiple FastAPI instances behind a load balancer → share the same queue.
- Workers can run on different machines.
- Queue is **the source of truth**, not memory.

In-process queues are fine for single-process apps; out-of-process queues are required for **distributed systems**. Production = distributed.

---

## 11. Main takeaways

- A **queue** = FIFO buffer between producer and consumer.
- **Producer-consumer pattern** decouples request acceptance from request processing.
- Without a queue, slow operations **block** the server thread.
- With a queue, server stays fast; work happens in background.
- The pattern is **universal** — Stripe, Slack, GitHub, every SaaS uses it.
- **Decoupling** = scalability + resilience + cross-language + auditability.
- Many queue technologies (RQ, Celery, RabbitMQ, Kafka, SQS, etc.) — same model, different APIs.
- Section uses **RQ** (simple Python).
- Queue lives **out-of-process** in Redis/Valkey — survives crashes, supports distributed setup.

---

## 12. Things I still want to figure out

- For **really high throughput**, when does RQ break down vs needing Kafka?
- How does **back-pressure** work in queue systems?
- What's the **right way** to handle a job that needs to call back to the user (push vs poll)?
- For **idempotency**, how to ensure a worker doesn't process the same job twice?
- How do **priority queues** work in RQ specifically?
- What's the role of **dead-letter queues** in real systems?

---

## 13. Things to dig into

- **The RQ docs**: https://python-rq.org/
- **Celery vs RQ**: https://python-rq.org/docs/ (RQ explicitly positions itself vs Celery)
- **Designing Data-Intensive Applications** by Martin Kleppmann — Chapter 11 on stream processing.
- **AWS SQS docs** for a managed-queue perspective.

---

## 14. Next up in this section

Set up the queue infrastructure (Valkey):

- [ ] [[03 - Setting up Valkey (Redis Alternative)]] — Docker Compose entry for the message broker.

---

## Related
- [[01 - Section Intro - Why Async]] — section motivation.
- [[03 - Setting up Valkey (Redis Alternative)]] — implementation of this concept.
- [[02 - What are AI Agents]] — agents internally use similar dispatcher patterns.

## Sources
- [RQ documentation](https://python-rq.org/)
- [Redis / Valkey documentation](https://valkey.io/)
- *Designing Data-Intensive Applications* by Martin Kleppmann — Chapter 11 (stream processing).
