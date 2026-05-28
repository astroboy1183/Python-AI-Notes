---
title: Connecting FastAPI to Ollama
date: 2026-05-28
source: "Section 5 / Lecture 6"
type: lecture-notes
status: in-progress
section: "Section 5: Local LLM Deployment & API Integration"
tags:
  - fastapi
  - ollama
  - python
  - local-llm
  - rest-api
  - chatml
  - integration
  - hands-on
  - production-pattern
related:
  - "[[03 - Running Ollama in Docker]]"
  - "[[05 - FastAPI Setup]]"
  - "[[03 - ChatML Prompting]]"
  - "[[02 - Using OpenAI API in Python]]"
---

# Connecting FastAPI to Ollama

> [!abstract] TL;DR
> Final note of Section 5. Wire FastAPI to Ollama so the local LLM is reachable via a **REST API** — same shape an application would use against OpenAI's hosted API. Use the **`ollama` Python SDK** (`pip install ollama`) with `Client(host="http://localhost:11434")` pointing at the Dockerized Ollama server. Build a `POST /chat` endpoint that accepts a `message` body, calls `client.chat(model="gemma:2b", messages=[ChatML])`, and returns the assistant's reply. Test interactively via FastAPI's auto-generated **`/docs`** Swagger UI. The result: a custom **API layer over a local model** — the foundation pattern for serving any local LLM to client apps.

> [!info] Where this fits
> Sixth and final note of **Section 5: Local LLM Deployment & API Integration**. Combines everything from earlier notes: Ollama running ([[03 - Running Ollama in Docker]]), FastAPI scaffolded ([[05 - FastAPI Setup]]), ChatML format ([[03 - ChatML Prompting]]). After this, the course pivots to **Section 6 (Hugging Face)** and beyond.

---

## 1. The architecture

What gets built here:

```
┌─────────────────────────────────────────────────────────────────┐
│   Client (browser / curl / mobile app / other service)          │
└───────────────────────────┬─────────────────────────────────────┘
                            │  HTTP POST /chat
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│   FastAPI server (Python)                                       │
│   localhost:8000                                                │
│                                                                 │
│   @app.post("/chat")                                            │
│   def chat(message): ...                                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │  ollama Python SDK call
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│   Ollama (in Docker container)                                  │
│   localhost:11434                                               │
│                                                                 │
│   Model: gemma:2b                                               │
└─────────────────────────────────────────────────────────────────┘
```

The pattern: **client → FastAPI → Ollama → model → back through the chain**.

This is exactly the architecture used to expose a local LLM to:
- A mobile app.
- A web frontend.
- Another microservice in a larger system.
- A CLI tool.
- A LangChain / LangGraph orchestration layer.

---

## 2. The Ollama Python SDK

Ollama ships an official Python client:

```bash
pip install ollama
pip freeze > requirements.txt
```

Import patterns:

```python
# Option A — module-level functions (uses default localhost:11434)
from ollama import chat
response = chat(model="gemma:2b", messages=[...])

# Option B — Client class (custom host)
from ollama import Client
client = Client(host="http://localhost:11434")
response = client.chat(model="gemma:2b", messages=[...])
```

**Option B** (Client class) is preferable here because it's explicit about where Ollama lives — a useful habit once multiple environments come into play.

---

## 3. Connecting to the Dockerized Ollama

```python
from ollama import Client

client = Client(
    host="http://localhost:11434",
    # headers={...}   # optional — can add auth headers if needed
)
```

This is the exact pattern from [[04 - Using Gemini through OpenAI SDK]] but for Ollama's native SDK — pointing the client at a custom server endpoint.

> [!note] Why localhost:11434
> Because Ollama runs in Docker with `-p 11434:11434` (from [[03 - Running Ollama in Docker]]), it's reachable from the host's `localhost` on that port. The FastAPI server (on the host) connects to it via `http://localhost:11434`.

> [!warning] Make sure Ollama is up
> Easy trap: the Ollama container gets stopped (manual `docker stop`, reboot, etc.) and the FastAPI call fails with a connection error. **Always confirm Ollama is running** (`docker ps` should show the container) before testing the FastAPI endpoint.

---

## 4. The `/chat` endpoint

Full `server.py` (combining [[05 - FastAPI Setup]] + this note):

```python
from fastapi import FastAPI, Body
from ollama import Client

app = FastAPI()

client = Client(host="http://localhost:11434")

@app.get("/")
def root():
    return {"hello": "world"}

@app.post("/chat")
def chat(message: str = Body(..., description="The message")):
    response = client.chat(
        model="gemma:2b",                       # model pulled in note 04
        messages=[
            {"role": "user", "content": message},
        ],
    )
    return {"response": response.message.content}
```

That's the entire integration. Three things happen:

