---
title: Deployment Patterns
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 24: LLMOps & Deployment"
tags:
  - llmops
  - deployment
  - docker
  - serverless
  - architecture
related:
  - "[[02 - Serving LLMs at Scale]]"
  - "[[06 - Setting up FastAPI Server]]"
---

# Deployment Patterns

> [!NOTE]
> **TL;DR**
> How an LLM app actually runs in production. The typical architecture: a **stateless API service** (FastAPI, §5/§9) wrapping your prompts/chains/agents, behind a load balancer, talking to **external state** (vector DB §8, memory DB §13, cache §20) and the **LLM** (managed API or self-hosted server, §02). Packaging is **Docker** (§5), orchestrated by **Kubernetes** or a managed platform for scaling. The big split: **API-only apps** (call a provider) deploy like any normal web service — easy, CPU-only, serverless-friendly; **self-hosted-model apps** need **GPUs**, which complicates everything (cost, autoscaling, cold starts). Key patterns: keep the app **stateless** (state in external stores) so it scales horizontally; use **async** (§9) for long LLM calls; and for spiky/long jobs, the **queue + workers** pattern from §9. Match the pattern to whether you serve a model yourself.

> [!NOTE]
> **Where this fits**
> Final note of **Section 24**. It assembles the serving (§02), reliability (§03), and the FastAPI/async/queue work from §5 and §9 into deployment architectures.

---

## 1. The typical architecture

```
        users
          │
   ┌──────▼───────┐
   │ load balancer│
   └──────┬───────┘
   ┌──────▼───────────────┐      ┌── LLM (managed API  or  self-hosted vLLM/TGI §02)
   │ stateless API service│──────┤── vector DB (Qdrant §8)
   │ (FastAPI: prompts,   │      ├── memory DB (Mongo/Neo4j §12-14)
   │  chains, agents)     │      ├── cache (semantic/prompt §20)
   └──────────────────────┘      └── queue/workers (Valkey/RQ §9)
```

The app service itself is mostly **glue + orchestration**; the heavy state lives in external stores, and the heavy compute lives in the LLM.

---

## 2. The defining question: do you serve a model?

> [!IMPORTANT]
> **API-only vs self-hosted-model changes everything about deployment**
>
> | | **API-only** (call a provider) | **Self-hosted model** (§02) |
> |---|---|---|
> | Hardware | **CPU** (just makes HTTP calls) | **GPU** (expensive, scarce) |
> | Deploy target | Anywhere (serverless, small containers) | GPU nodes (K8s + GPU, GPU cloud) |
> | Scaling | Easy, cheap, fast | Hard — GPU autoscaling, cold starts |
> | Ops burden | Low | High |
>
> Most apps are **API-only** and deploy like a normal stateless web service. **Self-hosting a model** is a different, GPU-heavy operational world (§02) — only take it on for the reasons in §02 (privacy, volume, custom models).

---

## 3. Keep the app stateless

> [!TIP]
> **Stateless app + external state = easy horizontal scaling**
> Don't keep conversation/memory/session state **in the app process** — push it to external stores (memory DB §13, checkpointer §12, cache §20). Then any instance can handle any request, and you scale by **adding identical replicas** behind the load balancer. This is why the §13 memory layer and §12 checkpointing store state in MongoDB/Qdrant/Neo4j rather than in memory — it makes the app horizontally scalable.

```
stateful app:   each instance holds sessions → can't freely add/remove instances
stateless app:  state in external DB → add/remove instances at will → autoscale
```

---

## 4. Async and long-running calls

LLM calls are **slow** (seconds; §20). A synchronous request-per-call model ties up server resources and risks timeouts.

| Pattern | When | From |
|---|---|---|
| **Async endpoints** | Standard chat | `async` FastAPI (§5) |
| **Streaming** | Chat UIs | stream tokens (§20) |
| **Queue + workers** | Long/spiky/batch jobs | the **§9 pattern** (submit → job id → poll) |

The **§9 scalable-RAG architecture** (FastAPI enqueues → RQ workers process → poll for result) is the canonical deployment pattern for workloads that are too slow/bursty for synchronous handling. It also doubles as rate-limit smoothing (§03).

---

## 5. Packaging and orchestration

