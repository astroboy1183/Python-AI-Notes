---
title: Why Run LLMs Locally
date: 2026-05-28
source: "Section 5 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 5: Local LLM Deployment & API Integration"
tags:
  - llm
  - local-llm
  - open-source
  - proprietary
  - ollama
  - docker
  - deepseek
  - qwen
  - gemma
  - llama
  - mistral
  - privacy
  - data-sovereignty
  - section-overview
related:
  - "[[01 - What is an LLM]]"
  - "[[01 - Setting up OpenAI Account]]"
  - "[[04 - Using Gemini through OpenAI SDK]]"
---

# Why Run LLMs Locally

> [!NOTE]
> **TL;DR**
> Sections 2 and 3 used **hosted, proprietary APIs** — OpenAI's GPT and Google's Gemini. Those models are closed source, run on someone else's servers, and **charge per token**. Section 5 introduces an alternative: **open-source LLMs** (DeepSeek, Qwen, Gemma, Llama, Mistral) running **locally** on your own hardware. Trade-off: needs **good CPU/GPU**, but data **stays on your machine**, and inference is **free** after the hardware investment. The vehicle: **Ollama** running in **Docker**. Combined with [[04 - Using Gemini through OpenAI SDK|the OpenAI-compat layer]], local models become drop-in replacements for hosted APIs — exactly what enterprises use for privacy-sensitive workloads.

> [!NOTE]
> **Where this fits**
> First lecture of **Section 5: Local LLM Deployment & API Integration**. The section bridges from "cloud APIs" (Sections 2–4) to "your own server." The setup learned here will also matter for: (a) enterprise data-privacy projects, (b) edge / on-device deployments, (c) keeping experimentation costs at zero.

---

## 1. The two worlds of LLMs

| | **Proprietary / Hosted** | **Open Source / Self-Hosted** |
|---|---|---|
| **Examples** | GPT-4o, GPT-4o-mini, GPT-o3, Gemini 2.5, Claude 4 | DeepSeek, Qwen 2.5, Gemma 3, Llama 3.1, Mistral |
| **Source code** | ❌ Hidden | ✅ Public |
| **Training data** | ❌ Hidden | ⚠️ Often partially documented |
| **Model weights** | ❌ Not downloadable | ✅ Downloadable |
| **Where it runs** | Provider's servers | Your machine / server |
| **Cost** | Per-token API charges | Free after hardware investment |
| **Data residency** | Sent to provider | Stays local |
| **Hardware needed** | Just internet | CPU, ideally GPU, lots of RAM |
| **Setup difficulty** | Easy (API key) | Harder (Docker, models, ports) |
| **Update cycle** | Provider pushes updates | You manage versions |
| **Best for** | Speed of getting started, top-tier quality | Privacy, cost control, customization |

> [!NOTE]
> **The core distinction**
> Models like ChatGPT, GPT-4o, GPT-4o mini, and Gemini are closed-source proprietary models — owned by their respective companies and not publicly available. Using them means going through their paid APIs. In contrast, a huge number of open-source models exist that can be downloaded and run on a personal machine, offline and for free.

---

## 2. Why someone would want to run locally

The fair question — *"why run a model locally at all?"* — has its strongest answer in the **enterprise privacy use case**.

### Reason 1 — Data privacy / sovereignty

The biggest one. Large companies dealing with:
- Customer PII (banking, healthcare, government).
- Internal IP (proprietary code, R&D documents).
- Regulated data (HIPAA, GDPR, financial filings).

…**can't legally or contractually send that data to OpenAI or Google**. Running an open-source model locally keeps data inside the company's network.

> [!NOTE]
> **The enterprise scenario**
> A large company that wants to leverage AI but cannot share its data with a third-party API like Gemini or OpenAI can download one of the open-source models and run it on its own hardware. The hardware cost is real, but the data stays inside the company's environment.

### Reason 2 — Cost control
- No per-token charges.
- Predictable monthly cost (just the hardware / electricity).
- At very high volume, self-hosting can become **dramatically** cheaper than API calls.

### Reason 3 — No vendor lock-in
- Provider changes pricing → you're stuck.
- Provider deprecates a model → your app breaks.
- Provider has an outage → you go down.
- Self-hosted = you control the entire stack.

### Reason 4 — Customization
- Fine-tune the model on domain-specific data.
- Modify behavior with custom prompts / tools / agents at the inference layer.
- No content-policy restrictions imposed by the provider.

