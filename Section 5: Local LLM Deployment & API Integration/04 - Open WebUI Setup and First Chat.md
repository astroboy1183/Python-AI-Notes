---
title: Open WebUI Setup and First Chat
date: 2026-05-28
source: "Section 5 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 5: Local LLM Deployment & API Integration"
tags:
  - open-webui
  - ollama
  - docker
  - chat-ui
  - local-llm
  - gemma
  - model-pulling
  - hands-on
related:
  - "[[03 - Running Ollama in Docker]]"
  - "[[01 - Why Run LLMs Locally]]"
---

# Open WebUI Setup and First Chat

> [!abstract] TL;DR
> **Open WebUI** is a ChatGPT-like web interface that talks to the Ollama server running in the background. Pull and run as another Docker container, **exposed on port 3000**, mapped internally to port 8080. Open WebUI **auto-detects** Ollama at `localhost:11434` and connects automatically. On first run: create an admin account, then **pull a model from the Models settings** — **`gemma:2b`** is a good starting choice (a ~2 GB Google model). After download, send the first prompt — the laptop's CPU spikes to **140-200%+** during inference, the unmistakable sign that local inference is genuinely happening. The chat experience mimics ChatGPT but everything runs **offline** on the host.

> [!info] Where this fits
> Fourth lecture of **Section 5: Local LLM Deployment & API Integration**. With Ollama running ([[03 - Running Ollama in Docker]]), this lecture adds the UI layer for manual testing. After this, [[05 - FastAPI Setup]] and [[06 - Connecting FastAPI to Ollama]] expose the model programmatically as a REST API.

---

## 1. What Open WebUI is

