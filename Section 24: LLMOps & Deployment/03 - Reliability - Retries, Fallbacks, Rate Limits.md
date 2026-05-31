---
title: Reliability - Retries, Fallbacks, Rate Limits
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 24: LLMOps & Deployment"
tags:
  - llmops
  - reliability
  - retries
  - rate-limits
  - fallbacks
related:
  - "[[02 - Serving LLMs at Scale]]"
  - "[[04 - Versioning and CI-CD for LLM Apps]]"
---

# Reliability - Retries, Fallbacks, Rate Limits

> [!NOTE]
> **TL;DR**
> LLM calls fail in production — providers have **outages**, enforce **rate limits**, time out, and occasionally return garbage. A reliable app plans for all of it. **Retries with exponential backoff + jitter** handle transient errors (rate limits, 5xx, timeouts) — but only **idempotent** retries, with a cap. **Fallbacks** keep you running when a provider is down or limited: fall back to another provider/model, a cached answer (§20), or a graceful degraded response. **Rate limits** (RPM/TPM) must be respected proactively — queue and throttle requests (the §9 queue pattern), don't just hammer and retry. A **model gateway** (LiteLLM, OpenRouter) centralizes retries, fallbacks, and rate-limit handling across providers. The mindset: treat the LLM API as an **unreliable external dependency** and engineer around it, exactly like any third-party service.

> [!NOTE]
> **Where this fits**
> Third note of **Section 24**. It hardens the serving from [[02 - Serving LLMs at Scale]] against real-world failure, and reuses the queue pattern from §9 (async RAG).

---

## 1. LLM APIs fail — plan for it

```
failure modes:
  • rate limit (429)        — too many requests/tokens per minute
  • server error (5xx)      — provider hiccup / outage
  • timeout                 — slow generation / network
  • content filter / refusal
  • malformed output        — invalid JSON, wrong format (§19 guardrails)
  • degraded quality        — provider issues
```

> [!IMPORTANT]
> **The LLM API is an unreliable external dependency**
> Treat it like any third-party service that can be slow, rate-limited, or down. The question isn't *if* calls fail but *how your app behaves when they do*. Reliability engineering here is standard distributed-systems practice applied to LLM calls.

---

## 2. Retries with exponential backoff

For **transient** errors (429, 5xx, timeout), retry — but smartly:

```
attempt 1 → fail → wait ~1s  (+ jitter) → 
attempt 2 → fail → wait ~2s  (+ jitter) →
attempt 3 → fail → wait ~4s  (+ jitter) → give up / fallback
```