### Reason 5 — Offline use cases
- Air-gapped networks (defense, healthcare, classified environments).
- Edge devices (robotics, AR/VR, vehicles).
- Remote / low-connectivity scenarios.

---

## 3. The cost — hardware

> [!WARNING]
> **Local LLMs are **not** cheap-on-machine**
> Running a model eats a lot of CPU and GPU — a decent amount of hardware is required.

Rough hardware tiers:

| Tier | Models that fit | Hardware |
|---|---|---|
| **Light** | 1B–3B parameter models (Gemma 2B, TinyLlama) | Modern CPU, 8–16 GB RAM |
| **Mid** | 7B–13B (Llama 3 8B, Mistral 7B, Gemma 7B) | CPU + 16–32 GB RAM; or modest GPU (8 GB VRAM) |
| **Heavy** | 30B–70B (Llama 3 70B, Qwen 72B) | High-end GPU (24+ GB VRAM, e.g., RTX 4090 / A100) |
| **Frontier** | 405B+ (Llama 3.1 405B, DeepSeek V3) | Multi-GPU server, $$$$ |

For learning, **light/mid tier** is plenty. `gemma:2b` (~2 GB on disk) runs comfortably on a regular laptop.

> [!TIP]
> **Quantization makes things smaller**
> Modern local runtimes (Ollama, llama.cpp) ship **quantized** versions of models — 4-bit or 8-bit representations that drastically reduce memory needs at a small quality cost. A "70B model in 4-bit" might fit on a single 24 GB GPU.

---

## 4. The major open-source LLM families

A quick map of the ecosystem:

| Family | Maker | Sizes | Notes |
|---|---|---|---|
| **Llama 3 / 3.1** | Meta | 8B, 70B, 405B | The dominant open-source family |
| **Mistral / Mixtral** | Mistral AI | 7B / 8×7B MoE / Large | Efficient, multilingual |
| **Gemma 2 / 3** | Google | 2B, 7B, 9B | Smaller, friendly for laptops |
| **Qwen 2 / 2.5** | Alibaba | 0.5B to 72B | Strong multilingual / code |
| **DeepSeek V3 / R1** | DeepSeek (China) | 7B to 671B (MoE) | Reasoning-strong, very competitive |
| **Phi 3 / 4** | Microsoft | 3.8B, 14B | Small but capable |
| **Command R / R+** | Cohere | 35B / 104B | Enterprise / RAG-optimized |
| **Yi 1.5** | 01.AI | 6B, 9B, 34B | Multilingual |

The list keeps growing. Most release on **Hugging Face**, and **Ollama** packages them for easy local use.

DeepSeek, Qwen, Gemma 3, Qwen 2.5 — all open-source, all downloadable, all runnable offline for free. The list goes on and keeps expanding.

---

## 5. The toolchain this section will install

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   Application code                                      │
│   (Python — OpenAI SDK or Ollama SDK or FastAPI)        │
│                                                         │
└───────────────────────────┬─────────────────────────────┘
                            │ HTTP
                            ▼
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   Ollama server                                         │
│   (runs in a Docker container, port 11434)              │
│                                                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │  Downloaded models:                             │   │
│   │    • gemma:2b      (~2 GB)                      │   │
│   │    • llama3:8b     (~5 GB)                      │   │
│   │    • mistral:7b    (~4 GB)                      │   │
│   │    • ...                                        │   │
│   └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
                            ▲
                            │
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   Open WebUI                                            │
│   (chat UI, runs in Docker, port 3000)                  │
│   — for quick manual testing                            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

Components to install:

1. **Docker Desktop** — container runtime, the foundation for everything else here.
2. **Ollama** (in Docker) — the local LLM server.
3. **Open WebUI** (in Docker) — graphical chat interface to test models.
4. **FastAPI** — wrap the local model as a REST API for downstream apps.

Each is one note in the rest of this section.

---

## 6. Why Docker (preview)

**Docker over native installs** of Ollama. Three reasons:

| Reason | Detail |
|---|---|
| **Platform-agnostic** | Same `docker run` command on macOS, Linux, Windows. |
| **No system bloat** | Tools live in containers, not scattered across the OS. |
| **Production-relevant** | Knowing Docker = knowing how to deploy LLMs on servers later. |

Full treatment in [[02 - Docker Deep Dive]].

