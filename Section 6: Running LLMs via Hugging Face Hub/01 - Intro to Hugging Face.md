---
title: Intro to Hugging Face
date: 2026-05-28
source: "Section 6 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 6: Running LLMs via Hugging Face Hub"
tags:
  - hugging-face
  - hf
  - models
  - spaces
  - datasets
  - open-source
  - llm-ecosystem
  - section-overview
  - foundations
related:
  - "[[01 - Why Run LLMs Locally]]"
  - "[[01 - What is an LLM]]"
  - "[[04 - Open WebUI Setup and First Chat]]"
---

# Intro to Hugging Face

> [!abstract] TL;DR
> **Hugging Face = GitHub for LLMs.** A central platform where the AI community **publishes, hosts, demos, and shares** open-source models, datasets, and interactive apps. Three core areas: **Models** (downloadable weights for Llama, Gemma, Mistral, Qwen, Stable Diffusion, etc.), **Spaces** (hosted interactive demos backed by free or paid GPUs — try a model in the browser without installing anything), and **Datasets** (training/evaluation data anyone can use). The **`transformers`** Python library is the standard way to download and run any model from the Hub. Ollama (Section 5) is essentially a curated, easier-to-install layer **on top of** the Hugging Face ecosystem. This section dives into using HF directly for more control.

> [!info] Where this fits
> First note of **Section 6: Running LLMs via Hugging Face Hub**. Section 5 used Ollama for the laptop-friendly path; Section 6 goes one layer deeper to the **broader open-source ecosystem** where every modern open model lives.

---

## 1. What Hugging Face is

> **"The AI community for building future"** — their tagline.

The role HF plays in the open-source AI world:

```
              ┌────────────────────────────────────────┐
              │           Hugging Face Hub             │
              │                                        │
              │   ┌──────────┐  ┌──────────┐  ┌────────┐│
              │   │  Models  │  │  Spaces  │  │ Datasets││
              │   └──────────┘  └──────────┘  └────────┘│
              │                                        │
              │   The central registry/distribution    │
              │   for open-source AI artifacts         │
              └────────────────────────────────────────┘
                              ▲
                              │  push / pull / browse
              ┌───────────────┼──────────────────┐
              │               │                  │
              ▼               ▼                  ▼
       Model authors    Researchers         End users
       (Meta, Google,   (universities,      (developers,
        Anthropic,      labs, hobbyists)    enterprises)
        Mistral, ...)
```

> [!tip] The one-line mental model
> Hugging Face is basically the **GitHub of LLM models**. On GitHub we push source code (Python, TypeScript, etc.); on Hugging Face we push and pull **model weights** the same way.

---

## 2. Why "GitHub for LLMs"?

GitHub solved the problem of distributing **source code**. Hugging Face solves the same problem for **model artifacts**:

| GitHub | Hugging Face |
|---|---|
| Source code | Model weights |
| Repositories | Model repositories |
| Pull requests | Discussions + Pull Requests on models |
| README.md | Model card (`README.md` + metadata) |
| Issues | Community tab |
| Forks | "Use this model" workflow |
| GitHub Actions | Spaces (interactive demos) |
| `git clone` | `huggingface-cli download` / `transformers` library |

So when researchers at Meta release Llama 3, or DeepSeek releases R1, or Mistral releases a new model — they publish it as a **repository on Hugging Face**. From there, anyone can:

- **Download** the weights and run locally.
- **Try** the model in the browser via Spaces.
- **Fine-tune** the model on custom data.
- **Push** their fine-tuned version back to the Hub.

> [!note] One reason HF exists at all
> GitHub doesn't handle multi-GB binary files well (model weights can be 1–500+ GB). HF was built around **Git LFS (Large File Storage)** specifically for this. Trying to host a 405B-parameter model on regular GitHub would be technically impossible.

---

## 3. The three core sections

### Models

The biggest section. As of mid-2020s, over **1 million** model repositories.

What's there:
- **Frontier open-source LLMs**: Llama 3.1, Gemma 3, Qwen 2.5, DeepSeek V3 / R1, Phi 4.
- **Specialized models**: code (CodeLlama, StarCoder), embeddings (BGE, GTE), reranking, multilingual translation.
- **Multimodal**: vision-language (LLaVA, Pixtral), image generation (Stable Diffusion, Flux), TTS / STT.
- **Older / smaller**: BERT, GPT-2, T5, distilled variants, fine-tunes.
- **Community fine-tunes**: thousands of variations of every popular base model.

