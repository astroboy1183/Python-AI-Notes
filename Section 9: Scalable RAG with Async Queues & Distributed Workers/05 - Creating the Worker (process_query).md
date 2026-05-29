---
title: Creating the Worker (process_query)
date: 2026-05-28
source: "Section 9 / Lecture 5"
type: lecture-notes
status: in-progress
section: "Section 9: Scalable RAG with Async Queues & Distributed Workers"
tags:
  - rq
  - worker
  - process-query
  - rag
  - retrieval
  - python
  - hands-on
related:
  - "[[04 - Installing RQ and Building the Queue Client]]"
  - "[[11 - Building the Retrieval (chat.py)]]"
  - "[[07 - The Chat Route - Enqueueing Jobs]]"
---

# Creating the Worker (process_query)

> [!NOTE]
> **TL;DR**
> Define `process_query(query: str) -> str` in `queues/worker.py` — the function that **workers run for each enqueued job**. Body is the **same retrieval logic from [[11 - Building the Retrieval (chat.py)|Section 8's chat.py]]**, but refactored into a function (no `while True`, no `input()`, just take a query argument and return a string). Reuses the existing Qdrant vector store + OpenAI client setup. Once defined, the chat route enqueues this function: `queue.enqueue(process_query, user_query)`. The worker (started in a separate process) picks up the job, calls `process_query(...)`, and stashes the return value in Valkey for the polling route to fetch. **The "consumer" in the producer-consumer pattern.**

> [!NOTE]
> **Where this fits**
> Fifth lecture of **Section 9: Scalable RAG with Async Queues & Distributed Workers**. Defines the work that gets done. The next lectures set up the **producer** side (FastAPI + chat route) that enqueues calls to this function.

---

## 1. What the worker function is

An RQ worker is just a Python function. The queue knows how to:
1. Serialize the function call (function reference + arguments).
2. Store it in Redis.
3. When a worker process picks it up, deserialize and call.
4. Store the return value back in Redis.

So the "worker" is genuinely just **a normal Python function**. Nothing RQ-specific in its signature. The contract: take a user query, do the retrieval, return the answer.

---

## 2. Reusing Section 8's logic

Section 8's `chat.py` had:

```python
while True:
    user_query = input("> ")
    search_results = vector_store.similarity_search(user_query)
    context = ...
    response = client.chat.completions.create(...)
    print(response.choices[0].message.content)
```

The worker version:
1. Drops the `while True` (workers handle iteration via the queue).
2. Drops `input()` (the query comes as a function argument).
3. Returns the response instead of printing.

Everything else — embedding model, vector store connection, system prompt, LLM call — is identical.

> [!TIP]
> **Why this is clean**
> The RAG logic was already a **pure function**: query → response. Section 8's chat loop was incidental I/O wrapping it. Refactoring is just **extracting the function** that was always there.

---

## 3. The full `worker.py`

```python
# queues/worker.py
from openai import OpenAI
from langchain_openai import OpenAIEmbeddings
from langchain_qdrant import QdrantVectorStore

client = OpenAI()

embedding_model = OpenAIEmbeddings(model="text-embedding-3-large")

vector_store = QdrantVectorStore.from_existing_collection(
    embedding=embedding_model,
    url="http://localhost:6333",
    collection_name="learning_rag",
)


def process_query(query: str) -> str:
    """Run the RAG retrieval pipeline for a single query."""
    print(f"🔍 Searching chunks for: {query}")
    search_results = vector_store.similarity_search(query=query)

    # Build context with page citations
    context = "\n\n".join([
        f"Page Content: {r.page_content}\n"
        f"Page Number: {r.metadata['page']}\n"
        f"File Location: {r.metadata['source']}"
        for r in search_results
    ])

    system_prompt = f"""
You are a helpful AI assistant who answers user queries based on the
available context retrieved from a PDF file, along with page content
and page number.

You should only answer the user based on the following context and
navigate the user to open the right page number to know more.

Available context:
{context}
"""

    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": query},
        ],
    )

    answer = response.choices[0].message.content
    print(f"🤖 {answer}")
    return answer
```

About 40 lines, almost all copied from [[11 - Building the Retrieval (chat.py)]].

### Key change: returns instead of prints

```python
return answer
```

The return value is **what `queue.fetch_job(job_id).return_value`** will deliver to the polling route ([[08 - The Get Result Route - Fetching Job Status]]).

`print()` statements remain — they appear in the worker terminal's logs, useful for debugging.

---

## 4. Where module-level setup lives

Note the **vector store and client** are constructed at **module level** (outside the function):

```python
client = OpenAI()
embedding_model = OpenAIEmbeddings(...)
vector_store = QdrantVectorStore.from_existing_collection(...)

def process_query(query): ...
```

This matters because:
- Module-level setup runs **once** when the worker process starts.
- The function is called **many times** per worker process.
- Setting up the vector store inside the function would mean **reconnecting every job** — wasteful.

This is the standard "expensive init outside, cheap call inside" pattern for hot paths.

> [!WARNING]
> **But this has a subtlety**
> The module imports `OpenAI()` and `OpenAIEmbeddings(...)` at import time, both of which read `OPENAI_API_KEY` from the environment. If the worker process doesn't have the env loaded **before** importing `worker.py`, the constructors fail.
>
> This bug shows up later in [[09 - Running RQ Workers in Parallel]] — the fix is `load_dotenv()` at the top of `worker.py`:
> ```python
> from dotenv import load_dotenv
> load_dotenv()
> ```
> **above** the imports that need the API key.

---

## 5. What `process_query` does (step-by-step)

1. **Receives** `query` string from the queue.
2. **Embeds + similarity-searches** Qdrant → top-K chunks.
3. **Builds the context string** with page-number metadata.
4. **Builds the system prompt** with the context inline.
5. **Calls OpenAI chat completions** with `[system, user]` messages.
6. **Returns** the LLM's reply as a string.

Identical to Section 8's flow. The async-ness is **outside** this function — in how it's called, not in what it does.

---

## 6. Why this stays a sync function

RQ workers run jobs **one at a time** (or in parallel across multiple worker processes). The function itself doesn't need to be `async def` — RQ handles the queuing dimension.

For Python `asyncio`-style concurrency inside a worker (e.g., parallel API calls inside one job), the function could be async with `asyncio.run(...)` glue. But for "one query → one OpenAI call → one return," **sync is fine**.

---

## 7. How the queue invokes this function

When the chat route does:

```python
queue.enqueue(process_query, user_query)
```

RQ:
1. Stores `("queues.worker.process_query", (user_query,), {})` as a Redis entry.
2. The worker pulls this entry from Redis.
3. The worker imports `queues.worker.process_query` (just like the producer did).
4. Calls `process_query(user_query)`.
5. Captures the return value.
6. Stores the return value back in Redis associated with the job ID.

For this to work:
- **The function must be importable** by the worker process.
- **The same Python environment** must be active in both producer and worker.
- The function's **module path** is what RQ stores (e.g., `queues.worker.process_query`).

So `queues/worker.py` being on the Python path matters. The project structure (`__init__.py` files, running from project root) ensures this.

---

## 8. What if `process_query` raises an exception?

By default:
- RQ marks the job as **failed**.
- Stores the exception's traceback in Redis (`job.exc_info`).
- Worker moves on to the next job — doesn't crash.
- Failed jobs visible via `queue.failed_job_registry`.

For Section 9, no retry / DLQ logic is added. Production setups would:
- Configure RQ to retry N times.
- Use a dead-letter queue.
- Alert on failures.

---

## 9. Module-level imports that matter

```python
from openai import OpenAI
from langchain_openai import OpenAIEmbeddings
from langchain_qdrant import QdrantVectorStore
```

All three packages must be installed in the worker's Python environment (same `venv`).

The connection to Qdrant is made **at worker startup** — meaning Qdrant must be reachable. If it's down, the import fails (or the connection times out). Production setups handle this with retry loops at startup.

---

## 10. State after this lecture

| Component | Status |
|---|---|
| Valkey container | ✅ |
| Qdrant (with indexed PDF) | ✅ (from Section 8) |
| `client/rq_client.py` (queue handle) | ✅ |
| **`queues/worker.py` (`process_query`)** | ✅ |
| FastAPI server | ❌ (next lecture) |
| Chat route (enqueue) | ❌ |
| Result route (poll) | ❌ |
| Workers actually running | ❌ (last lecture) |

The **consumer side is defined**, but no workers are running yet. The next notes wire up the producer side.

---

## 11. Common gotchas

> [!WARNING]
> **Worker function issues**

| Symptom | Cause | Fix |
|---|---|---|
| `OpenAI API key missing` when worker starts | `.env` not loaded before imports | `load_dotenv()` at top |
| `ImportError: queues.worker` from worker | Worker not run from project root | `cd` to project root before running `rq worker` |
| Slow first call | Module-level Qdrant connection delayed | Pre-warm at startup |
| Memory bloat after many jobs | LangChain holding refs | Worker can be restarted via `--max-jobs` |
| Workers don't pick up jobs | Worker watching wrong queue name | `rq worker default` (or specify) |
| `Connection refused` for Qdrant | Qdrant not running | `docker compose ps` |

---

## 12. Main takeaways

- A **worker function** is just a regular Python function.
- For RAG: refactor [[11 - Building the Retrieval (chat.py)|Section 8's chat.py]] into a `process_query(query) -> str` function.
- **Module-level setup** (OpenAI client, vector store) runs once per worker process.
- **Body** runs once per job.
- The function **returns** instead of prints — the return value is what the polling route reads.
- Worker code must `load_dotenv()` before importing things that need `OPENAI_API_KEY`.
- **Same function signature** RQ stores: `(module.func_name, args, kwargs)`.
- If the function raises, RQ marks the job failed but the worker keeps running.

---

## 13. Things I still want to figure out

- For **multi-turn conversations** in the async pattern, how to thread history?
- How to **stream tokens** from a worker back to the user (WebSockets? polling chunks?)?
- For **shared state** across workers (e.g., cache), what's the right pattern?
- How to **deploy** the worker in production (Docker container? systemd service?)?
- What's the cost-per-job tracking pattern for billing?

---

## 14. Things to dig into

- **RQ jobs API**: https://python-rq.org/docs/jobs/
- **RQ worker docs**: https://python-rq.org/docs/workers/
- **Hands-on**: in a Python REPL, `from queues.worker import process_query; print(process_query("test query"))` — verify it works synchronously before testing async.

---

## 15. Next up in this section

The worker function is defined. Now build the producer side — FastAPI server:

- [ ] [[06 - Setting up FastAPI Server]] — web server scaffold.
- [ ] [[07 - The Chat Route - Enqueueing Jobs]] — POST route that enqueues `process_query`.
- [ ] [[08 - The Get Result Route - Fetching Job Status]] — GET route that polls.
- [ ] [[09 - Running RQ Workers in Parallel]] — start workers, demo end-to-end.

---

## Related
- [[04 - Installing RQ and Building the Queue Client]] — the queue this connects to.
- [[11 - Building the Retrieval (chat.py)]] — the function this is refactored from.
- [[07 - The Chat Route - Enqueueing Jobs]] — what enqueues this function.

## Sources
- [RQ jobs API](https://python-rq.org/docs/jobs/)
- [RQ workers](https://python-rq.org/docs/workers/)
- [LangChain Qdrant integration](https://python.langchain.com/docs/integrations/vectorstores/qdrant/)
