---
title: Creating the State and Graph Builder
date: 2026-05-29
source: "Section 11 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 11: Building Agentic Workflows with LangGraph"
tags:
  - langgraph
  - state
  - typeddict
  - add-messages
  - stategraph
  - hands-on
related:
  - "[[03 - Installing LangGraph & Core Concepts]]"
  - "[[05 - Coding the Nodes]]"
---

# Creating the State and Graph Builder

> [!abstract] TL;DR
> First two building blocks of any LangGraph app. **State** is a `TypedDict` describing the data that flows through the graph — for a chatbot, the key that matters is `messages`, typed as `Annotated[list, add_messages]`. That `add_messages` annotation is a **reducer**: instead of *overwriting* `messages` when a node returns it, LangGraph **appends** to the list. So the conversation grows — user query first, then every node's output gets tacked on. With the state schema defined, build a **`StateGraph`**: `graph_builder = StateGraph(State)`. That builder is what I'll hang nodes and edges off of in the next notes.

> [!info] Where this fits
> Fourth note of **Section 11**, and the first hands-on step. Sets up `chat.py` with a state and a graph builder. [[05 - Coding the Nodes]] adds the nodes; [[06 - Adding Edges and Compiling the Graph]] wires and compiles.

---

## 1. Project setup

A fresh folder and file:

```
langgraph_learning/
└── chat.py
```

Everything for the basic chatbot lives in `chat.py`.

---

## 2. Defining the State

State is a **typed dictionary** — a `TypedDict`. It declares the shape of the data flowing through the graph.

```python
from typing_extensions import TypedDict
from typing import Annotated
from langgraph.graph.message import add_messages

class State(TypedDict):
    messages: Annotated[list, add_messages]
```

A state *could* hold anything — `x`, `input`, `output`, whatever the workflow needs. But for a chatbot the meaningful key is **`messages`**: the running conversation.

| Piece | Meaning |
|---|---|
| `TypedDict` | A dict with a declared, typed shape |
| `messages` | The conversation — a list of messages |
| `Annotated[list, add_messages]` | A list, *plus* a rule for how updates to it are merged |

---

## 3. The crucial bit: `add_messages` is a reducer

`Annotated[list, add_messages]` is the part that makes a chatbot work. The annotation attaches a **reducer** — a function that decides how a node's returned value is combined with the existing state.

Without a reducer, returning `messages` would **replace** the whole list. With `add_messages`, returning `messages` **appends** to it.

```
default behaviour:      new value  REPLACES  old value
add_messages reducer:   new value  APPENDED TO  old value
```

So the conversation **accumulates**:

```
initial messages:  [ Human("hi, what is the time?") ]
node returns:       [ AI("It's 3pm") ]
after reducer:      [ Human("hi, what is the time?"), AI("It's 3pm") ]   ← appended, not replaced
```

> [!important] Why append, not overwrite
> A conversation must keep its history. If each node *replaced* `messages`, every turn would wipe the previous messages and the model would lose all context. `add_messages` is what lets the list grow turn by turn — exactly what a chat needs.

> [!tip] Reducers are a general mechanism
> `add_messages` is a built-in reducer specialised for message lists (it also handles message IDs and updates intelligently). Other state keys can use other reducers — or none (default overwrite). The annotation pattern `Annotated[type, reducer]` is how LangGraph knows how to merge updates for each key.

---

## 4. Building the graph builder

With the state schema in hand, create a **`StateGraph`** — the object I attach nodes and edges to:

```python
from langgraph.graph import StateGraph

graph_builder = StateGraph(State)
```

I hand `StateGraph` my `State` schema, and it gives back a **graph builder**. Read it as: *"Hey StateGraph, here's my state shape — give me a builder."*

```
StateGraph(State)  ──►  graph_builder
                         │
                         ├─ .add_node(...)     (next note)
                         ├─ .add_edge(...)     (note 06)
                         └─ .compile()         (note 06)
```

---

## 5. Full code so far

```python
# chat.py
from typing_extensions import TypedDict
from typing import Annotated

from langgraph.graph import StateGraph
from langgraph.graph.message import add_messages


class State(TypedDict):
    messages: Annotated[list, add_messages]


graph_builder = StateGraph(State)

# nodes, edges, compile  →  next notes
```

At this point: **state is defined, the builder is ready.** Nothing runs yet — nodes and edges come next.

---

## 6. Why a TypedDict (not a plain dict)?

| Option | Trade-off |
|---|---|
| Plain `dict` | Works, but no shape guarantees, no editor autocomplete |
| **`TypedDict`** | Declares keys + types; LangGraph reads it to know the schema; editor help | 
| Pydantic model | Even stricter (validation) — also supported by LangGraph |

`TypedDict` is the sweet spot for learning: typed enough to be safe and self-documenting, light enough to stay simple.

---

## 7. Main takeaways

- **State** = a `TypedDict` describing the data flowing through the graph.
- For a chatbot, the key is `messages: Annotated[list, add_messages]`.
- `add_messages` is a **reducer**: returned messages get **appended**, not overwritten.
- Appending is what preserves conversation history across nodes.
- Build the graph with `graph_builder = StateGraph(State)`.
- The builder is the handle for `.add_node`, `.add_edge`, `.compile` (next notes).
- `TypedDict` gives shape + safety without the weight of full validation.

---

## 8. Things I still want to figure out

- What other **built-in reducers** exist besides `add_messages`?
- Can I write a **custom reducer** for a non-message key?
- For keys *without* an annotation, is the behaviour always overwrite?
- When does a **Pydantic** state make more sense than `TypedDict`?

---

## 9. Things to dig into

- **LangGraph state & reducers**: https://langchain-ai.github.io/langgraph/concepts/low_level/#state
- **`add_messages` source/behaviour** — how it dedupes by message ID.
- **`MessagesState`** — LangGraph's prebuilt state with `messages` already set up.

---

## 10. Next up in this section

- [ ] [[05 - Coding the Nodes]] — write the node functions and register them on the builder.

---

## Related
- [[03 - Installing LangGraph & Core Concepts]] — the nodes/edges/state vocabulary.
- [[05 - Coding the Nodes]] — the functions that read and return this state.

## Sources
- [LangGraph state concepts](https://langchain-ai.github.io/langgraph/concepts/low_level/#state)