- **Exponential backoff**: double the wait each time (don't hammer a struggling service).
- **Jitter**: add randomness so many clients don't retry in sync (thundering herd).
- **Cap** retries (e.g. 3–5) and total time — don't retry forever.

> [!WARNING]
> **Only retry idempotent operations**
> A plain completion is safe to retry. But if the call had a **side effect** (an agent sent an email, charged a card, wrote to a DB via a tool, §7/§19), a naive retry can **do it twice**. Make tool actions idempotent (or guard them) before retrying agent calls. Also: don't retry **non-transient** errors (bad request, auth, content policy) — they'll just fail again.

```python
# conceptual retry with backoff (libraries: tenacity, or SDK built-ins)
for attempt in range(MAX_RETRIES):
    try:
        return client.chat.completions.create(...)
    except (RateLimitError, APITimeoutError, InternalServerError):
        sleep(base * 2**attempt + random_jitter())   # backoff + jitter
    # don't catch/retry BadRequestError, AuthError, content-policy
raise   # or fall back (next section)
```

---

## 3. Fallbacks — degrade gracefully

When retries are exhausted or a provider is down, **fall back** instead of failing:

| Fallback | Example |
|---|---|
| **Another provider/model** | OpenAI down → switch to Anthropic/Gemini (or a self-hosted model, §02) |
| **Cached answer** | Serve a semantically-cached response (§20) |
| **Smaller/faster model** | Primary overloaded → cheaper model (ties to routing, §20) |
| **Graceful message** | "We're having trouble — try again shortly" (never a stack trace) |
| **Queue for later** | Accept the request, process when capacity returns (§9) |

```
primary model → (retries fail) → fallback model → (also fails) → cached / graceful message
```

> [!TIP]
> **Multi-provider fallback is also a resilience strategy**
> Depending on a single provider is a single point of failure. Designing your client to **switch providers** on outage (same OpenAI-compatible interface helps, §2/§02) keeps you up during a provider incident. A gateway (below) makes this declarative.

---

## 4. Respecting rate limits (proactively)

Providers cap **RPM** (requests/min) and **TPM** (tokens/min). Blowing past them → 429s.

Reactive (retry on 429) is the floor; **proactive** is better:
- **Client-side rate limiting / token bucket** — cap your own send rate below the limit.
- **Queue + workers** — exactly the **§9 pattern** (Valkey/RQ): enqueue requests, workers drain at a controlled rate. This smooths bursts and decouples user-facing latency from provider limits.
- **Concurrency limits** — cap simultaneous in-flight calls.
- **Track usage** — monitor TPM/RPM headroom (§05 monitoring).

```
burst of 1000 requests → QUEUE (§9) → workers pull at safe rate → no 429 storms
```

---

## 5. Timeouts and circuit breakers

- **Set explicit timeouts** — never wait indefinitely on a hung call; fail fast to a fallback.
- **Circuit breaker**: if a provider is failing repeatedly, **stop sending** to it for a cooldown (and use the fallback) instead of retrying into a wall — protects both you and the struggling service.

---

## 6. Model gateways — centralize it all

> [!IMPORTANT]
> **A gateway turns reliability into config**
> Tools like **LiteLLM** and **OpenRouter** sit between your app and providers, offering one unified (OpenAI-compatible) API plus built-in **retries, fallbacks, load balancing, rate-limit handling, and cost tracking** across providers. Instead of coding backoff/fallback everywhere, you declare "primary: model A, fallback: model B, retries: 3" and the gateway handles it. Great for multi-provider resilience and centralized control.

```
your app → [gateway: retries + fallbacks + rate limits + routing] → many providers
```

---

## 7. Main takeaways

- LLM APIs **fail** (rate limits, outages, timeouts, bad output) — engineer for it.
- Treat the API as an **unreliable external dependency**.
- **Retries with exponential backoff + jitter**, capped — for **transient** errors only.
- **Only retry idempotent** calls; agent tool side-effects can double-execute.
- **Fallbacks**: another provider/model, cached answer, smaller model, graceful message, or queue.
- **Multi-provider fallback** removes a single point of failure.
- **Respect rate limits proactively**: client-side throttling + **queue/workers (§9)**, not just retry-on-429.
- Use **timeouts** + **circuit breakers**; consider a **gateway** (LiteLLM/OpenRouter) to centralize all of it.

---

## 8. Things I still want to figure out

- Good default backoff/retry caps for chat vs batch workloads?
- Building idempotent agent tool calls for safe retries?
- Gateway (LiteLLM) vs hand-rolled reliability — when to adopt?

---

## 9. Things to dig into

- **tenacity** (Python retries) + SDK built-in retry options.
- **LiteLLM** / **OpenRouter** fallbacks + load balancing.
- The **§9 queue pattern** (Valkey/RQ) for rate-limit smoothing.
- Next: [[04 - Versioning and CI-CD for LLM Apps]].

---

## 10. Next up in this section

- [ ] [[04 - Versioning and CI-CD for LLM Apps]] — ship prompt/model changes safely.

---

## Related
- [[02 - Serving LLMs at Scale]] — the serving this makes resilient.
- [[02 - Queues in System Design]] — the queue pattern for rate-limit smoothing (§9).

## Sources
- [LiteLLM (retries/fallbacks)](https://docs.litellm.ai/docs/completion/reliable_completions)
- [tenacity](https://tenacity.readthedocs.io/)
