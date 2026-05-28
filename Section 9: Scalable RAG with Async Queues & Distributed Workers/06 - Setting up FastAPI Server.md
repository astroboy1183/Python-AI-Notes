---
title: Setting up FastAPI Server
date: 2026-05-28
source: "Section 9 / Lecture 6"
type: lecture-notes
status: in-progress
section: "Section 9: Scalable RAG with Async Queues & Distributed Workers"
tags:
  - fastapi
  - uvicorn
  - python
  - server
  - rag
  - infrastructure
  - hands-on
related:
  - "[[05 - FastAPI Setup]]"
  - "[[05 - Creating the Worker (process_query)]]"
  - "[[07 - The Chat Route - Enqueueing Jobs]]"
---

# Setting up FastAPI Server

> [!abstract] TL;DR
> Standard FastAPI scaffold from [[05 - FastAPI Setup|Section 5]] — but split into two files instead of one: **`server.py`** (declares the FastAPI app + routes) and **`main.py`** (entry point that loads `.env` and starts uvicorn). Why split: cleaner separation between "how the app is configured to run" (main.py) and "what the app does" (server.py). `python main.py` becomes the launch command. Server binds to `0.0.0.0:8000` so external clients can reach it. **`load_dotenv()` must run before any imports that need `OPENAI_API_KEY`** — a subtle ordering issue that bites if you don't get it right (covered in the chat-route note). After this, an empty FastAPI server runs at `localhost:8000`, ready for routes.

> [!info] Where this fits
> Sixth lecture of **Section 9: Scalable RAG with Async Queues & Distributed Workers**. Builds the producer side. The next two lectures add the actual routes ([[07 - The Chat Route - Enqueueing Jobs]] and [[08 - The Get Result Route - Fetching Job Status]]).

---

## 1. Recap from Section 5

FastAPI was introduced in [[05 - FastAPI Setup]]:
- `pip install "fastapi[standard]"`.
- Define routes with `@app.get(...)`.
- Run with `fastapi dev server.py`.

This section uses **the same library, slightly different launch pattern** — explicit `main.py` with `uvicorn.run(...)` instead of the CLI. Both work; explicit launch is more flexible for production.

---

## 2. Why a separate `main.py`

Two reasons:

### Reason 1 — env-loading control
`load_dotenv()` **must** happen before any module that reads `OPENAI_API_KEY` at import time gets imported. With `fastapi dev`, the order is implicit. With explicit `main.py`, the order is **explicitly controlled**:

```python
# main.py
from dotenv import load_dotenv
load_dotenv()                          # 1. Load env first

from server import app                  # 2. THEN import the app
import uvicorn

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

### Reason 2 — production parity
Production deployments use `gunicorn -k uvicorn.workers.UvicornWorker server:app` or similar — they import an `app` object from a module. Having `server.py` already exposing `app` matches that pattern.

For learning, both flavors work. The explicit approach used here is the more production-shaped one.

---

## 3. `server.py` — the app + routes

```python
# server.py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"status": "Server is up and running"}
```

Five lines. The `app` object is exported for `main.py` to start.

---

## 4. `main.py` — the entry point

```python
# main.py
from dotenv import load_dotenv

# IMPORTANT: load env BEFORE importing anything else that needs it
load_dotenv()

from server import app
import uvicorn

def main():
    uvicorn.run(app, host="0.0.0.0", port=8000)

if __name__ == "__main__":
    main()
```

### What each piece does

| Line | Purpose |
|---|---|
| `load_dotenv()` | Read `.env` into `os.environ` |
| `from server import app` | Get the FastAPI app instance |
| `uvicorn.run(...)` | Start the ASGI server |
| `host="0.0.0.0"` | Listen on all interfaces (vs `127.0.0.1` which is localhost-only) |
| `port=8000` | Standard FastAPI port |
| `if __name__ == "__main__"` | Only run when invoked directly |

> [!tip] Why `0.0.0.0` instead of `127.0.0.1`
> - `127.0.0.1` / `localhost` — only reachable from the same machine.
> - `0.0.0.0` — reachable from any network interface (Docker, other machines on LAN).
>
> For local dev: either works. For containerized / cloud deployments: must be `0.0.0.0`.

---

## 5. `.env` file

```
# .env
OPENAI_API_KEY=sk-...
```

Same as previous sections. Important: **add to `.gitignore`**.

```
# .gitignore
.env
__pycache__/
venv/
```

---

## 6. Running the server

```bash
python main.py
```

Output:

```
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

Verify:

```bash
curl http://localhost:8000
# {"status":"Server is up and running"}
```

Or visit in browser. The auto-generated docs are at:

```
http://localhost:8000/docs
```

That confirms the FastAPI scaffold is up — the `/docs` view shows the Swagger UI for the routes (just the root right now).

