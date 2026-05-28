---
title: Docker Deep Dive
date: 2026-05-28
source: "Section 5 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 5: Local LLM Deployment & API Integration"
tags:
  - docker
  - containers
  - devops
  - infrastructure
  - docker-desktop
  - docker-cli
  - foundations
  - hands-on
related:
  - "[[01 - Why Run LLMs Locally]]"
  - "[[03 - Running Ollama in Docker]]"
---

# Docker Deep Dive

> [!abstract] TL;DR
> **Docker** is a container management tool that lets applications run in **isolated, portable, reproducible** environments. Instead of installing Ollama (and its dependencies, libraries, network configs, etc.) directly onto a machine, run it as a **container**: a self-contained bundle that includes the app and everything it needs. **Same `docker run` command works on Mac, Linux, Windows** — that's why the course picks Docker over a native Ollama install. Core commands: `docker pull <image>` (download), `docker run <image>` (start), `docker container ps` (list), `docker container rm <id>` (delete). This lecture covers Docker just enough to install Ollama in the next note; deep Docker expertise isn't required.

> [!info] Where this fits
> Second lecture of **Section 5: Local LLM Deployment & API Integration**. Pure infrastructure setup. The next lecture ([[03 - Running Ollama in Docker]]) puts these Docker skills to work running the Ollama LLM server.

> [!warning] Not a Docker course
> This is a Docker primer scoped to "what's needed for the next lecture." For deeper Docker mastery (Dockerfiles, multi-stage builds, Docker Compose, networks, swarms), use a dedicated Docker course or the official docs.

---

## 1. What Docker actually does

Docker packages an application + everything it depends on (system libraries, runtime, config files) into a **container image**. That image can be **run anywhere Docker is installed** and behave identically.