| Layer | Tool |
|---|---|
| **Package** | **Docker** (§5) — containerize the app |
| **Orchestrate / scale** | **Kubernetes**, or managed (ECS, Cloud Run, Render, Railway, Fly.io) |
| **Serverless** | Lambda / Cloud Functions / Cloud Run — great for **API-only**, CPU, spiky traffic |
| **GPU hosting** | GPU clouds / K8s with GPU nodes — for **self-hosted models** (§02) |

```
API-only, spiky traffic    → serverless / managed container platform (cheap, autoscale)
steady traffic / control   → containers on K8s
self-hosted model          → GPU nodes (K8s + GPU or GPU cloud) — heavier ops
```

> [!WARNING]
> **Serverless + GPU + cold starts don't mix well**
> Serverless is ideal for API-only apps (CPU, scale-to-zero). But serving a **model** on serverless GPU suffers **cold starts** — loading a multi-GB model into a freshly-spun GPU can take many seconds, killing latency. For self-hosted models, prefer **always-warm** GPU instances with autoscaling, not scale-to-zero serverless.

---

## 6. Environments and config

Standard hygiene, with LLM specifics:
- **Dev / staging / prod** environments; promote changes through them (with eval gates, §04).
- **Secrets** (API keys) in a secret manager, never in code/images (§19).
- **Config per env**: model names/versions (pinned, §04), rate limits, feature flags.
- **Infrastructure as code** (Terraform, etc.) for reproducible environments.

---

## 7. Putting the whole stack together

```
DEV     → prompts/chains/agents in code, versioned (§04)
TEST    → eval suite gate (§17) in CI
PACKAGE → Docker image
DEPLOY  → stateless API behind LB; canary rollout (§04)
         ├─ LLM: managed API (default) or self-hosted vLLM/TGI on GPU (§02)
         ├─ state: vector DB (§8), memory (§13/14), cache (§20) — external
         ├─ async/queue for slow jobs (§9); reliability: retries/fallbacks (§03)
RUN     → monitor quality/cost/latency/drift + alert (§05) → failures feed eval (§17)
```

This is the entire arc of these gap sections, assembled into a running production system.

---

## 8. Main takeaways

- Typical architecture: **stateless API service** (FastAPI) + **external state** (vector/memory/cache DBs) + **LLM** (managed or self-hosted).
- The defining question is **API-only vs self-hosted model**: API-only = CPU, easy, serverless-friendly; self-hosted = **GPU**, hard scaling, high ops.
- Keep the app **stateless** (state in external stores) → scale by adding **replicas**.
- LLM calls are slow → use **async**, **streaming**, and the **queue+workers (§9)** pattern for long/spiky jobs.
- Package with **Docker (§5)**; orchestrate with **Kubernetes / managed platforms / serverless**.
- **Serverless GPU cold starts** make self-hosted models prefer always-warm instances.
- Standard hygiene: **dev/staging/prod, secret management, pinned config, IaC**.
- It all assembles the §17/§19/§20/§02–05 pieces into one running system.

---

## 9. Things I still want to figure out

- Cheapest reliable way to host a **self-hosted model** without idle GPU cost?
- Managed platform (Cloud Run/Render) vs full **K8s** for an API-only app at my scale?
- Best pattern for **streaming** through a load balancer / serverless?

---

## 10. Things to dig into

- **Docker (§5)** + **Kubernetes** (GPU scheduling) basics.
- Managed platforms: Cloud Run, Render, Railway, Fly.io; serverless (Lambda).
- The **§9 queue + workers** deployment pattern.
- **Terraform** for IaC.

---

## 11. Section wrap-up

Section 24 covers **LLMOps & deployment**: the operational umbrella (§01), **serving at scale** (§02), **reliability** (§03), **versioning/CI-CD with eval gates** (§04), **monitoring** (§05), and **deployment patterns** (this note). Together with eval (§17), safety (§19), and cost (§20), it's the full "make it production-grade" toolkit — turning the demos from the course into systems real users can depend on.

---

## Related
- [[02 - Serving LLMs at Scale]] — the LLM-hosting decision this builds on.
- [[06 - Setting up FastAPI Server]] / [[02 - Queues in System Design]] — the app + queue patterns (§5/§9).

## Sources
- [Docker](https://docs.docker.com/) · [Kubernetes](https://kubernetes.io/docs/)
- [FastAPI deployment](https://fastapi.tiangolo.com/deployment/)
