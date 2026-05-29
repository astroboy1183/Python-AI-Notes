---
title: Implementing Checkpointing with MongoDBSaver
date: 2026-05-29
source: "Section 12 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 12: Checkpointing Workflows in LangGraph with MongoDB"
tags:
  - langgraph
  - mongodb
  - checkpointing
  - thread-id
  - streaming
  - hands-on
related:
  - "[[02 - Setting up MongoDB with Docker Compose]]"
  - "[[01 - The State Persistence Problem]]"
---

# Implementing Checkpointing with MongoDBSaver

> [!abstract] TL;DR
> Wire MongoDB into the graph as a checkpointer. Install `pymongo langgraph langgraph-checkpoint-mongodb`, import `MongoDBSaver`, and compile the graph **inside** the saver's connection context: `with MongoDBSaver.from_conn_string(uri) as checkpointer: graph = graph_builder.compile(checkpointer=checkpointer)`. Connection URI: `mongodb://admin:admin@localhost:27017` (matching the Docker creds; **no trailing slash**, and don't close the connection before you're done using the graph — both bite). Crucially, a checkpointed graph needs a **`thread_id`** at invoke time: `graph.invoke(state, config={"configurable": {"thread_id": "Jayanth"}})`. State is **scoped per thread** — like a table keyed by thread. Run with `thread_id="Jayanth"`, say "my name is Jayanth," and a later run with the same thread remembers it; switch to `thread_id="John"` and it's a clean slate. Thread ID = usually the **user ID**, so users never see each other's history. For readable output, **stream** with `stream_mode="values"` and `pretty_print()` the last message.

> [!info] Where this fits
> Third and final note of **Section 12**. It completes the persistence story from [[01 - The State Persistence Problem]] using the MongoDB stood up in [[02 - Setting up MongoDB with Docker Compose]].

---

## 1. Starting point

Copy the working chatbot to a new file to preserve the original:

```bash
cp chat.py chat_checkpoint.py
```

Then simplify: **remove the `sample_node`** (it was only ever a demo). The graph becomes a clean single node:

```
START → chatbot → END
```

Recap of what `chat_checkpoint.py` does: load env, init the LLM, define a `messages` state, the `chatbot` node does `llm.invoke(state["messages"])`, one-node graph, invoke with a query. Now add checkpointing.

---

## 2. Install the packages

```bash
pip install pymongo langgraph langgraph-checkpoint-mongodb
pip freeze > requirements.txt
```

| Package | Role |
|---|---|
| `pymongo` | MongoDB driver |
| `langgraph` | the graph framework |
| `langgraph-checkpoint-mongodb` | the MongoDB checkpointer (`MongoDBSaver`) |

---

## 3. Import the saver

```python
from langgraph.checkpoint.mongodb import MongoDBSaver
```

`MongoDBSaver` is the checkpointer — it knows how to read/write graph state to MongoDB.

---

## 4. Compile the graph *with* a checkpointer

A checkpointed graph is just a normal compile with one extra argument: `checkpointer=...`. The saver is created from a **connection string** and used as a **context manager**:

```python
MONGODB_URI = "mongodb://admin:admin@localhost:27017"

def compile_graph_with_checkpointer(checkpointer):
    graph = graph_builder.compile(checkpointer=checkpointer)
    return graph
```

The connection string breaks down as:

```
mongodb://admin:admin@localhost:27017
          │     │     │         │
          user  pass  host      port
```

— matching the Docker credentials and port from [[02 - Setting up MongoDB with Docker Compose]].

> [!warning] Two bugs that bite here
> **Bug 1 — trailing slash / wrong URI.** Adding a stray `/...` or a slash where none belongs causes `Authentication failed`. The correct form is `mongodb://admin:admin@localhost:27017` (no trailing slash). If auth fails, the URI is the first thing to check.
>
> **Bug 2 — `Cannot use MongoDB client after close`.** If the `with MongoDBSaver(...)` block creates the graph and then *exits* before the graph is invoked, the Mongo connection is already closed when invoke runs. **Fix:** keep everything that uses the graph **inside** the `with` block — open connection → build graph → use graph → (block exits, connection closes). Don't compile inside the `with` and invoke outside it.

---

## 5. The correct structure — everything inside the `with`