1. **FastAPI receives** a POST request with a JSON body containing a `message`.
2. **The Ollama client** sends a chat request to the local model in ChatML format.
3. **The response** comes back; FastAPI returns it as JSON to the caller.

---

## 5. The Body declaration

```python
def chat(message: str = Body(..., description="The message")):
```

This tells FastAPI:
- Expect a `message` field in the **request body** (not the URL).
- It's a required `string`.
- Description "The message" appears in the auto-generated `/docs` UI.

> [!example] Pydantic alternative (more idiomatic)
> A cleaner production pattern:
> ```python
> from pydantic import BaseModel
>
> class ChatRequest(BaseModel):
>     message: str
>
> @app.post("/chat")
> def chat(request: ChatRequest):
>     ...
> ```
> Plus all the validation, schema generation, etc. covered in [[05 - FastAPI Setup]].
>
> The `Body(...)` shortcut is fine for quick prototyping.

---

## 6. The ChatML message structure

The `messages` parameter uses the **ChatML format** from [[03 - ChatML Prompting]]:

```python
messages=[
    {"role": "user", "content": "Why is the sky blue?"},
]
```

Same shape as OpenAI's API. For a real chatbot, the list would include the full conversation history (system prompt + past turns), but the minimal example here keeps it single-turn.

This is the **payoff of [[03 - ChatML Prompting]]**: knowing the format means working with any chat-completion API (hosted or local) uses the same patterns.

---

## 7. Extracting the response

```python
return {"response": response.message.content}
```

The Ollama Python SDK returns a `ChatResponse` object with:

| Attribute | Type | What it is |
|---|---|---|
| `response.message.role` | string | Usually `"assistant"` |
| `response.message.content` | string | The reply text |
| `response.model` | string | Which model served the request |
| `response.created_at` | timestamp | When the request was processed |
| `response.done` | bool | Whether generation finished |
| `response.total_duration` | int | Nanoseconds spent total |
| `response.eval_count` | int | Number of output tokens |

For the FastAPI response, `response.message.content` is the actual text reply.

---

## 8. Testing via Swagger UI

Run the server:

```bash
fastapi dev server.py
```

Visit **`http://localhost:8000/docs`**.

The Swagger UI shows the `POST /chat` endpoint:
1. Click **"Try it out"**.
2. Enter a message in the `message` field, e.g., `"Why is the sky blue?"`.
3. Click **"Execute"**.

Wait a few seconds (CPU spike, as in [[04 - Open WebUI Setup and First Chat]]) → the response appears:

```json
{
  "response": "The sky appears blue due to Rayleigh scattering — short-wavelength blue light scatters more in the atmosphere than other wavelengths..."
}
```

FastAPI is talking to Ollama, Ollama runs the model, the reply comes back, and the endpoint returns it as JSON. The same endpoint accepts any prompt the model can handle: `"Who are you?"`, `"Tell me a joke"`, `"Write a Python function to add two numbers"`, etc.

---

## 9. The architectural insight

Crystal-clear after this exercise:

> [!tip] The big idea
> Local Ollama, hosted OpenAI, hosted Gemini, hosted Claude — they all expose the same conceptual interface (`messages → reply`). A FastAPI wrapper makes a local model look like a hosted one to client apps.
>
> Result: a client app doesn't need to know (or care) whether it's talking to a free local model or a paid hosted one. Behind the FastAPI proxy, **swap implementations freely**.

This is the foundation pattern for:

| Use case | How it works |
|---|---|
| Cost optimization | Route routine calls to local Ollama; spike to OpenAI for hard cases |
| Privacy filtering | Run a local model that strips PII before forwarding to hosted API |
| Caching layer | FastAPI caches identical prompts before hitting the model |
| Auth / rate-limiting | Add API keys and quotas in front of any LLM backend |
| A/B testing | Route some users to model A, some to model B |
| Hybrid agents | Use local for cheap planning, hosted for the final answer |

---

## 10. Production upgrades

For real services, the basic endpoint needs hardening:

### Streaming responses
```python
from fastapi.responses import StreamingResponse

@app.post("/chat/stream")
def chat_stream(message: str = Body(...)):
    def generate():
        for chunk in client.chat(
            model="gemma:2b",
            messages=[{"role": "user", "content": message}],
            stream=True,
        ):
            yield chunk.message.content

    return StreamingResponse(generate(), media_type="text/event-stream")
```
Tokens arrive at the client as soon as the model emits them — much better UX for long replies.

### Multi-turn conversation
```python
from pydantic import BaseModel

class Message(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: list[Message]

@app.post("/chat")
def chat(req: ChatRequest):
    response = client.chat(
        model="gemma:2b",
        messages=[m.model_dump() for m in req.messages],
    )
    return {"role": "assistant", "content": response.message.content}
```

