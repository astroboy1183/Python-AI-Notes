---
title: FastAPI Setup
date: 2026-05-28
source: "Section 5 / Lecture 5"
type: lecture-notes
status: in-progress
section: "Section 5: Local LLM Deployment & API Integration"
tags:
  - fastapi
  - python
  - rest-api
  - web-framework
  - uvicorn
  - pydantic
  - openapi
  - hands-on
related:
  - "[[02 - Using OpenAI API in Python]]"
  - "[[06 - Connecting FastAPI to Ollama]]"
---

# FastAPI Setup

> [!NOTE]
> **TL;DR**
> **FastAPI** (by **Sebastián Ramírez / Tiangolo**) is a modern Python web framework for building REST APIs. Three big advantages: **fast** (built on Starlette + Uvicorn), **typed** (uses Python type hints for validation via Pydantic), and **auto-documented** (generates an interactive Swagger UI at `/docs` for free). Install: `pip install "fastapi[standard]"`. Hello-world endpoint: define a function decorated with `@app.get("/")` returning a dict — done. Run: `fastapi dev server.py` → server up at `localhost:8000` with built-in hot-reload. This lecture builds a basic FastAPI server with two routes (`/` and `/contact-us`) — the foundation for [[06 - Connecting FastAPI to Ollama]] which wraps the local LLM in a REST API.

> [!NOTE]
> **Where this fits**
> Fifth lecture of **Section 5: Local LLM Deployment & API Integration**. Pivots from "model + UI" to "model + programmatic access." After this lecture, the basic FastAPI server is running; the next lecture connects it to Ollama so the local model becomes a real REST API.

---

## 1. What FastAPI is