```python
with MongoDBSaver.from_conn_string(MONGODB_URI) as checkpointer:
    graph = graph_builder.compile(checkpointer=checkpointer)

    config = {"configurable": {"thread_id": "Jayanth"}}

    result = graph.invoke(
        {"messages": ["Hi, my name is Jayanth"]},
        config,
    )
    print(result)
# connection closes here, after the graph has been used
```

```
open connection ─► build graph (with checkpointer) ─► invoke graph ─► close connection
└────────────────────────  all inside the `with`  ───────────────────────┘
```

The compiled graph still has the **same API** as before — `.invoke()`, `.stream()`. Checkpointing is transparent to how I call it; the only new requirement is the config (next section).

---

## 6. The `thread_id` — scoping state

A checkpointed graph can be invoked **many times**, and it needs to know *which* conversation each call belongs to. That's the **`thread_id`**, passed via a config object as the **second argument** to `invoke`:

```python
config = {"configurable": {"thread_id": "Jayanth"}}
graph.invoke(state, config)
```

| Argument | What it is |
|---|---|
| 1st: `state` | the input state (the new message) |
| 2nd: `config` | `{"configurable": {"thread_id": "..."}}` |

> [!important] State is scoped to a thread, not global
> Think of the checkpoint store as a **table keyed by `thread_id`**. All state for `thread_id="Jayanth"` is stored under "Jayanth"; messages from another thread never mix in. Invoke with `"Jayanth"` and only Jayanth's history is loaded.

```
MongoDB (checkpoints)
├── thread_id "Jayanth"  ──► [ Human("my name is Jayanth"), AI(...), ... ]
└── thread_id "John"     ──► [ ... separate history ... ]
```

---

## 7. Proving persistence across runs

### Run 1 (thread "Jayanth") — tell it my name
```python
config = {"configurable": {"thread_id": "Jayanth"}}
graph.invoke({"messages": ["Hi, my name is Jayanth"]}, config)
# → "Hello Jayanth, how can I assist you today?"
```

### Run 2 (separate program run, same thread) — ask my name
```python
graph.invoke({"messages": ["What is my name?"]}, config)
# → "Your name is Jayanth. How can I help you further?"
```

It **remembers** — because run 1's state was checkpointed to Mongo under "Jayanth" and reloaded in run 2. Compare this to [[01 - The State Persistence Problem]], where the exact same second question returned "I don't know your name." The only difference is the checkpointer.

### Build up more history (same thread)
```python
graph.invoke({"messages": ["I am learning LangGraph"]}, config)
graph.invoke({"messages": ["What am I learning?"]}, config)
# → "You mentioned you are learning LangGraph."
```

The full history accumulates in Mongo and is replayed each run — that's why it has context.

---

## 8. Switching threads = switching context

Change the `thread_id` to `"John"` and the slate is clean:

```python
config = {"configurable": {"thread_id": "John"}}

graph.invoke({"messages": ["What am I learning?"]}, config)
# → "Could you clarify what you mean?"   (no history for John)

graph.invoke({"messages": ["What is my name?"]}, config)
# → "I don't have access to your personal information."

graph.invoke({"messages": ["My name is John"]}, config)
graph.invoke({"messages": ["What is my name?"]}, config)
# → "Your name is John."
```

Switch back to `"Jayanth"` and it still says "Your name is Jayanth." Each thread keeps its **own isolated history**.

> [!tip] Thread ID = user ID
> In a real multi-user app, set `thread_id` to the **user's ID**. That guarantees each user only ever sees their own conversation — no cross-contamination between users. (For multiple conversations per user, combine user + conversation IDs.)

---

## 9. Readable output: stream instead of invoke

`invoke` returns the whole final state, which is hard to read. **Streaming** the graph and pretty-printing the last message is much cleaner:

```python
for chunk in graph.stream(
    {"messages": ["What is my name?"]},
    config,
    stream_mode="values",
):
    chunk["messages"][-1].pretty_print()
```

| Piece | Purpose |
|---|---|
| `graph.stream(...)` | yields state as it progresses (instead of one final blob) |
| `stream_mode="values"` | each chunk is the **full state values** at that step |
| `chunk["messages"][-1]` | the **latest** message in that chunk |
| `.pretty_print()` | nicely formats the message (role + content) |

Same checkpointing behaviour — just a friendlier way to see the output.

---

## 10. Full code (assembled)