Filter by:
- Task (text generation, classification, etc.).
- Library (`transformers`, `diffusers`, etc.).
- License (open, commercial-friendly, etc.).
- Size, language, dataset, ...

### Spaces

**Spaces = interactive demos**. Each Space is a small app (built with Gradio, Streamlit, or Docker) that lets anyone try a model **without installing anything**, using HF's hosted hardware (often a free GPU).

Quick example: open the **Flux** image-to-image Space, upload an image, type "convert the paper to orange" → the Space transforms the image on HF's GPU instance, no local install required.

| Spaces use case | Example |
|---|---|
| Try a model quickly | "Does Llama 3 understand my prompt?" |
| Compare two models | Run both on the same input |
| Public-facing app | Share with non-technical users |
| Demo for a paper | Reviewers can interact without setup |
| Hackathon / prototype | Spin up an app in minutes |

> [!tip] Why this is so useful
> Spaces let me try a model right there on HF's hosted GPUs — perfect for **testing, benchmarking, and evaluating** new models before committing to a local download or integration.

> [!example] What's under the hood
> A Space is just a Git repository containing a small app (typically `app.py` for Gradio). HF runs it in a container with hardware spec the author selects:
> - **CPU basic** (free): for lightweight Spaces.
> - **CPU upgrade** (paid).
> - **T4 small / medium** (paid GPU).
> - **A10G / A100** (paid, serious GPU).
> Free GPU minutes are limited per user; popular Spaces can get rate-limited.

### Datasets

The **training-data** counterpart to Models. Both raw and curated datasets:

- Common Crawl scrapes.
- Code datasets (The Stack, GitHub Code).
- Instruction-tuning datasets (Alpaca, OpenAssistant).
- Multimodal datasets (LAION).
- Domain-specific (legal, medical, scientific).

Used for **fine-tuning** custom models on top of a base model.

---

## 4. The `transformers` library — the entry point

The Python library that ties everything together:

```bash
pip install transformers
```

What it does:
- Downloads any model from the Hub.
- Provides a uniform API across model architectures (Llama, Gemma, Mistral, GPT-2, BERT — same `pipeline()` interface).
- Handles tokenization, generation, fine-tuning.
- Auto-detects PyTorch / TensorFlow / JAX as the backend.

This is the **standard** Python tool for direct model use, and what [[05 - Using the Transformers Package]] covers in detail.

---

## 5. How HF relates to Ollama (Section 5)

Quick comparison:

| | Ollama | Hugging Face (direct) |
|---|---|---|
| Curated model catalog | ✅ ~100 models, pre-packaged | ❌ Raw — 1M+ repos |
| Easy install | ✅ One `docker run` command | ⚠️ More setup |
| Quantization handled | ✅ Pre-quantized GGUF | ⚠️ Manual |
| Multi-model serving | ✅ Built-in | ⚠️ Build it yourself |
| API server | ✅ OpenAI-compatible | ⚠️ Need to set up |
| Fine-tuning | ❌ Not really | ✅ Full support |
| Custom architectures | ❌ Limited | ✅ Any model |
| Bleeding-edge models | ⚠️ Lags by days/weeks | ✅ Day-zero access |
| Inference speed | ⚠️ Depends on backend | ✅ Faster (Transformers, vLLM) |
| Production deployment | ⚠️ Possible but Ollama isn't optimized | ✅ Designed for it |

> [!tip] Mental model
> Ollama = curated, easy, batteries-included. Hugging Face = raw, powerful, full-control. Use Ollama for laptop chat; use HF directly for fine-tuning, custom workflows, or any model not in Ollama's catalog.

Even Ollama gets its model weights from Hugging Face under the hood — HF is the underlying source of truth for the open-source model ecosystem.

---

## 6. The Flux demo — a concrete walkthrough

A quick concrete walkthrough of a Space running **Flux** (an image-to-image model):

