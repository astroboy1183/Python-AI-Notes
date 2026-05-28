---
title: Running Ollama in Docker
date: 2026-05-28
source: "Section 5 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 5: Local LLM Deployment & API Integration"
tags:
  - ollama
  - docker
  - local-llm
  - port-mapping
  - volume-mount
  - infrastructure
  - hands-on
related:
  - "[[01 - Why Run LLMs Locally]]"
  - "[[02 - Docker Deep Dive]]"
  - "[[04 - Open WebUI Setup and First Chat]]"
---

# Running Ollama in Docker

> [!abstract] TL;DR
> Pull the official `ollama/ollama` image from Docker Hub and run it as a detached container with **port 11434 mapped** (where the Ollama API listens) and a **named volume** for model storage (so downloaded models survive container restarts). The full command: `docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama`. **Common gotcha**: running without `-p 11434:11434` leaves the container "up" but unreachable from the host. Once running, Ollama exposes a REST API on `localhost:11434` ready for the Open WebUI ([[04 - Open WebUI Setup and First Chat]]) and the Python SDK ([[06 - Connecting FastAPI to Ollama]]) to connect.

> [!info] Where this fits
> Third lecture of **Section 5: Local LLM Deployment & API Integration**. The actual installation step for the local-LLM stack. By the end, an Ollama server is running on `localhost:11434` — ready but with no models downloaded yet. The next lecture sets up the chat UI and pulls the first model.

---

## 1. The official Ollama image

Ollama publishes a Docker image at `ollama/ollama` on Docker Hub. It's the recommended way to run Ollama on any host without polluting the OS with native binaries.

