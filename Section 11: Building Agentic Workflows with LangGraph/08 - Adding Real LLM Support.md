---
title: Adding Real LLM Support
date: 2026-05-29
source: "Section 11 / Lecture 8"
type: lecture-notes
status: in-progress
section: "Section 11: Building Agentic Workflows with LangGraph"
tags:
  - langgraph
  - llm
  - init-chat-model
  - openai
  - hands-on
related:
  - "[[07 - Running the Graph]]"
  - "[[09 - Conditional Edges]]"
---

# Adding Real LLM Support

> [!NOTE]
> **TL;DR**
> Replace the static node message with a real LLM call. Create a model with LangChain's `init_chat_model("gpt-4.1-mini", model_provider="openai")`, then inside the chatbot node call `response = llm.invoke(state["messages"])` and return `{"messages": [response]}`. Because of the `add_messages` reducer, the AI's reply gets appended to the conversation. The model needs an API key, so load it: `from dotenv import load_dotenv; load_dotenv()` at the top (copy the `.env` over from an earlier project). After running, the final state shows the human message **plus** a real `AIMessage` — e.g. *"Hello Jayanth, how can I assist you today?"* — along with token-usage metadata.

> [!NOTE]
> **Where this fits**
> Eighth note of **Section 11**. It upgrades the toy chatbot node ([[07 - Running the Graph]]) into a real LLM call. The final note ([[09 - Conditional Edges]]) adds branching to build an actual decision-making workflow.

---

## 1. The goal

So far the chatbot node returned a hardcoded string. Now it should call an LLM and return the model's actual reply — turning the graph into a genuine chatbot.

---

## 2. Creating the model with `init_chat_model`

LangChain provides a convenience constructor that abstracts over providers:

```python
from langchain.chat_models import init_chat_model

llm = init_chat_model("gpt-4.1-mini", model_provider="openai")
```

| Argument | Meaning |
|---|---|
| `"gpt-4.1-mini"` | Which model to use |
| `model_provider="openai"` | Which provider's API |

> [!TIP]
> **`init_chat_model` vs raw OpenAI client**
> I *could* use the raw `OpenAI().chat.completions.create(...)` client inside a node — that works fine too. But `init_chat_model` returns a LangChain chat model whose `.invoke()` accepts the message list straight from state and returns a LangChain `AIMessage`, which slots cleanly back into `messages`. Swapping providers later is just changing the two arguments.

---

## 3. The LLM call inside the node

```python
def chatbot(state: State):
    response = llm.invoke(state["messages"])
    return {"messages": [response]}
```

What happens:
1. `state["messages"]` is the full conversation so far.
2. `llm.invoke(...)` sends it to the model and returns an `AIMessage`.
3. Returning `{"messages": [response]}` **appends** that AIMessage (via the `add_messages` reducer).

```
state.messages  ──►  llm.invoke()  ──►  AIMessage  ──►  appended to state.messages
```

The `sample_node` can stay as-is (still appending its static message) — only the chatbot node becomes "real."

---

## 4. Loading the API key

The LLM needs `OPENAI_API_KEY`. Load the `.env` **before** the model is used:

```python
from dotenv import load_dotenv
load_dotenv()
```

The `.env` can be copied from an earlier project:

```bash
cp ../image/.env ./.env
```

```
.env  →  OPENAI_API_KEY=sk-...
```

> [!WARNING]
> **Load env early, keep the key private**
> `load_dotenv()` belongs near the **top** of the file, before the model call runs. And `.env` must be **gitignored** — never commit the key.

---

## 5. Full code