| Step | Action |
|---|---|
| 1 | Open the Flux model's Space page on HF. |
| 2 | Space spins up on a hosted GPU (managed by HF). |
| 3 | Upload an image (e.g. a "back-of-the-envelope estimations" paper). |
| 4 | Type a transformation prompt: *"convert the paper to orange"*. |
| 5 | Click Run → HF runs inference on its GPU. |
| 6 | After ~10–30 seconds → modified image appears (paper now orange-tinted). |

The point: **Spaces let anyone use any open model with zero install**. Hugely useful for evaluating models before committing to downloading or integrating them.

---

## 7. Why HF matters for the agentic-AI journey

Even when building on hosted APIs (OpenAI, Gemini), HF is relevant:

| Use case | How HF fits |
|---|---|
| **Embeddings** (RAG, semantic search) | Best open embedding models (BGE, GTE) are on HF |
| **Reranking** | Top open rerankers (BGE-reranker, Cohere R) on HF |
| **Tokenizers** | Inspect / compare any tokenizer |
| **Datasets** | Find evaluation / fine-tuning data |
| **Fine-tuning** | The whole pipeline lives on HF |
| **Self-hosted backup** | When proprietary APIs are too expensive / blocked |
| **Edge / on-device** | Smaller models for mobile / IoT |

In short: any serious agentic-AI work will eventually touch HF, even if just for an embedding model.

---

## 8. The rest of this section

| Note | Topic |
|---|---|
| 02 | [[02 - Setting up Hugging Face Account]] — sign up flow |
| 03 | [[03 - Accessing Gated Models]] — Gemma 3 needs license acceptance |
| 04 | [[04 - Hugging Face CLI Setup and Login]] — `huggingface-cli` + access tokens |
| 05 | [[05 - Using the Transformers Package]] — actually run a model in Python |

By the end: a Gemma 3 model running locally via the `transformers` Python library — exactly what enterprise data-pipeline code looks like.

---

## 9. Main takeaways

- **Hugging Face = GitHub for LLMs**: registry, distribution, and demos for open-source AI.
- Three core sections: **Models** (weights), **Spaces** (live demos with hosted GPUs), **Datasets** (training data).
- The `transformers` Python library is the standard entry point.
- HF and Ollama are complementary: Ollama curates HF models for easy laptop use.
- HF matters even for hosted-API workflows (embeddings, datasets, fine-tuning).
- Spaces are a brilliant way to **evaluate** models without installing.
- Anyone can publish models, fine-tunes, datasets, and Spaces — the community drives the ecosystem.

---

## 10. Things I still want to figure out

- How does HF differ from **GitHub Models** (newer, competing offering)?
- What's the best **embedding model** on HF for English text right now?
- How does **inference cost** on HF Spaces compare to running locally / on AWS?
- What's the model selection process for **production** — license, size, eval scores, popularity?
- How do **PRs against models** work — can the community improve a model after release?
- What's the difference between **`transformers`** and **`diffusers`** libraries on HF?
- How does **HF Inference Endpoints** (paid API for any HF model) compare to OpenAI's API?

---

## 11. Things to dig into

- **Hugging Face Hub**: https://huggingface.co
- **Open LLM Leaderboard**: https://huggingface.co/spaces/HuggingFaceH4/open_llm_leaderboard — benchmarks the best open models.
- **Spaces gallery**: https://huggingface.co/spaces — browse interesting demos.
- **Embedding model leaderboard**: https://huggingface.co/spaces/mteb/leaderboard — MTEB benchmark for embeddings.
- **Hands-on**: try 3 different Spaces in 5 minutes — vision-language, image generation, audio. The variety is striking.

---

## 12. Next up in this section

- [ ] [[02 - Setting up Hugging Face Account]] — sign up so models can be downloaded.

---

## Related
- [[01 - Why Run LLMs Locally]] — Section 5's framing for why this matters.
- [[01 - What is an LLM]] — what these models even are.
- [[04 - Open WebUI Setup and First Chat]] — Ollama's curated approach; HF is the raw layer underneath.

## Sources
- **Hugging Face Hub**: https://huggingface.co
- **Open LLM Leaderboard**: https://huggingface.co/spaces/HuggingFaceH4/open_llm_leaderboard
- **MTEB embeddings leaderboard**: https://huggingface.co/spaces/mteb/leaderboard
- **`transformers` docs**: https://huggingface.co/docs/transformers