Documentation source: search **"Ollama Docker"** → look for the [hub.docker.com](https://hub.docker.com/r/ollama/ollama) listing or the [Ollama blog post](https://ollama.com/blog/ollama-is-now-available-as-an-official-docker-image).

Image size: **~2 GB**. The first `docker pull` takes a few minutes.

A quick search for "Ollama Docker" surfaces the relevant pointers — the official announcement *"Ollama is now available as an official Docker image"* and the `hub.docker.com/r/ollama/ollama` listing confirming the image is published and supported.

---

## 2. The recommended run command

From the Ollama Docker Hub docs:

```bash
docker run -d \
  -v ollama:/root/.ollama \
  -p 11434:11434 \
  --name ollama \
  ollama/ollama
```

Breaking it down:

| Flag | What it does |
|---|---|
| `-d` | Detached / background mode (the container runs without blocking the terminal) |
| `-v ollama:/root/.ollama` | Named volume `ollama` mounted at `/root/.ollama` inside the container — where Ollama stores models and config |
| `-p 11434:11434` | Map host port 11434 to container port 11434 (the Ollama API) |
| `--name ollama` | Give the container a friendly name (so it's easy to refer to as `ollama` instead of a hash) |
| `ollama/ollama` | The image to run |

If the image isn't already pulled, `docker run` auto-pulls it first. Subsequent runs use the cached image.

---

## 3. The "container up but unreachable" gotcha

A naive first attempt looks like:

```bash
docker run ollama/ollama
```

**No `-p 11434:11434`.** The container starts, Ollama runs inside it, but **the API is not reachable from the host**. Trying to connect to `localhost:11434` returns "connection refused."

The fix: **always include the `-p` flag**. The official command from the Docker Hub docs already has it.

> [!warning] The lesson
> A container being "up" doesn't mean its services are reachable. **Port mapping is required for anything outside the container to talk to it.**

---

## 4. What Ollama exposes

Once running, Ollama serves an HTTP API on **port 11434**. The API is OpenAI-compatible plus has Ollama-specific endpoints.

Quick smoke test from the host:

```bash
curl http://localhost:11434/
```

Should return something like:
```
Ollama is running
```

Or list available models (none yet at this point):
```bash
curl http://localhost:11434/api/tags
```

Returns JSON.

---

## 5. The detached container in Docker Desktop

After running with `-d`, the container disappears from the terminal but is visible in:

- **Docker Desktop** → Containers tab → "ollama" entry.
- CLI: `docker container ps` → lists the running container.

To inspect logs:
```bash
docker logs -f ollama
```

To stop:
```bash
docker stop ollama
```

To restart:
```bash
docker start ollama
```

To remove (after stopping):
```bash
docker rm ollama
```

To recreate (if the run command needs adjusting):
```bash
docker rm -f ollama          # force remove (even if running)
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```

> [!note]
> Because the named volume `ollama` persists across container removal, **downloaded models survive** even if the container is destroyed and recreated.

---

## 6. The port mapping explained

```
Host machine                          Docker container
─────────────                         ─────────────────
                                      
    Application                            Ollama
    talks to                               listens
    localhost:11434  ──── -p ────────►  port 11434
                          flag
```

Without `-p`, the right side exists but the bridge from the left side is missing.

---

## 7. The volume mapping explained

```
Host machine                          Docker container
─────────────                         ─────────────────
                                      
    Docker-managed                          Ollama
    named volume:    ──── -v ────────►  /root/.ollama
    "ollama"              flag
    
    (persists                           (where models
     across restarts)                    live)
```

Without `-v`, every recreation of the container = re-download every model. With `-v`, models stay on the host's disk (inside Docker's volume area).

To inspect named volumes:
```bash
docker volume ls
docker volume inspect ollama
```

---

## 8. Running with GPU support

For NVIDIA GPUs, Ollama's Docker image can use the GPU for inference (much faster):

```bash
docker run -d --gpus all \
  -v ollama:/root/.ollama \
  -p 11434:11434 \
  --name ollama \
  ollama/ollama
```

The `--gpus all` flag passes the host's GPUs into the container. Requires the [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) installed on the host.

> [!warning] Apple Silicon (M1/M2/M3 Macs)
> Docker Desktop on Apple Silicon **does not expose the GPU** to Linux containers. So Ollama in Docker on a Mac runs on CPU only. To use the Apple Neural Engine, install Ollama natively (`brew install ollama` or the Mac installer) instead of via Docker.
>
> Trade-off: native install gives GPU acceleration on Mac but loses cross-platform parity.

---

## 9. The complete starting state

After this lecture:

| Component | Status |
|---|---|
| Docker Desktop | ✅ Installed and running |
| `ollama/ollama` image | ✅ Pulled |
| `ollama` container | ✅ Running, detached |
| Port 11434 | ✅ Mapped (host ↔ container) |
| `ollama` named volume | ✅ Created for model persistence |
| Downloaded models | ❌ None yet (next lecture pulls `gemma:2b`) |
| Chat UI | ❌ Not installed yet (next lecture) |

The plumbing is in place. The next note ([[04 - Open WebUI Setup and First Chat]]) adds the chat interface and the first model.

---

## 10. The Ollama CLI (running inside the container)

Ollama has its own CLI accessible inside the container — useful as an alternative to the WebUI:

```bash
docker exec -it ollama ollama list             # list installed models
docker exec -it ollama ollama pull gemma:2b    # pull a model
docker exec -it ollama ollama run gemma:2b     # interactive chat with a model
docker exec -it ollama ollama rm gemma:2b      # remove a model
```

The Open WebUI ([[04 - Open WebUI Setup and First Chat]]) uses the same operations under the hood via Ollama's API, but the CLI works as an alternative.

---

## 11. Common gotchas

> [!warning] Things that go wrong on first run

| Symptom | Cause | Fix |
|---|---|---|
| "connection refused" on `localhost:11434` | Missing `-p` | Recreate container with `-p 11434:11434` |
| `port is already allocated` | Another process using 11434 | Use different host port: `-p 11435:11434`, update clients to use 11435 |
| Models gone after restart | Missing `-v` | Recreate with `-v ollama:/root/.ollama` |
| "no such image" | Typo in image name | It's `ollama/ollama`, not `ollama:latest` (well, both work) |
| Image pull is slow / fails | Slow network / Docker Hub throttling | Retry; sometimes use a mirror registry |
| Container stops immediately | Out of memory | Check Docker Desktop memory allocation (Settings → Resources) |
| Slow inference | No GPU access | Accept on CPU, or install Ollama natively for GPU |

---

## 12. Main takeaways

- Pull and run the **official `ollama/ollama` image**.
- **Always include `-p 11434:11434`** — otherwise the container is unreachable.
- **Always include `-v ollama:/root/.ollama`** — otherwise models disappear on container restart.
- Use `-d` for detached/background, `--name ollama` for friendly reference.
- The full command:
  ```bash
  docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
  ```
- Ollama API listens on **`localhost:11434`** once port-mapped.
- For NVIDIA GPUs: add `--gpus all`.
- On Apple Silicon Macs: Docker can't use the GPU → native install is faster.
- After this, the LLM **plumbing is ready**; models still need to be pulled.

---

## 13. Things I still want to figure out

- What's the **memory limit** Docker Desktop allocates by default — and is that enough for 7B models?
- How to **back up** the `ollama` named volume (in case of system migration)?
- For multi-user / shared dev environments, is there a way to run Ollama on a shared server and clients connect remotely?
- What's the latency overhead of Docker for LLM inference vs native install?
- Can multiple Ollama containers run simultaneously (e.g., one per project)? Trade-offs?
- How does **Ollama's model storage format** differ from raw Hugging Face downloads?

---

## 14. Things to dig into

- **Ollama Docker docs**: https://hub.docker.com/r/ollama/ollama
- **Ollama API reference**: https://github.com/ollama/ollama/blob/main/docs/api.md
- **Ollama OpenAI-compat docs**: https://ollama.com/blog/openai-compatibility — relevant for [[04 - Using Gemini through OpenAI SDK]] style integration.
- **Hands-on**: After this note, run `curl http://localhost:11434/api/tags` to confirm the API responds.

---

## 15. Next up in this section

Ollama is running but has no models and no UI. Fix both next:

- [ ] [[04 - Open WebUI Setup and First Chat]] — install the chat UI, pull `gemma:2b`, send the first prompt.

---

## Related
- [[02 - Docker Deep Dive]] — Docker fundamentals.
- [[01 - Why Run LLMs Locally]] — context for this setup.
- [[04 - Using Gemini through OpenAI SDK]] — the OpenAI-compat layer that also lets Ollama be called like OpenAI.

## Sources
- [Ollama Docker Hub image](https://hub.docker.com/r/ollama/ollama)
- [Ollama API reference](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Ollama OpenAI-compatibility blog post](https://ollama.com/blog/openai-compatibility)
- [NVIDIA Container Toolkit install guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html)