[Open WebUI](https://github.com/open-webui/open-webui) is an open-source, self-hosted web interface for Ollama (and other LLM backends). It looks and feels like ChatGPT:

- Chat-style conversations.
- Multiple models selectable from a dropdown.
- Persistent chat history.
- Model management UI (pull, delete, view stats).
- Admin panel for connections and settings.

Runs as a single Docker container — same pattern as Ollama. It's the UI layer that sits on top of Ollama.

---

## 2. Pulling the image

```bash
docker pull ghcr.io/open-webui/open-webui:main
```

Note: this image lives on **GitHub Container Registry** (`ghcr.io`), not Docker Hub. Pulling is the same — Docker handles multiple registries transparently.

Image size: **~1 GB**. Pulls in a few minutes, then needs a moment to extract.

---

## 3. Running the container

```bash
docker run -d -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

Breaking it down:

| Flag | Purpose |
|---|---|
| `-d` | Detached background mode |
| `-p 3000:8080` | Host port 3000 → container port 8080 (Open WebUI's internal port) |
| `--add-host=host.docker.internal:host-gateway` | Lets the container reach the host's `localhost:11434` (where Ollama is) |
| `-v open-webui:/app/backend/data` | Persist database, settings, chat history |
| `--name open-webui` | Friendly name |
| `--restart always` | Auto-restart on host reboot |
| `ghcr.io/open-webui/open-webui:main` | The image |

After this, Open WebUI is accessible at **http://localhost:3000**.

---

## 4. First load — patience required

Open WebUI runs database migrations and initialization on first launch. The browser may show errors or a blank page for **30-60 seconds** while the backend warms up — it's also fetching some files from the server during that window.

Tail the logs for visibility:

```bash
docker logs -f open-webui
```

Once `Application startup complete` appears in the logs, refresh `http://localhost:3000`.

---

## 5. Admin account creation

On first visit, Open WebUI requires creating an **admin account**:

| Field | Value |
|---|---|
| Full name | Jayanth |
| Email | (any — even a fake one works for local-only deployments) |
| Password | (something memorable) |

> [!warning] First account = admin
> The **first** account created on a fresh Open WebUI install gets **admin privileges**. Subsequent accounts are regular users (and admins can promote/demote from the admin panel).

For a personal localhost install with no exposed network, account security is more about habit than necessity — but using a real password is still a good idea.

---

## 6. Auto-detection of Ollama

Open WebUI automatically scans for a running Ollama server at the default port. If Ollama is running on `localhost:11434` (from [[03 - Running Ollama in Docker]]) and the container was started with `--add-host=host.docker.internal:host-gateway`, the connection works automatically.

To verify: **Admin Panel → Settings → Connections → Manage Ollama API Connections**. The URL `http://host.docker.internal:11434` should be listed and **green/connected** — confirmation that the WebUI has auto-found the Ollama server.

---

## 7. The empty model list — and why

After login, the chat UI works but no models are available. That's because **Ollama itself has no models downloaded yet** (the [[03 - Running Ollama in Docker]] step only installed Ollama, not any models).

To fix: **Admin Panel → Settings → Models → Pull a Model from Ollama.com**.

---

## 8. Pulling a model — the starting choice

Browsing [ollama.com/library](https://ollama.com/library), pick something small for laptop-friendly inference:

> **`gemma:2b`** — Google's 2-billion-parameter Gemma model, ~2 GB on disk.

Smaller models trade quality for speed and memory. For CPU-only inference (no GPU), 2B is a good starting point.

### How to pull from the UI

1. Open **Admin Panel → Settings → Models**.
2. In the "Pull a model from Ollama.com" field, type the model identifier: `gemma:2b`.
3. Click the download button.

The download progress shows live both in the UI and in the Ollama container's logs:

```bash
docker logs -f ollama
```

Will show lines like:
```
pulling manifest
pulling 8b2e35a8c1... 100%
verifying sha256 digest
writing manifest
success
```

### Pull from the CLI alternatively

The same effect via terminal:

```bash
docker exec -it ollama ollama pull gemma:2b
```

---

## 9. Other small models worth trying

The Ollama library has a huge selection. Some laptop-friendly picks:

| Model | Size | Notes |
|---|---|---|
| `gemma:2b` | ~2 GB | Google's small Gemma. Solid default starting point. |
| `gemma2:2b` | ~2 GB | Newer Gemma 2 small. |
| `phi3:mini` | ~2.3 GB | Microsoft's small + capable. |
| `tinyllama` | ~640 MB | Smallest viable LLM. |
| `llama3.2:1b` / `llama3.2:3b` | 1–2 GB | Meta's small Llama 3.2. |
| `qwen2.5:1.5b` | ~1 GB | Alibaba's small Qwen. |
| `mistral:7b` | ~4 GB | Larger but still laptop-feasible. |

For larger models (7B-13B), expect inference times of 10-60 seconds per response on CPU only.

---

## 10. The first chat

After the model finishes downloading:

1. Click **New Chat** in Open WebUI.
2. Select `gemma:2b` from the model dropdown (top of the chat).
3. Type a message: *"Hey there, who are you?"*.

Hit enter.

### What happens behind the scenes
- The browser sends the message to Open WebUI on port 3000.
- Open WebUI forwards it to Ollama on port 11434.
- Ollama loads `gemma:2b` into memory (if not already loaded).
- Ollama runs **inference** — the autoregressive token-prediction loop from [[03 - The Transformer - Predicting the Next Token]] — on the host CPU.
- Tokens stream back to Open WebUI, which streams them to the browser.

### Observable result
The reply appears word-by-word (streaming). The CPU spikes dramatically during generation — jumping from idle to 140%, 200%, even 295% on a multi-core machine, then dropping straight back to zero once the reply finishes.

CPU usage going from 0% → 140-200%+ during a reply is the unmistakable signal that **inference is happening locally**, not in the cloud.

> [!note] CPU > 100%?
> On multi-core systems, top reports the **sum across cores**. A 4-core machine showing 200% means roughly 2 cores fully busy. 295% means ~3 cores busy. Normal for LLM inference.

---

## 11. Latency expectations

Rough numbers to set expectations:

| Setup | First-token latency | Tokens / second |
|---|---|---|
| `gemma:2b` on a 2024 laptop CPU | 0.5–2 s | 10–30 t/s |
| `gemma:2b` on a modest GPU | 0.2 s | 50–150 t/s |
| `llama3:8b` on CPU | 2–5 s | 3–8 t/s |
| `llama3:8b` on RTX 4090 | 0.2 s | 80–200 t/s |
| Hosted GPT-4o (for reference) | 0.5–1 s | 50–100 t/s |

Even on CPU, a 2B model is usable for chat. Frontier-class quality requires bigger models and/or GPU acceleration.

---

## 12. The state after this lecture

| Component | Status |
|---|---|
| Docker Desktop | ✅ |
| Ollama container | ✅ Running on `localhost:11434` |
| Open WebUI container | ✅ Running on `localhost:3000` |
| Auto-connection Ollama ↔ WebUI | ✅ |
| Admin account in WebUI | ✅ |
| `gemma:2b` model | ✅ Downloaded and ready |
| First chat | ✅ Sent and answered |

Everything is in place. The next lectures expose this same model to **application code** instead of just a browser UI.

---

## 13. Common gotchas

> [!warning] Things to watch for

| Symptom | Likely cause | Fix |
|---|---|---|
| `localhost:3000` shows "connection refused" | Container still warming up | Wait 30-60s, check `docker logs -f open-webui` |
| Open WebUI can't see Ollama | Missing `--add-host=host.docker.internal:host-gateway` | Recreate container with that flag |
| Model pull fails | Network / Ollama service issue | Check Ollama logs; retry pull |
| Reply is **gibberish** | Wrong model format / corrupt download | Re-pull the model |
| First reply is very slow | Model loading into memory | Subsequent replies will be fast |
| CPU pegged at 100% one core only | Single-threaded inference (rare) | Switch to a runtime that uses all cores |
| Admin login forgotten | Database persists | Delete the volume to reset: `docker volume rm open-webui` (loses chat history) |

---

## 14. Main takeaways

- **Open WebUI** = ChatGPT-like web interface for Ollama, runs in another Docker container.
- Default port mapping: **3000 (host) → 8080 (container)**.
- Auto-detects Ollama at `localhost:11434` via `--add-host=host.docker.internal:host-gateway`.
- First load: **patience required** (database migrations).
- **First account = admin**. Use the admin panel to manage models and settings.
- **Models must be pulled** explicitly — empty by default.
- **`gemma:2b`** (~2 GB) is a solid first model. Other good laptop picks: `phi3:mini`, `llama3.2:3b`, `qwen2.5:1.5b`, `tinyllama`.
- During inference, **CPU usage spikes massively** (140-200%+) — the visible proof of local inference.
- After this setup, the same model is reachable via Ollama's REST API on `localhost:11434` for programmatic access.

---

## 15. Things I still want to figure out

- How does Open WebUI handle multiple models — can it switch mid-conversation?
- What's the chat history storage format and where exactly is it persisted (in the `open-webui` volume)?
- How do **system prompts** work in Open WebUI? Per-conversation? Per-model?
- Can Open WebUI use **OpenAI / Gemini APIs** alongside Ollama (multi-backend chat)?
- How are **user permissions** managed (multi-user setups)?
- What's the **best model size** for my specific hardware (laptop, RAM, CPU/GPU)?
- How does **streaming** work in Open WebUI's UI?

---

## 16. Things to dig into

- **Open WebUI docs**: https://docs.openwebui.com
- **Ollama model library**: https://ollama.com/library — browse all available models with sizes and capabilities.
- **Quantization guide**: explore Q4 vs Q5 vs Q8 quantizations — same model, different memory footprints.
- **Hands-on**: pull `phi3:mini`, `llama3.2:3b`, and `gemma:2b`. Compare their replies to the same prompt. Quality + speed trade-offs become visible.
- **Open WebUI advanced features**: RAG (upload docs), web search, image generation integration.

---

## 17. Next up in this section

The Open WebUI is the convenient way to **chat manually** with the local model. Next, expose the same model to application code:

- [ ] [[05 - FastAPI Setup]] — install FastAPI and build a basic Python web server.
- [ ] [[06 - Connecting FastAPI to Ollama]] — wire FastAPI to Ollama → REST API on top of the local LLM.

---

## Related
- [[03 - Running Ollama in Docker]] — the prerequisite.
- [[02 - Docker Deep Dive]] — the container fundamentals.
- [[01 - Why Run LLMs Locally]] — the section's motivation.

## Sources
- [Open WebUI docs](https://docs.openwebui.com)
- [Open WebUI on GitHub](https://github.com/open-webui/open-webui)
- [Ollama model library](https://ollama.com/library)
