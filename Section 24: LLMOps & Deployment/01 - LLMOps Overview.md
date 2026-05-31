---
title: LLMOps Overview
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 24: LLMOps & Deployment"
tags:
  - llmops
  - mlops
  - deployment
  - foundations
related:
  - "[[05 - Tracing and Observability]]"
  - "[[02 - Serving LLMs at Scale]]"
---

# LLMOps Overview

> [!NOTE]
> **TL;DR**
> **LLMOps** is the practice of taking LLM apps from a working prototype to a **reliable, monitored, maintainable production system** — the operational discipline around everything else in these gap sections. It borrows from **MLOps** but differs: there's usually **no training** (you call APIs or serve open models), the "artifact" you version is often a **prompt** (not weights), quality is **non-deterministic** and needs eval (§17), and cost is **per-token at runtime** (§20). The LLMOps lifecycle: **develop** (prompts/chains/agents) → **evaluate** (§17) → **deploy** (serve, §02) → **monitor/observe** (§17/§05) → **iterate** (feed failures back) — a continuous loop. The pillars this section covers: serving at scale, **reliability** (retries/fallbacks/rate limits), **versioning/CI-CD** for prompts and models, **monitoring** in production, and **deployment patterns**.

> [!NOTE]
> **Where this fits**
> First note of **Section 24: LLMOps & Deployment** — the operational umbrella. It ties together eval (§17), cost (§20), and security (§19) into "running it in production," and frames the rest of the section.

---

## 1. What LLMOps is

LLMOps = **MLOps for LLM-powered applications**: the tooling, processes, and discipline to **build, deploy, run, and improve** LLM apps reliably in production.

```
prototype that works on your laptop  ──LLMOps──►  reliable service real users depend on
```

It's the connective tissue: evaluation, observability, cost control, safety, serving, deployment, and iteration all working together.

---

## 2. LLMOps vs MLOps — the key differences

| Aspect | Classic MLOps | LLMOps |
|---|---|---|
| Core artifact | A trained **model** (weights) | Often a **prompt / chain / agent** config |
| Training | You train the model | Usually **no training** — call an API or serve a base model (FT optional, §21) |
| Evaluation | Accuracy on a test set | **Non-deterministic, open-ended** → eval suite + judges (§17) |
| Cost | Mostly **training** compute | Mostly **inference** (per-token) at runtime (§20) |
| Iteration unit | Retrain | **Edit a prompt** / swap a model (fast) |
| Failure mode | Wrong prediction | **Plausible but wrong** (hallucination, §19) |

> [!IMPORTANT]
> **The big mental shift: prompts are the deployable artifact**
> In a lot of LLM apps you never train anything — your "code" that determines behavior is the **prompt** (plus chain/agent structure and model choice). That means prompts need the same rigor as code: **versioning, testing (eval), CI/CD, rollback** (note 04). This is unintuitive coming from either traditional software or classic ML.

---

## 3. The LLMOps lifecycle

```
   ┌──────────────────────── continuous loop ────────────────────────┐
   ▼                                                                  │
DEVELOP ──► EVALUATE ──► DEPLOY ──► MONITOR ──► (failures → data) ────┘
(prompts,   (§17 suite,  (serve,   (observe,
 chains,     judges)      §02)      §05/§17)
 agents)
```

1. **Develop** — build/iterate prompts, chains, agents, RAG.
2. **Evaluate** — gate changes on the eval suite (§17). *No ship without eval.*
3. **Deploy** — serve reliably (notes 02–03), behind versioning (note 04).
4. **Monitor** — trace, track quality/cost/latency/errors (§17, note 05).
5. **Iterate** — production failures → eval set → next dev cycle.

This is the same online/offline loop from §17, viewed operationally.

---

## 4. The pillars (this section)

| Pillar | Note | Question it answers |
|---|---|---|
| **Serving at scale** | [[02 - Serving LLMs at Scale]] | How do I run inference fast + cheap for many users? |
| **Reliability** | [[03 - Reliability - Retries, Fallbacks, Rate Limits]] | How do I survive failures, timeouts, limits? |
| **Versioning & CI/CD** | [[04 - Versioning and CI-CD for LLM Apps]] | How do I ship prompt/model changes safely? |
| **Monitoring** | [[05 - Monitoring in Production]] | How do I know it's healthy in production? |
| **Deployment patterns** | [[06 - Deployment Patterns]] | Where/how does it actually run? |

Plus the cross-cutting disciplines already covered: **eval (§17)**, **cost (§20)**, **security (§19)**, **observability (§17)**.

---

## 5. Why it matters

> [!WARNING]
> **The demo-to-production gap is where projects die**
> A prototype that works on happy-path inputs on your machine is maybe 20% of the work. Production demands: it stays up under load, handles provider outages/rate limits, doesn't blow the budget, doesn't regress when you tweak a prompt, is monitored, and is safe. LLMOps is the discipline that closes that gap — without it, AI projects stall at "cool demo."

---

## 6. The LLMOps tooling landscape (orientation)

- **Eval + observability**: LangSmith, Langfuse, Phoenix (§17).
- **Prompt management/versioning**: LangSmith, Langfuse, PromptLayer (note 04).
- **Serving**: vLLM, TGI, Ollama (§5), managed APIs (note 02).
- **Orchestration**: LangChain, LangGraph (§11).
- **Gateways**: LiteLLM, OpenRouter (unify providers, add retries/fallbacks — note 03).
- **Deployment**: Docker (§5), Kubernetes, serverless (note 06).

Don't adopt all of it — start with eval + observability + a serving choice, and add as needed.

---

## 7. Main takeaways

- **LLMOps** = the operational discipline to run LLM apps **reliably in production**.
- It's **MLOps adapted**: often **no training**, the artifact is often a **prompt**, quality is **non-deterministic** (needs eval, §17), cost is **per-token at runtime** (§20).
- **Prompts are deployable artifacts** → version, test, CI/CD, roll back like code.
- Lifecycle: **develop → evaluate → deploy → monitor → iterate** (continuous).
- Pillars: **serving, reliability, versioning/CI-CD, monitoring, deployment** — plus eval/cost/security.
- The **demo-to-production gap** is where most AI projects fail; LLMOps closes it.

---

## 8. Things I still want to figure out

- Minimal LLMOps stack for a small team / solo project?
- Build vs buy for prompt management + observability?
- How heavy is the ops burden for an API-only app vs a self-hosted model?

---

## 9. Things to dig into

- LLMOps overviews + the lifecycle diagrams from observability vendors.
- **LiteLLM** gateway (unify providers).
- Cross-links: eval (§17), cost (§20), security (§19).
- Next: [[02 - Serving LLMs at Scale]].

---

## 10. Next up in this section

- [ ] [[02 - Serving LLMs at Scale]] — fast, efficient inference for many users.

---

## Related
- [[05 - Tracing and Observability]] — the monitoring half of the lifecycle.
- [[01 - Understanding LLM Cost and Tokens]] — runtime cost, the LLMOps cost center.

## Sources
- [LangSmith / LLMOps](https://docs.smith.langchain.com/)
- [LiteLLM](https://docs.litellm.ai/)