### System prompts
```python
class ChatRequest(BaseModel):
    message: str
    system_prompt: str | None = None

@app.post("/chat")
def chat(req: ChatRequest):
    messages = []
    if req.system_prompt:
        messages.append({"role": "system", "content": req.system_prompt})
    messages.append({"role": "user", "content": req.message})

    response = client.chat(model="gemma:2b", messages=messages)
    return {"response": response.message.content}
```

### Error handling
```python
from fastapi import HTTPException

@app.post("/chat")
def chat(...):
    try:
        response = client.chat(...)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Model error: {e}")
    return {"response": response.message.content}
```

### Authentication
```python
from fastapi import Header, HTTPException

API_KEY = "secret-key-from-env"

def verify_key(x_api_key: str = Header(...)):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")

@app.post("/chat", dependencies=[Depends(verify_key)])
def chat(...): ...
```

Each of these is one line of upgrade. Production setups stack all of them.

---

## 11. End of Section 5

This wraps up **Section 5: Local LLM Deployment & API Integration**:

| Note | Topic |
|---|---|
| 01 | Why Run LLMs Locally |
| 02 | Docker Deep Dive |
| 03 | Running Ollama in Docker |
| 04 | Open WebUI Setup and First Chat |
| 05 | FastAPI Setup |
| 06 | Connecting FastAPI to Ollama (this note) |

By the end:
- ✅ Docker running.
- ✅ Ollama serving `gemma:2b` on `localhost:11434`.
- ✅ Open WebUI on `localhost:3000` for browser chat.
- ✅ FastAPI on `localhost:8000` exposing `/chat` for programmatic access.

The local-LLM stack is **production-shaped**.

**Next**: Section 6 — running LLMs from the **Hugging Face Hub**, which is the broader open-source model ecosystem behind Ollama's curated catalog.

---

## 12. Main takeaways

- Install the official Ollama SDK: **`pip install ollama`**.
- Create a client: **`Client(host="http://localhost:11434")`**.
- Call it: **`client.chat(model="gemma:2b", messages=[ChatML])`**.
- Get the reply text from **`response.message.content`**.
- In FastAPI: wrap that call in a **`@app.post("/chat")`** handler.
- Test interactively via the auto-generated **`/docs`** Swagger UI.
- The same ChatML format from hosted APIs ([[02 - Using OpenAI API in Python]], [[04 - Using Gemini through OpenAI SDK]]) works directly here.
- The architectural insight: **a local model behind FastAPI looks identical to a hosted model** to client apps.
- Real services add streaming, multi-turn, system prompts, auth, error handling, caching — each just a few extra lines.

---

## 13. Things I still want to figure out

- How does Ollama's **OpenAI-compatible endpoint** (at `localhost:11434/v1/`) compare to the native Ollama SDK? When to prefer one?
- For multi-turn chat, what's the right way to **persist history** on the server (session IDs, Redis)?
- How does streaming **chunk size** affect perceived latency?
- For production, can FastAPI run **multiple workers** and still talk to one shared Ollama instance?
- How to add **observability** (request logs, latency metrics, error rates)?
- What's the **right cache key** when caching LLM responses? (Prompt hash? Model + temperature + prompt?)
- For really long responses, how to handle **timeouts** cleanly?

---

## 14. Things to dig into

- **Ollama Python SDK**: https://github.com/ollama/ollama-python
- **Ollama OpenAI-compatible API**: https://ollama.com/blog/openai-compatibility — works with the OpenAI SDK + `base_url`, exactly the [[04 - Using Gemini through OpenAI SDK]] pattern.
- **FastAPI streaming**: https://fastapi.tiangolo.com/advanced/custom-response/#streamingresponse
- **Hands-on**: extend the `/chat` endpoint to support multi-turn (full history in the request body).

---

## 15. Next up

End of Section 5. Next:

- [ ] **Section 6: Running LLMs via Hugging Face Hub** — the broader open-model ecosystem, downloading models directly from Hugging Face, the `transformers` library.

---

## Related
- [[03 - Running Ollama in Docker]] — provides the server this note connects to.
- [[05 - FastAPI Setup]] — the FastAPI scaffolding this note extends.
- [[03 - ChatML Prompting]] — the message format used in the call.
- [[02 - Using OpenAI API in Python]] — the cloud counterpart pattern.
- [[04 - Using Gemini through OpenAI SDK]] — same `base_url` trick can target Ollama's OpenAI-compatible endpoint.

## Sources
- [Ollama Python SDK](https://github.com/ollama/ollama-python)
- [Ollama OpenAI-compatibility blog post](https://ollama.com/blog/openai-compatibility)
- [FastAPI StreamingResponse](https://fastapi.tiangolo.com/advanced/custom-response/#streamingresponse)
