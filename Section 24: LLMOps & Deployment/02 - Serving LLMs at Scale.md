---
title: Serving LLMs at Scale
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 24: LLMOps & Deployment"
tags:
  - llmops
  - serving
  - vllm
  - inference
  - throughput
related:
  - "[[01 - LLMOps Overview]]"
  - "[[03 - Running Ollama in Docker]]"
---

# Serving LLMs at Scale

> [!NOTE]
> **TL;DR**
> The first deployment decision: **managed API** (OpenAI/Anthropic/Gemini — they serve the model, you just call it) vs **self-hosted** (you run an open model on your own GPUs). Managed = zero infra, instant scale, pay-per-token; self-hosted = control, privacy (§19), and lower cost **at high volume**, but you own the serving. If self-hosting, you don't use raw `transformers` for production — you use an **inference server** like **vLLM** or **TGI** that delivers high **throughput** via tricks like **continuous batching** (pack many requests through the GPU together) and **PagedAttention** (efficient KV-cache memory). The metrics that matter: **throughput** (requests/tokens per second across users) and **latency** (TTFT + per-token, §20). The art is **batching** — serving many concurrent users efficiently rather than one at a time.

> [!NOTE]
> **Where this fits**
> Second note of **Section 24**. It scales up the local-model work from §5 ([[03 - Running Ollama in Docker]]) to production serving, and feeds reliability (note 03) and deployment (note 06).

---

## 1. The fork: managed API vs self-hosted

```
MANAGED API                          SELF-HOSTED
provider runs the model              you run an open model on your GPUs
call it over HTTP                    you operate the inference server
pay per token                        pay for GPUs (fixed) + ops
instant scale, zero infra            control, privacy, cheaper at volume
```

| | Managed API | Self-hosted |
|---|---|---|
| Infra/ops | None | **You own it** |
| Scaling | Provider handles | Your problem |
| Cost model | Per-token | Per-GPU-hour (cheaper at **high, steady** volume) |
| Privacy/control | Data leaves your env | **Full control** (§19) |
| Model choice | Provider's models | **Any open model**, fine-tuned (§21) |
| Best for | Most apps, getting started | High volume, privacy needs, custom models |

> [!TIP]
> **Default to a managed API; self-host when there's a clear reason**
> Most apps should start on a managed API — no GPUs, no serving, instant scale. Self-host when you have a concrete driver: **privacy/compliance** (§19), **high steady volume** where per-GPU economics beat per-token, or a **fine-tuned/open model** you must run yourself. Self-hosting trades a token bill for an ops burden.

---

## 2. Self-hosting: don't use raw `transformers` in prod

The Hugging Face `transformers` library (§6) is great for experimentation but **single-request, unoptimized** — terrible for serving many users. Production needs a dedicated **inference server**:

| Server | Notes |
|---|---|
| **vLLM** | High-throughput OSS server; continuous batching + PagedAttention; OpenAI-compatible API |
| **TGI** (Text Generation Inference) | Hugging Face's production server |
| **Ollama** (§5) | Great for local/dev and light self-hosting; less for high-scale |
| **TensorRT-LLM / SGLang** | Further-optimized serving stacks |

These expose an HTTP endpoint (often **OpenAI-compatible**, so your client code barely changes — like the Gemini-via-OpenAI-SDK trick in §2).

---

## 3. The key technique: batching

A GPU is most efficient when it processes **many requests together**, not one at a time.

```
naive:       req1 → GPU → done, req2 → GPU → done   (GPU idle between, low utilization)
batched:     [req1, req2, req3, ...] → GPU together  (high utilization, high throughput)
```

> [!IMPORTANT]
> **Continuous batching is what makes self-serving viable**
> Static batching waits to fill a batch (adds latency) and wastes capacity when requests finish at different times. **Continuous (in-flight) batching** — vLLM's headline feature — dynamically adds/removes requests from the running batch as they arrive and complete, keeping the GPU saturated. This is the difference between serving a handful of users and serving thousands on the same hardware. **PagedAttention** complements it by managing the attention KV-cache memory efficiently (like OS paging), so more requests fit at once.

---

## 4. Throughput vs latency

The two serving metrics, often in tension:

| Metric | What it measures | Driven by |
|---|---|---|
| **Throughput** | Requests/tokens per second **across all users** | Batching, GPU count, model size |
| **Latency** | Time for **one** user's response | TTFT + per-token (§20), batch wait, load |

```
bigger batches → higher throughput (good for cost) but can raise individual latency
```

Tuning serving = balancing these for your workload (interactive chat → favor latency; bulk processing → favor throughput).

---

## 5. Scaling out

Beyond one GPU:
- **Horizontal scaling**: multiple model replicas behind a **load balancer**; autoscale on traffic.
- **Multi-GPU / sharding**: split a model too big for one GPU across several (tensor/pipeline parallelism).
- **Quantization (§21.05)**: serve a 4/8-bit model to fit bigger models on cheaper GPUs and raise throughput.
- **GPU autoscaling** is harder/slower than CPU (cold starts, GPU availability) — a real ops consideration (note 06).

---

## 6. A pragmatic decision guide

```
just shipping / low-mid volume        → managed API
need privacy / on-prem / fine-tuned   → self-host with vLLM/TGI
high steady volume, cost-sensitive    → self-host (per-GPU beats per-token at scale)
dev / local / prototyping             → Ollama (§5)
```

Many production apps use a **hybrid**: managed API as the default + a self-hosted model for specific high-volume or sensitive paths (and a gateway to route between them, note 03).

---

## 7. Main takeaways

- First fork: **managed API** (no infra, per-token) vs **self-hosted** (control/privacy, per-GPU, your ops).
- **Default to managed**; self-host for **privacy, high steady volume, or custom/fine-tuned models**.
- Self-hosting: **don't use raw `transformers`** — use an **inference server** (**vLLM**, TGI), often OpenAI-compatible.
- **Batching** is the core scaling technique; **continuous batching** (vLLM) keeps the GPU saturated; **PagedAttention** manages KV-cache memory.
- Two metrics: **throughput** (across users) vs **latency** (per user) — often in tension.
- Scale out via **replicas + load balancing**, multi-GPU sharding, and **quantization** (§21.05).
- Hybrid (managed + self-hosted) is common.

---

## 8. Things I still want to figure out

- At what volume does self-hosting beat per-token pricing?
- vLLM vs TGI for my workload (throughput/latency)?
- GPU autoscaling/cold-start strategies (note 06)?

---

## 9. Things to dig into

- **vLLM** (continuous batching, PagedAttention) + **TGI** docs.
- OpenAI-compatible self-hosted endpoints (drop-in client).
- Quantized serving (§21.05); Ollama for dev (§5).
- Next: [[03 - Reliability - Retries, Fallbacks, Rate Limits]].

---

## 10. Next up in this section

- [ ] [[03 - Reliability - Retries, Fallbacks, Rate Limits]] — surviving failures and provider limits.

---

## Related
- [[03 - Running Ollama in Docker]] — local serving (§5), scaled up here.
- [[05 - Quantization]] — serve bigger models cheaper.

## Sources
- [vLLM](https://docs.vllm.ai/) · [TGI](https://huggingface.co/docs/text-generation-inference/)
- [PagedAttention / vLLM paper](https://arxiv.org/abs/2309.06180)