```
┌──────────────────────────────────────────────────────────┐
│   YOUR MACHINE                                            │
│                                                            │
│   ┌──────────────────────────────────────────────────┐    │
│   │   Docker Engine                                  │    │
│   │                                                  │    │
│   │   ┌──────────────┐  ┌──────────────┐             │    │
│   │   │  Container:  │  │  Container:  │             │    │
│   │   │   Ollama     │  │  Open WebUI  │             │    │
│   │   │  (port 11434)│  │  (port 3000) │             │    │
│   │   └──────────────┘  └──────────────┘             │    │
│   │                                                  │    │
│   │   Each container is isolated, has its own        │    │
│   │   filesystem, ports, processes.                  │    │
│   └──────────────────────────────────────────────────┘    │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

Key benefits:

| Benefit | What it means |
|---|---|
| **Platform-agnostic** | Same container works on Mac, Linux, Windows |
| **Isolated** | Containers don't pollute the host system |
| **Reproducible** | Same image = same behavior, anywhere |
| **Versioned** | Pin to specific versions; easy rollback |
| **Disposable** | Tear down and recreate cleanly |
| **Production-ready** | Same image runs on dev laptop and prod server |

---

## 2. Why Docker over native install for Ollama

Three reasons to prefer Docker over a native Ollama install:

| Reason | Detail |
|---|---|
| **Cross-platform** | One set of commands works across macOS, Linux, Windows |
| **No system bloat** | Doesn't install Ollama binaries / models into `/usr/local`, etc. |
| **Transferable knowledge** | Future deployment to a server uses the same Docker workflow |

Installing tools like this directly onto the host always feels wrong — Docker keeps the machine clean while teaching the exact workflow that translates to deploying Ollama on a real server later.

---

## 3. Installing Docker Desktop

The recommended install path for personal machines:

1. Visit **https://docker.com**.
2. Click **Download Docker Desktop**.
3. Pick the right installer:
   - **macOS** — Apple Silicon or Intel.
   - **Windows** — works on Windows 10/11 (uses WSL2 under the hood).
   - **Linux** — Docker Desktop is also available; CLI-only Docker Engine is more common.
4. Install + launch.

After installation, **Docker Desktop** runs in the background. The icon in the menu bar / system tray shows whether the engine is up.

> [!note] Linux alternative
> On Linux, many people skip Docker Desktop and install **Docker Engine** directly (`docker-ce` / `docker-ce-cli` packages). Both work; Docker Desktop adds a GUI and a single-binary install path.

---

## 4. Verifying the install

Open a terminal:

```bash
docker
```

If a help screen appears listing available commands, Docker is installed and the daemon is reachable.

```bash
docker --version
```

Should print something like `Docker version 28.x.x, build ...`. The major version number is roughly chronological — version 28 was the current release while these notes were taken.

---

## 5. The Docker Desktop GUI

Launching Docker Desktop shows a window with tabs for:

| Tab | What's there |
|---|---|
| **Containers** | Running and stopped containers, with start/stop/delete controls |
| **Images** | Downloaded images on the machine |
| **Volumes** | Persistent storage attached to containers |
| **Builds** | Build history |

Useful for visual inspection. The same operations are doable from the CLI.

---

## 6. The core Docker commands (CLI)

The minimum needed for this section:

### `docker pull <image>` — download an image

```bash
docker pull busybox
```

Downloads the `busybox` image from **Docker Hub** (the default public registry). Each image has a name like `ollama/ollama`, `nginx`, `mongo:7`, etc.

### `docker run <image> <command>` — start a container

```bash
docker run busybox ls
```

This:
1. Creates a new container from the `busybox` image.
2. Runs the `ls` command inside it.
3. Exits when the command finishes.

Result: the directory listing inside the container prints to the terminal.

### `docker container ps` — list running containers

```bash
docker container ps
```

Shows currently-running containers with their IDs, image, status, ports.

For all containers (including stopped):

```bash
docker container ps -a
```

### `docker container rm <id-or-name>` — delete a container

```bash
docker container rm 561abc123
```

Removes the container (stopped containers can be removed; running ones need `-f`).

> [!example] More flags worth knowing

| Flag | Purpose | Example |
|---|---|---|
| `-d` | Detached (run in background) | `docker run -d <image>` |
| `-p HOST:CONTAINER` | Map ports | `docker run -p 11434:11434 ollama/ollama` |
| `-v HOST:CONTAINER` | Mount a volume | `docker run -v ollama:/root/.ollama ollama/ollama` |
| `--name <n>` | Give the container a name | `docker run --name my-ollama ...` |
| `-e KEY=VAL` | Set environment variable | `docker run -e DEBUG=true ...` |
| `--rm` | Auto-remove on exit | `docker run --rm <image>` |
| `-it` | Interactive terminal | `docker run -it <image> bash` |
| `--restart unless-stopped` | Auto-restart on host reboot | `docker run --restart unless-stopped ...` |

The Ollama installation in [[03 - Running Ollama in Docker]] uses several of these (notably `-d`, `-p`, `-v`, `--name`).

---

## 7. Walkthrough — quick verification demo

A minimal end-to-end check:

```bash
docker --version
# Docker version 28.x.x

docker pull busybox
# Pulls busybox image from Docker Hub

docker run busybox ls
# Lists files inside the busybox container

docker container ps -a
# Shows the just-exited busybox container

docker container rm <container-id>
# Removes the leftover container
```

That's enough to confirm Docker works end-to-end. Now ready for real images.

---

## 8. Docker images, containers, and volumes — terminology

Three core concepts:

| Term | What it is | Analogy |
|---|---|---|
| **Image** | A read-only blueprint (template) for containers | A class in OOP |
| **Container** | A running (or stopped) instance of an image | An object in OOP |
| **Volume** | Persistent storage attached to containers | A separate database / disk |

When containers are removed, their **internal filesystem disappears**. Volumes are how data **survives container deletion** — important for the Ollama setup where downloaded models should persist.

---

## 9. Port mapping — `-p HOST:CONTAINER`

The most-misunderstood Docker concept. A container has its own internal network. By default, services running inside it are **not reachable** from the host.

Port mapping fixes this:

```bash
docker run -p 11434:11434 ollama/ollama
#          ^^^^^^^^^^^^
#          host port : container port
```

This tells Docker:
- Anything connecting to `localhost:11434` on the **host machine**…
- …gets forwarded to port `11434` inside the **container**.

Without `-p`, the Ollama server runs but is unreachable. This is exactly the gotcha that surfaces in the next note.

---

## 10. Volume mapping — `-v HOST:CONTAINER`

Used to persist data and share files:

```bash
docker run -v ollama:/root/.ollama ollama/ollama
#          ^^^^^^^^^^^^^^^^^^^^^^^
#          named volume : path inside container
```

Two flavors:

- **Named volumes** (recommended): `-v ollama:/root/.ollama` — Docker manages where the data physically lives.
- **Bind mounts**: `-v /Users/me/data:/data` — directly map a host directory.

Without this, downloaded Ollama models would disappear every time the container is recreated.

---

## 11. Docker Hub — where images come from

By default, `docker pull` fetches from **https://hub.docker.com** — the public image registry.

Image names follow the pattern:

```
<registry>/<organization>/<image>:<tag>
e.g., docker.io/ollama/ollama:latest
       ^^^^^^^^^ ^^^^^^^ ^^^^^^ ^^^^^^
        default  org    image   version
