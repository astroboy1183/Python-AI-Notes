---
title: Coding the Nodes
date: 2026-05-29
source: "Section 11 / Lecture 5"
type: lecture-notes
status: in-progress
section: "Section 11: Building Agentic Workflows with LangGraph"
tags:
  - langgraph
  - nodes
  - add-node
  - state
  - hands-on
related:
  - "[[04 - Creating the State and Graph Builder]]"
  - "[[06 - Adding Edges and Compiling the Graph]]"
---

# Coding the Nodes

> [!abstract] TL;DR
> A node is **just a function** that takes the current `state` and returns a (partial) state. Define `def chatbot(state: State)` that returns `{"messages": ["Hi, this is a message from the chatbot node"]}`. Because the state's `messages` key uses the `add_messages` reducer, whatever the node returns gets **appended** to the existing messages — it doesn't overwrite them. But the builder doesn't know about a function until I **register** it: `graph_builder.add_node("chatbot", chatbot)`. The first arg is the node's name (any string; best practice = match the function name), the second is the function. Add a second node (`sample_node`) the same way and the graph now has two nodes — ready to be wired with edges.

> [!info] Where this fits
> Fifth note of **Section 11**. The state and builder exist (from [[04 - Creating the State and Graph Builder]]); now I write the node functions and register them. [[06 - Adding Edges and Compiling the Graph]] connects them and compiles.

---

## 1. A node is a function

> A **node is just a function** that does a specific task.

The signature: it receives the **current state** and returns a state update.

```python
def chatbot(state: State):
    # read state, do work, return an updated state
    ...
```

For now, no LLM call — just return a static message to see the mechanics. (The real LLM call comes in [[08 - Adding Real LLM Support]].)

```python
def chatbot(state: State):
    return {
        "messages": ["Hi, this is a message from the chatbot node"],
    }
```

---

## 2. What "return" means with the `add_messages` reducer

This is the subtle, important part. The node returns a dict with a `messages` list. Because the state defined `messages` as `Annotated[list, add_messages]`, the returned list is **appended** to whatever was already there — not substituted.

```
initial state:
    messages = [ Human("hey there") ]

chatbot node returns:
    { "messages": ["Hi, this is a message from the chatbot node"] }

state AFTER the node (reducer appends):
    messages = [
        Human("hey there"),                              ← original
        "Hi, this is a message from the chatbot node",   ← appended
    ]
```

> [!important] The node returns only what it wants to add
> I don't reconstruct the whole `messages` list inside the node. I return **just the new message(s)**, and the `add_messages` reducer merges them onto the existing list. That's the entire point of the annotation from [[04 - Creating the State and Graph Builder]].

---

## 3. Registering a node on the builder

Writing the function isn't enough — the **graph builder has no idea it exists** until I register it:

```python
graph_builder.add_node("chatbot", chatbot)
```

| Argument | Meaning |
|---|---|
| `"chatbot"` (1st) | The node's **name** — any string |
| `chatbot` (2nd) | The **function** to run for that node |

The name can be anything (`"xyz"` would work), but **best practice is to match the function name** so the graph is readable.

```
graph_builder.add_node("chatbot", chatbot)
                          │          └─ the code (function)
                          └─ the node's name (used by edges later)
```

The name matters because **edges refer to nodes by name** (next note) — so `"chatbot"` is how I'll say "start at the chatbot" or "go to the chatbot."

---

## 4. Adding a second node

Nodes compose — add as many as the workflow needs. A second, sample node:

```python
def sample_node(state: State):
    return {
        "messages": ["Sample message, appended"],
    }

graph_builder.add_node("sample_node", sample_node)
```

Now the graph has **two registered nodes**: `chatbot` and `sample_node`. They aren't connected yet — that's what edges do.

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


def chatbot(state: State):
    return {"messages": ["Hi, this is a message from the chatbot node"]}


def sample_node(state: State):
    return {"messages": ["Sample message, appended"]}


graph_builder.add_node("chatbot", chatbot)
graph_builder.add_node("sample_node", sample_node)

# edges + compile  →  next note
```

State ✅ · builder ✅ · **nodes ✅**. Still missing: edges and compilation.

---

## 6. The node contract — visualised

```
        ┌─────────────────────────────┐
state ─►│  node(state) -> state_update │─► (reducer merges into state)
        └─────────────────────────────┘
           reads          returns
        current state    what to add
```

Every node follows the same contract: **state in, state-update out.** That uniformity is what lets LangGraph chain arbitrary nodes together — they all speak "state."

---

## 7. Common gotchas

> [!warning] Node issues

| Symptom | Cause | Fix |
|---|---|---|
| Node "doesn't run" | Function written but not registered | `add_node(name, fn)` |
| Returned messages overwrite history | State key missing `add_messages` | Annotate `messages` with the reducer |
| Edge can't find the node | Name typo in `add_node` vs `add_edge` | Match the names exactly |
| Returned a bare value, not a dict | Node must return a state-shaped dict | Return `{"messages": [...]}` |

---

## 8. Main takeaways

- A **node is a function**: `def node(state: State) -> dict`.
- It **reads** the state and **returns** a state update.
- With the `add_messages` reducer, the returned list is **appended**, not overwritten.
- A node returns **only what it wants to add**, not the full list.
- Register with `graph_builder.add_node("name", fn)` — name first, function second.
- **Match the node name to the function name** for readability.
- Edges reference nodes **by name**, so names matter.
- Add as many nodes as the workflow needs; they connect via edges next.

---

## 9. Things I still want to figure out

- Can a node return **multiple state keys** at once (e.g. `messages` + a flag)?
- What if a node returns a key **not** in the `TypedDict` — error or ignored?
- Can a node be **async**?
- How does a node **read** specific state values it needs (e.g. `state["messages"][-1]`)?

---

## 10. Things to dig into

- **LangGraph nodes**: https://langchain-ai.github.io/langgraph/concepts/low_level/#nodes
- Returning **partial state updates** and how reducers merge them.
- Async nodes and parallel fan-out.

---

## 11. Next up in this section

- [ ] [[06 - Adding Edges and Compiling the Graph]] — connect the nodes with START/END edges and compile.

---

## Related
- [[04 - Creating the State and Graph Builder]] — the state these nodes read/return.
- [[06 - Adding Edges and Compiling the Graph]] — wiring the nodes together.
- [[08 - Adding Real LLM Support]] — replacing the static message with an LLM call.

## Sources
- [LangGraph nodes documentation](https://langchain-ai.github.io/langgraph/concepts/low_level/#nodes)