[FastAPI](https://fastapi.tiangolo.com) is a Python web framework optimized for **building APIs** (as opposed to full-stack web apps).

| Feature | Why it matters |
|---|---|
| **Fast** | Built on **Starlette** (ASGI) + **Uvicorn** — one of the fastest Python frameworks |
| **Type-safe** | Python type hints become request validation via **Pydantic** |
| **Auto docs** | Interactive Swagger UI at `/docs` and ReDoc at `/redoc` — for free |
| **Async-first** | `async def` works natively for I/O-bound endpoints |
| **Modern Python** | Targets Python 3.8+; clean syntax |
| **OpenAPI spec** | Generates a standards-compliant OpenAPI document |

The official site is **fastapi.tiangolo.com** — Tiangolo (Sebastián Ramírez) being the creator. For LLM-related APIs (the use case in this section), FastAPI is the **default Python pick**.

---

## 2. Installation

Inside the project's activated virtual environment:

```bash
pip install "fastapi[standard]"
```

> [!NOTE]
> **The `[standard]` extras**
> Plain `pip install fastapi` installs the core library. `"fastapi[standard]"` includes:
> - **Uvicorn** — the ASGI server.
> - **httpx** — modern HTTP client for testing.
> - **email-validator** — for email field types.
> - **`fastapi` CLI** — the `fastapi dev` / `fastapi run` commands.
>
> For a quickstart, `[standard]` is the right choice. For production, sometimes just `fastapi` + a custom server is preferred.

After install, freeze dependencies:

```bash
pip freeze > requirements.txt
```

This adds `fastapi`, `uvicorn`, etc. to the dependency list.

---

## 3. The minimal app — `server.py`

Inside a new project folder (e.g. `ollama_fastapi/`):

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {"hello": "world"}
```

That's a complete FastAPI server. Five lines.

### What each line does

| Line | Purpose |
|---|---|
| `from fastapi import FastAPI` | Import the framework class |
| `app = FastAPI()` | Create the application instance |
| `@app.get("/")` | Register a handler for `GET /` |
| `def root():` | The handler function |
| `return {"hello": "world"}` | Return data — FastAPI auto-serializes to JSON |

> [!TIP]
> **Auto-JSON**
> Whatever the handler returns (dict, list, Pydantic model) gets **automatically serialized to JSON** in the HTTP response, with the right `Content-Type: application/json` header set. No `jsonify` calls needed.

---

## 4. Running the server

From the project folder:

```bash
fastapi dev server.py
```

`dev` mode includes hot-reload — file edits trigger a server restart.

Output:

```
INFO     Started server process [12345]
INFO     Waiting for application startup.
INFO     Application startup complete.
INFO     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
```

Visit **`http://localhost:8000`** in a browser → returns `{"hello": "world"}` as JSON. Uvicorn is now running on localhost:8000 and serving the response.

---

## 5. Adding more routes

Easy:

```python
@app.get("/")
def root():
    return {"hello": "world"}

@app.get("/contact-us")
def contact_us():
    return {"email": "jayanth@example.com"}
```

The hot-reload kicks in automatically. Visit `http://localhost:8000/contact-us` → returns the contact email. Now there are two endpoints — root `/` and `/contact-us` — both auto-reloading on file changes.

---

## 6. The two URL patterns

| HTTP method + path | Decorator |
|---|---|
| `GET /` | `@app.get("/")` |
| `GET /contact-us` | `@app.get("/contact-us")` |
| `POST /chat` | `@app.post("/chat")` |
| `PUT /items/{id}` | `@app.put("/items/{id}")` |
| `DELETE /items/{id}` | `@app.delete("/items/{id}")` |

For the [[06 - Connecting FastAPI to Ollama|next note]], the `chat` endpoint will be `POST /chat` — taking a JSON body with a user message.

---

## 7. The free Swagger UI — `/docs`

The killer FastAPI feature. After starting the server, visit:

```
http://localhost:8000/docs
```

A fully interactive **Swagger UI** appears — every registered route is listed, with parameter forms, "Try it out" buttons, and live response display.

Behind the scenes:
- FastAPI generates an **OpenAPI 3** specification from the decorated functions and type hints.
- The Swagger UI renders that spec into the interactive page.
- No manual documentation maintenance — the docs **always match the code**.

Especially useful for the next note: instead of running `curl` commands, click "Try it out" → enter a message → see the LLM reply.

> [!TIP]
> **Alternative docs view**
> FastAPI also exposes ReDoc at `/redoc` — a different, more reference-doc-style view of the same OpenAPI spec. Both update automatically.

---

## 8. Adding type hints + Pydantic (preview)

A more realistic endpoint declares request bodies using Pydantic models:

```python
from pydantic import BaseModel
from fastapi import FastAPI

app = FastAPI()

class ChatRequest(BaseModel):
    message: str

@app.post("/chat")
def chat(request: ChatRequest):
    return {"echo": request.message}
```

What FastAPI does automatically:
- Validates that the incoming JSON has a `message` field of type `string`.
- Returns `422 Unprocessable Entity` with a clear error if validation fails.
- Includes the schema in the Swagger UI for the request body.

The next note uses an inline shortcut (`Body(..., description="The message")`) but Pydantic models are the **idiomatic production approach**.

---

## 9. The starting state for the next note

After this lecture:

| Component | Status |
|---|---|
| Virtual environment | ✅ Activated |
| `fastapi[standard]` package | ✅ Installed |
| `server.py` | ✅ Created |
| Two routes (`/`, `/contact-us`) | ✅ Working |
| Server | ✅ Running on `localhost:8000` |
| `/docs` Swagger UI | ✅ Auto-generated |
| Ollama connection | ❌ Not yet — comes next |

---

## 10. Why FastAPI specifically (and not Flask, Django, etc.)

Quick justification:

| Framework | Strength | Weakness for LLM APIs |
|---|---|---|
| **FastAPI** | Async, typed, auto docs | Few — best fit |
| **Flask** | Simple, mature | Sync only by default; no built-in validation |
| **Django REST Framework** | Full-stack ecosystem | Heavy for pure APIs |
| **Starlette** | What FastAPI is built on | Lower-level; more boilerplate |
| **Sanic** | Async, fast | Smaller ecosystem |

For LLM API services in 2024+, **FastAPI is the standard pick**. Streaming responses (essential for token-by-token LLM output) work cleanly with async, and Pydantic validation pairs perfectly with structured LLM outputs ([[05 - Structured Output with Few-Shot Prompting]]).

---

## 11. Common gotchas

> [!WARNING]
> **First-time FastAPI snags**

| Symptom | Likely cause | Fix |
|---|---|---|
| `command not found: fastapi` | `[standard]` extras missing | `pip install "fastapi[standard]"` |
| Port 8000 in use | Another service has it | Use different: `fastapi dev server.py --port 8001` |
| Changes not reloading | Not using `dev` command | `fastapi dev`, not `fastapi run` |
| `422 Unprocessable Entity` | Request body doesn't match Pydantic model | Check the error response for the exact missing/extra fields |
| `/docs` returns 404 | Not at the root or running an old version | Confirm URL is exactly `http://localhost:8000/docs` |
| Import error inside venv | Wrong Python or venv not activated | `source venv/bin/activate`, then re-run |

---

## 12. Main takeaways

- **FastAPI** is the standard modern Python web framework for building REST APIs.
- Install: **`pip install "fastapi[standard]"`** (includes Uvicorn + CLI).
- Minimal app: `app = FastAPI()` + `@app.get("/")` + a handler function.
- Run with **`fastapi dev server.py`** → hot-reload on file changes.
- Default URL: **`http://localhost:8000`**.
- Returned dicts → JSON automatically.
- Free interactive docs at **`/docs`** (Swagger) and **`/redoc`** (ReDoc).
- **Pydantic models** validate request bodies and auto-generate OpenAPI schemas.
- Decorators: `@app.get`, `@app.post`, `@app.put`, `@app.delete`.
- Pairs perfectly with LLM APIs (async, streaming, structured I/O).

---

## 13. Things I still want to figure out

- For LLM streaming responses, what's the FastAPI pattern? (`StreamingResponse` with `async`-generator?)
- Production deployment: **gunicorn + uvicorn workers**? Or Docker?
- How to add **authentication** (API key, JWT) cleanly?
- Best practice for **dependency injection** in FastAPI (the `Depends(...)` system)?
- How to organize routes once the app grows (routers, subapps)?
- What's the right way to handle **CORS** for browser-side LLM apps?
- Performance benchmarks — how many req/s can a single-worker FastAPI handle for LLM proxying?

---

## 14. Things to dig into

- **FastAPI docs**: https://fastapi.tiangolo.com — extensive and well-written.
- **Tutorial**: https://fastapi.tiangolo.com/tutorial/ — best-in-class.
- **Pydantic docs**: https://docs.pydantic.dev — Pydantic is half of FastAPI's superpower.
- **Streaming responses**: https://fastapi.tiangolo.com/advanced/custom-response/#streamingresponse
- **Production deployment**: https://fastapi.tiangolo.com/deployment/

---

## 15. Next up in this section

The FastAPI skeleton is ready. Next, wire it to Ollama → REST API in front of the local LLM:

- [ ] [[06 - Connecting FastAPI to Ollama]] — `pip install ollama`, build a `/chat` endpoint that proxies to the running Ollama server.

---

## Related
- [[02 - Using OpenAI API in Python]] — similar Python setup pattern (`venv`, `pip`, env vars).
- [[01 - Why Run LLMs Locally]] — section context.
- [[04 - Open WebUI Setup and First Chat]] — the prior way to chat with the model; FastAPI gives programmatic access.

## Sources
- [FastAPI docs](https://fastapi.tiangolo.com)
- [FastAPI tutorial](https://fastapi.tiangolo.com/tutorial/)
- [Pydantic docs](https://docs.pydantic.dev)
- [FastAPI StreamingResponse](https://fastapi.tiangolo.com/advanced/custom-response/#streamingresponse)
- [FastAPI deployment](https://fastapi.tiangolo.com/deployment/)