```

Most commands omit the registry (Docker Hub assumed) and tag (`latest` assumed):

```bash
docker pull ollama/ollama        # = docker.io/ollama/ollama:latest
```

For pinned versions: `docker pull ollama/ollama:0.1.32`.

---

## 12. Common gotchas

> [!warning] First-time Docker pain points

| Symptom | Likely cause | Fix |
|---|---|---|
| `Cannot connect to Docker daemon` | Docker Desktop not running | Launch Docker Desktop |
| `permission denied` (Linux) | User not in `docker` group | `sudo usermod -aG docker $USER` + relog |
| `port is already allocated` | Another process bound to that host port | Pick a different host port: `-p 11435:11434` |
| Models disappear after container restart | No volume mount | Add `-v` for persistent storage |
| `docker run` exits immediately | Container's main process finished | Use `-d` for long-running daemons |
| Image takes ages to pull | Large image, slow network | Just wait; check `docker pull` progress |
| "WSL 2 installation incomplete" (Windows) | Missing WSL2 | Follow Docker Desktop's prompt to install WSL2 |
| Out of disk space | Old images / containers accumulating | `docker system prune -a` (careful — removes everything) |

---

## 13. Main takeaways

- **Docker** = container management tool. Containers are isolated, portable, reproducible runtimes for applications.
- Picked over native Ollama install because: **cross-platform, no bloat, transferable skill**.
- **Install**: Docker Desktop from docker.com → verify with `docker --version`.
- **Core commands**: `docker pull`, `docker run`, `docker container ps`, `docker container rm`.
- **Image** = blueprint, **Container** = running instance, **Volume** = persistent storage.
- **Port mapping** (`-p HOST:CONTAINER`) makes a container's services reachable from the host.
- **Volume mapping** (`-v HOST:CONTAINER`) persists data across container restarts.
- **Docker Hub** is the default public image registry — `docker pull <org>/<image>` works out of the box.
- This is **just enough Docker** for the rest of Section 5; deeper knowledge isn't required.

---

## 14. Things I still want to figure out

- What's the difference between **Docker Desktop** and just installing the **Docker Engine** on Linux?
- How does Docker on macOS / Windows actually work (it uses a VM under the hood)?
- When does **Docker Compose** make sense vs raw `docker run`? (Probably once multiple containers need to be wired together.)
- What's the **right way** to inspect a container's logs / shell into a running container?
- How do **container networks** work between Ollama and Open WebUI?
- For production, when does container orchestration (**Kubernetes**, **Docker Swarm**) become necessary?
- How big are LLM-related Docker images compared to typical web app images?

---

## 15. Things to dig into

- **Docker official docs**: https://docs.docker.com — definitive reference.
- **`docker exec`**: shell into a running container — `docker exec -it <id> bash`.
- **`docker logs`**: stream a container's stdout — `docker logs -f <id>`.
- **Docker Compose**: declare multi-container setups in YAML.
- **Hands-on**: pull and run `nginx`, then `mongo`, then a Python image. Get used to the patterns.

---

## 16. Next up in this section

The Docker basics are in place. Now use them to install the actual LLM server:

- [ ] [[03 - Running Ollama in Docker]] — `docker run` the Ollama image with proper port + volume mapping.

---

## Related
- [[01 - Why Run LLMs Locally]] — why this whole section exists.
- [[03 - Running Ollama in Docker]] — the immediate payoff for these Docker skills.

## Sources
- [Docker official docs](https://docs.docker.com)
- [Docker Hub](https://hub.docker.com)