```python
# chat_checkpoint.py
from dotenv import load_dotenv
load_dotenv()

from typing_extensions import TypedDict
from typing import Annotated

from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langchain.chat_models import init_chat_model
from langgraph.checkpoint.mongodb import MongoDBSaver


class State(TypedDict):
    messages: Annotated[list, add_messages]


llm = init_chat_model("gpt-4.1-mini", model_provider="openai")

graph_builder = StateGraph(State)


def chatbot(state: State):
    response = llm.invoke(state["messages"])
    return {"messages": [response]}


graph_builder.add_node("chatbot", chatbot)
graph_builder.add_edge(START, "chatbot")
graph_builder.add_edge("chatbot", END)


MONGODB_URI = "mongodb://admin:admin@localhost:27017"

with MongoDBSaver.from_conn_string(MONGODB_URI) as checkpointer:
    graph = graph_builder.compile(checkpointer=checkpointer)

    config = {"configurable": {"thread_id": "Jayanth"}}

    for chunk in graph.stream(
        {"messages": ["What is my name?"]},
        config,
        stream_mode="values",
    ):
        chunk["messages"][-1].pretty_print()
```

---

## 11. Common gotchas

> [!warning] Checkpointing issues

| Symptom | Cause | Fix |
|---|---|---|
| `Authentication failed` | Bad URI (trailing slash, wrong creds) | Use `mongodb://admin:admin@localhost:27017`, match Docker creds |
| `Cannot use MongoDB client after close` | Used the graph outside the `with` block | Keep build + invoke **inside** the `with` |
| No memory across runs | Missing `thread_id` / using different threads | Pass a consistent `config` thread ID |
| Users see each other's chats | Shared/static `thread_id` | Use the **user ID** as thread ID |
| Output unreadable | `invoke` dumps full state | `stream` + `stream_mode="values"` + `pretty_print()` |
| Connection refused | Mongo container not running | `docker ps` / `docker compose up -d` |

---

## 12. Main takeaways

- Install `pymongo langgraph langgraph-checkpoint-mongodb`; import `MongoDBSaver`.
- Create the saver with `MongoDBSaver.from_conn_string(uri)` as a **context manager**.
- Compile with `graph_builder.compile(checkpointer=checkpointer)`.
- URI: `mongodb://admin:admin@localhost:27017` — **no trailing slash**.
- Keep graph build **and** use **inside** the `with` (else "client after close").
- A checkpointed graph needs a **`thread_id`** via `config={"configurable": {"thread_id": ...}}`.
- State is **scoped per thread** — like a table keyed by thread ID.
- Same thread → remembers across runs; different thread → clean slate.
- **Thread ID = user ID** keeps users' histories isolated.
- **Stream** with `stream_mode="values"` + `pretty_print()` for readable output.
- The graph API (`invoke`/`stream`) is otherwise unchanged.

---

## 13. Things I still want to figure out

- How to **list or delete** a thread's history programmatically?
- Can I **trim** old messages so context doesn't grow unbounded (and costly)?
- How does this interact with **conditional edges / multi-node** graphs — is every node's state checkpointed?
- What does the stored **checkpoint document** look like in Mongo?
- **Async** variant (`AsyncMongoDBSaver`) for a FastAPI server?

---

## 14. Things to dig into

- **LangGraph MongoDB checkpointer**: https://langchain-ai.github.io/langgraph/reference/checkpoints/
- **Persistence concepts** (threads, checkpoints): https://langchain-ai.github.io/langgraph/concepts/persistence/
- **Hands-on**: inspect the checkpoints in Mongo (Compass/mongosh); try user+conversation composite thread IDs; wire this into a FastAPI route.

---

## 15. Section wrap-up

Checkpointing closes the loop on LangGraph: state now **survives across runs**, scoped per thread/user, stored durably in MongoDB. Combined with Sections 11's nodes/edges/conditional-edges, this is everything needed to build a stateful, multi-user agentic workflow — the in-memory limitation from [[01 - The State Persistence Problem]] is gone.

---

## Related
- [[01 - The State Persistence Problem]] — the problem this solves.
- [[02 - Setting up MongoDB with Docker Compose]] — the database backing it.

## Sources
- [LangGraph checkpointers reference](https://langchain-ai.github.io/langgraph/reference/checkpoints/)
- [LangGraph persistence](https://langchain-ai.github.io/langgraph/concepts/persistence/)