```python
# chat.py
from dotenv import load_dotenv
load_dotenv()

from typing_extensions import TypedDict
from typing import Annotated

from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages
from langchain.chat_models import init_chat_model


class State(TypedDict):
    messages: Annotated[list, add_messages]


llm = init_chat_model("gpt-4.1-mini", model_provider="openai")

graph_builder = StateGraph(State)


def chatbot(state: State):
    response = llm.invoke(state["messages"])
    return {"messages": [response]}


def sample_node(state: State):
    return {"messages": ["Sample message, appended"]}


graph_builder.add_node("chatbot", chatbot)
graph_builder.add_node("sample_node", sample_node)

graph_builder.add_edge(START, "chatbot")
graph_builder.add_edge("chatbot", "sample_node")
graph_builder.add_edge("sample_node", END)

graph = graph_builder.compile()

updated_state = graph.invoke({"messages": ["Hi, my name is Jayanth"]})
print(updated_state)
```

---

## 6. The output

Run it:

```bash
cd langgraph_learning
python chat.py
```

After a short wait (a real network call now), the final state contains a genuine AI reply:

```
updated_state.messages = [
    HumanMessage("Hi, my name is Jayanth"),
    AIMessage("Hello Jayanth, how can I assist you today?"),   ← real LLM output
    "Sample message, appended",
]
```

The `AIMessage` also carries **metadata**: token counts (prompt + completion), cost-relevant usage, model name, etc. The meaningful part is `.content` — the actual reply — but the metadata is handy for tracking spend.

---

## 7. Before vs after

| | Before (note 07) | After (this note) |
|---|---|---|
| chatbot node | returns static string | `llm.invoke(state["messages"])` |
| Output | canned text | real `AIMessage` |
| Network | none | real API call |
| Metadata | none | tokens, usage, model |
| Latency | instant | a beat (LLM call) |

The graph structure didn't change at all — only the *inside* of one node. That's the maintainability win: behaviour changes are localized to a node.

---

## 8. Common gotchas

> [!WARNING]
> **LLM-in-node issues**

| Symptom | Cause | Fix |
|---|---|---|
| `AuthenticationError` / key missing | `.env` not loaded or absent | `load_dotenv()` at top; check `.env` |
| `llm.invoke` rejects input | Passed a string, not the message list | Pass `state["messages"]` |
| Reply overwrites history | Missing `add_messages` annotation | Annotate `messages` |
| Wrong/unknown model | Typo or unsupported model id | Use a valid model name |
| Slow / hangs | Real network call | Expected — it's hitting the API |

---

## 9. Main takeaways

- Build the model with `init_chat_model("gpt-4.1-mini", model_provider="openai")`.
- Inside the node: `response = llm.invoke(state["messages"])`, then `return {"messages": [response]}`.
- The `add_messages` reducer **appends** the `AIMessage` to the conversation.
- `load_dotenv()` at the top so `OPENAI_API_KEY` is available; keep `.env` gitignored.
- Output is a real `AIMessage` (`.content`) plus token/usage metadata.
- Only the node's **internals** changed — graph structure stayed identical.
- A node can use `init_chat_model` *or* the raw OpenAI client; both work.

---

## 10. Things I still want to figure out

- How to add a **system prompt** to steer the chatbot node?
- Can I **stream** the LLM tokens through the graph?
- How to read and **log token cost** from the AIMessage metadata systematically?
- Multiple models in one graph — e.g. a cheap model for one node, a strong one for another (foreshadows [[09 - Conditional Edges]]).

---

## 11. Things to dig into

- **`init_chat_model` docs**: https://python.langchain.com/docs/how_to/chat_models_universal_init/
- **LangChain `AIMessage` metadata** — `response_metadata`, `usage_metadata`.
- **System messages** in LangChain chat models.

---

## 12. Next up in this section

- [ ] [[09 - Conditional Edges]] — branch the workflow based on a condition (LLM-as-judge, retry path).

---

## Related
- [[07 - Running the Graph]] — the static version this upgrades.
- [[04 - Creating the State and Graph Builder]] — the reducer that appends the AIMessage.
- [[09 - Conditional Edges]] — adding decision points.

## Sources
- [LangChain init_chat_model](https://python.langchain.com/docs/how_to/chat_models_universal_init/)