---

## 7. Why hot-reload is missing here

`fastapi dev server.py` ships with hot-reload built in (file change → server restart). The explicit `uvicorn.run(app, ...)` doesn't have it by default.

To add:

```python
uvicorn.run(
    "server:app",       # import string instead of object
    host="0.0.0.0",
    port=8000,
    reload=True,        # hot reload
)
```

Note: `reload=True` requires passing the app **as an import string** (`"server:app"`), not as a Python object.

For Section 9's quick development: hot-reload is nice-to-have. Skipping it here.

---

## 8. Project structure so far

```
rag_queue/
├── docker-compose.yml          # Qdrant + Valkey
├── requirements.txt
├── .env                         # OPENAI_API_KEY
├── main.py                     # ← this lecture
├── server.py                   # ← this lecture
├── client/
│   ├── __init__.py
│   └── rq_client.py            # queue handle
└── queues/
    ├── __init__.py
    └── worker.py               # process_query()
```

Five Python files. Clean separation of concerns.

---

## 9. State after this lecture

| Component | Status |
|---|---|
| Valkey container | ✅ |
| Qdrant container | ✅ |
| RQ client | ✅ |
| Worker function | ✅ |
| `server.py` | ✅ (empty app + root route) |
| **`main.py`** | ✅ (entry point with uvicorn) |
| Server runs | ✅ on port 8000 |
| Chat route | ❌ Next lecture |
| Result route | ❌ |
| Workers running | ❌ Final lecture |

---

## 10. Auto-generated docs preview

FastAPI's killer feature — visit `/docs`:

```
http://localhost:8000/docs
```

Currently shows just the root route. Once chat + result routes are added, they'll appear here with "Try it out" buttons (used heavily in the next two notes for testing).

---

## 11. Common gotchas

> [!warning] FastAPI server issues

| Symptom | Cause | Fix |
|---|---|---|
| `address already in use` | Port 8000 busy | Pick different port or kill the process |
| Routes don't auto-update | No `reload=True` | Add the flag or use `fastapi dev` |
| Can't reach from another machine | Bound to `127.0.0.1` | Use `0.0.0.0` |
| `OPENAI_API_KEY missing` | `load_dotenv()` after imports | Move it to top of `main.py` |
| Server starts but routes 404 | Wrong app object imported | Check `from server import app` |
| Browser shows blank `/docs` | Server not running | `python main.py` first |

---

## 12. Why `uvicorn` and not other servers

| Server | Notes |
|---|---|
| **uvicorn** | ASGI server, FastAPI's default, recommended |
| **gunicorn + uvicorn workers** | Production combo — gunicorn supervises uvicorn workers |
| **hypercorn** | Alternative ASGI server |
| **daphne** | Django's ASGI server |

For dev: `uvicorn` direct.
For prod: `gunicorn` with uvicorn workers gives auto-restart on worker death.

---

## 13. Main takeaways

- Split into **`server.py`** (app + routes) and **`main.py`** (env + uvicorn launch).
- `main.py` calls `load_dotenv()` **first**, then imports the app.
- `host="0.0.0.0"` for containerized/cloud reachability.
- `port=8000` standard.
- Run with `python main.py`.
- Auto-docs at `/docs` (Swagger) and `/redoc`.
- For hot-reload: `uvicorn.run("server:app", reload=True, ...)`.
- Production: `gunicorn -k uvicorn.workers.UvicornWorker server:app`.
- Server scaffold is **ready for routes** in the next notes.

---

## 14. Things I still want to figure out

- For **production deployment**, gunicorn worker count tuning?
- How to add **logging middleware** properly?
- For **CORS** with browser clients, what's the FastAPI pattern?
- How to **gracefully shutdown** with active jobs?
- What's the right way to add **request IDs** for tracing?

---

## 15. Things to dig into

- **FastAPI docs**: https://fastapi.tiangolo.com/
- **uvicorn docs**: https://www.uvicorn.org/
- **gunicorn with uvicorn workers**: production deployment pattern.
- **Hands-on**: hit `http://localhost:8000/docs` and explore the Swagger UI before adding routes.

---

## 16. Next up in this section

Add the route that enqueues jobs:

- [ ] [[07 - The Chat Route - Enqueueing Jobs]] — POST /chat that pushes queries to the queue.

---

## Related
- [[05 - FastAPI Setup]] — Section 5 — FastAPI fundamentals.
- [[05 - Creating the Worker (process_query)]] — the function the server will enqueue.
- [[04 - Installing RQ and Building the Queue Client]] — the queue handle the server will use.

## Sources
- [FastAPI documentation](https://fastapi.tiangolo.com/)
- [uvicorn documentation](https://www.uvicorn.org/)
- [gunicorn documentation](https://docs.gunicorn.org/)