---

## 7. Connecting back to the rest of the course

This section's payoff isn't just "now I can run LLMs offline." It's the **architectural insight**:

> [!TIP]
> **The big idea**
> Local Ollama, hosted OpenAI, hosted Gemini — they all expose **OpenAI-compatible chat endpoints**. The `base_url` trick from [[04 - Using Gemini through OpenAI SDK]] means the **same application code** can target any of them. Switching from `gpt-4o` (cloud, paid) to `gemma:2b` (local, free) is a config change.

The notes in this section build toward an **API layer** ([[06 - Connecting FastAPI to Ollama]]) that exposes local models the same way OpenAI exposes hosted ones — making local LLMs **production-ready**.

---

## 8. When to use local vs hosted (decision matrix)

| Scenario | Pick |
|---|---|
| Personal project, fast iteration | Hosted (OpenAI / Gemini) |
| Sensitive enterprise data | Local |
| Solo learner, $5 OK to spend | Hosted (lower friction) |
| Solo learner, $0 budget | Local (or Gemini free tier) |
| High-volume API calls | Local (cost) or hybrid |
| Need cutting-edge capability | Hosted (frontier models always better for now) |
| Need offline / air-gapped | Local |
| Edge deployment | Local |
| Need fine-tuning | Local (full control) or hosted (managed) |
| Need fastest inference | Hosted (better hardware on tap) |
| Need lowest latency | Local (no network round-trip) — but only if hardware is fast |

Hybrid setups are common: hosted for high-quality fallback, local for the bulk of routine calls.

---

## 9. Main takeaways

- LLM ecosystem splits into **proprietary/hosted** vs **open-source/self-hosted**.
- Hosted = easy + expensive. Self-hosted = harder + free (modulo hardware).
- **Primary reasons** to run locally: **data privacy**, cost control, no vendor lock-in, customization, offline use.
- **Hardware matters** — light models on laptops, heavy models need GPUs.
- Major open-source families: **Llama, Mistral, Gemma, Qwen, DeepSeek, Phi, Command R, Yi**.
- This section's toolchain: **Docker + Ollama + Open WebUI + FastAPI**.
- The architectural payoff: local models speak the same **OpenAI-compatible** language → swappable with cloud APIs.

---

## 10. Things I still want to figure out

- For my specific laptop, what's the largest model that runs at usable speed?
- Are there **rented GPU** options for "between laptop and server" (e.g., RunPod, vast.ai)?
- What's the difference between Ollama, **vLLM**, **llama.cpp** as serving runtimes?
- For production, is **Ollama** suitable, or should something heavier (vLLM) be used?
- How do **quantization levels** (Q4, Q5, Q8) trade off quality vs memory?
- What's the workflow for **fine-tuning** a local model?
- Can I run a local model in **parallel** with hosted APIs for cost optimization?

---

## 11. Things to dig into

- **Ollama**: https://ollama.com — model library + download instructions.
- **Hugging Face Open LLM Leaderboard**: ranks open models on benchmarks.
- **llama.cpp**: https://github.com/ggerganov/llama.cpp — the underlying inference engine many tools (including Ollama) rely on.
- **vLLM**: https://github.com/vllm-project/vllm — production-grade LLM server.
- **LocalLLaMA subreddit**: r/LocalLLaMA — practical experimentation community.

---

## 12. Next up in this section

- [ ] [[02 - Docker Deep Dive]] — install Docker, basic container commands.
- [ ] [[03 - Running Ollama in Docker]] — get the Ollama server running.
- [ ] [[04 - Open WebUI Setup and First Chat]] — chat with a local model.
- [ ] [[05 - FastAPI Setup]] — wrap the model as an API.
- [ ] [[06 - Connecting FastAPI to Ollama]] — expose local models to applications.

---

## Related
- [[01 - What is an LLM]] — model fundamentals.
- [[01 - Setting up OpenAI Account]] — the cloud counterpart.
- [[04 - Using Gemini through OpenAI SDK]] — the `base_url` trick that also bridges local LLMs.

## Sources
- [Ollama model library](https://ollama.com)
- [Hugging Face Open LLM Leaderboard](https://huggingface.co/spaces/open-llm-leaderboard/open_llm_leaderboard)
- [llama.cpp](https://github.com/ggerganov/llama.cpp)
- [vLLM](https://github.com/vllm-project/vllm)
