---
title: Installing LangGraph & Core Concepts
date: 2026-05-29
source: "Section 11 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 11: Building Agentic Workflows with LangGraph"
tags:
  - langgraph
  - installation
  - nodes
  - edges
  - state
  - foundations
  - hands-on
related:
  - "[[02 - What is LangGraph]]"
  - "[[04 - Creating the State and Graph Builder]]"
---

# Installing LangGraph & Core Concepts

> [!abstract] TL;DR
> Install with `pip install -U langgraph` (assuming LangChain is already present), then freeze into `requirements.txt`. LangGraph offers **prebuilt agents** — e.g. `from langgraph.prebuilt import create_react_agent`, hand it a model + tools + prompt — but the real power is building graphs from three primitives: **Nodes** (just functions, each doing one task), **Edges** (the connections defining flow between nodes), and **State** (a single piece of data that flows through the graph). When I `invoke` a graph, I pass an **initial state** in; it travels node-to-node, each node **reads and returns an updated state**, and I get the **final state** back. That read-modify-return-state loop is the heart of LangGraph.

> [!info] Where this fits
> Third note of **Section 11**. It installs LangGraph and lays out the vocabulary (nodes / edges / state) that the rest of the section builds on. The hands-on construction starts in [[04 - Creating the State and Graph Builder]].

---

## 1. Installation

```bash
pip install -U langgraph
```

`-U` upgrades to the latest. This assumes **LangChain and the usual deps are already installed** from earlier sections. Then freeze:

```bash
pip freeze > requirements.txt
```

Now LangGraph is locked into the project's dependency list.

> [!tip] LangGraph builds on LangChain
> LangGraph isn't a replacement for LangChain — it sits on top of it. The chat-model utilities, message types (`HumanMessage`, `AIMessage`), and tool abstractions all come from LangChain; LangGraph adds the **graph orchestration** layer.

---

## 2. The shortcut: prebuilt agents

LangGraph ships ready-made agents so a basic tool-using agent is one import:

```python
from langgraph.prebuilt import create_react_agent

agent = create_react_agent(
    model="openai:gpt-4.1-mini",
    tools=[search_tool],
    prompt="You are a helpful assistant.",
)
```

Give it a model, tools, and a prompt — done. This is great for a quick start, but it hides the mechanics. To actually *understand* and *customize* workflows, I need the three primitives underneath.

---

## 3. The three primitives

Everything in LangGraph reduces to **nodes, edges, and state**.

```
        ┌──────┐   edge   ┌──────┐   edge   ┌──────┐
state ─►│ node │ ───────► │ node │ ───────► │ node │ ─► final state
        └──────┘          └──────┘          └──────┘
        (function)        (function)        (function)
```

### 3.1 Nodes — functions

> A **node is just a function** that does a specific task.

Examples of what a node might do:
- Get the user input.
- Call a tool.
- Make a call to OpenAI.
- Store something in a database.

Nothing magic — a node is a Python function. (How they're written: [[05 - Coding the Nodes]].)

### 3.2 Edges — connections

> An **edge is a connection between two nodes** — it defines the workflow (what runs after what).

If I have 4 nodes connected in a line, I have 3-4 edges wiring them in order. Edges are what turn a bag of functions into an ordered flow. (Covered in [[06 - Adding Edges and Compiling the Graph]].)

### 3.3 State — the data that flows

> **State is just a piece of data** that travels through the graph.

A state might look like:

```python
state = {
    "input": "...",     # str
    "output": "...",    # str
}
```

State is the shared context every node can read and write. (Defined in [[04 - Creating the State and Graph Builder]].)

---

## 4. How a graph actually runs (the state lifecycle)

This is the key idea. When I `invoke` a graph, I pass an **initial state**. That state then flows through the nodes, each one transforming it:

```
initial state = 1
      │
      ▼
  ┌────────┐   reads 1, does work, returns 2
  │ node A │ ─────────────────────────────────► state = 2
  └────────┘
      │
      ▼
  ┌────────┐   reads 2, does work, returns 3
  │ node B │ ─────────────────────────────────► state = 3
  └────────┘
      │
      ▼
  ┌────────┐   reads 3, does work, returns 4
  │ node C │ ─────────────────────────────────► state = 4
  └────────┘
      │
      ▼
  ┌────────┐   reads 4, returns 4 unchanged
  │ node D │ ─────────────────────────────────► state = 4
  └────────┘
      │
      ▼
 final state = 4   ◄── this is what invoke() returns
```

Step by step:
1. I **create a state** and put my data in it (e.g. the user's input).
2. The state goes to the **first node** as input.
3. That node can **read the state, do work, and return a new/updated state**.
4. The updated state flows to the **next node** — which sees the change.
5. When the graph finishes, I get the **final updated state** back.

> [!important] Nodes communicate only through state
> Nodes don't pass arguments to each other directly. The **only channel** between nodes is the state object. A node reads the current state, modifies it, returns it — and the next node picks up from there. Get the state design right and the whole graph falls into place.

---

## 5. `invoke` — in and out

```python
final_state = graph.invoke(initial_state)
```

- **Input**: the initial state (my starting data).
- **Output**: the final state (after every node has had its turn).

This matches the docs' framing exactly: invoke a graph with an initial state, get the final state back.

---

## 6. Mental model summary

| Primitive | What it is | Analogy |
|---|---|---|
| **Node** | A function doing one task | A station on an assembly line |
| **Edge** | A connection between nodes | The conveyor belt between stations |
| **State** | The data flowing through | The product moving down the line |
| **invoke** | Run the graph on an input | Start the line with raw material |

```
nodes  = what work happens
edges  = in what order
state  = what gets carried along and transformed
```

---

## 7. Main takeaways

- Install: `pip install -U langgraph`, then `pip freeze > requirements.txt`.
- LangGraph **builds on LangChain** — it adds graph orchestration.
- **Prebuilt agents** (`create_react_agent`) exist for a quick start, but learning the primitives matters.
- Three primitives: **Nodes** (functions), **Edges** (connections / flow), **State** (the data).
- **Nodes only communicate via state** — read it, modify it, return it.
- `invoke(initial_state)` runs the graph and returns the **final state**.
- Each node transforms the state; the changes accumulate down the chain.

---

## 8. Things I still want to figure out

- When two nodes write the **same state key**, who wins — last write, or is it merged? (Answer starts in [[04 - Creating the State and Graph Builder]] with reducers/annotations.)
- Does a node **return the whole state** or just the keys it changed?
- What exactly does `create_react_agent` build under the hood?
- How is **state typed** — plain dict, TypedDict, Pydantic?

---

## 9. Things to dig into

- **LangGraph low-level concepts**: https://langchain-ai.github.io/langgraph/concepts/low_level/
- **Prebuilt `create_react_agent`**: the docs' quickstart.
- **State reducers / annotations** — how updates merge (next note).

---

## 10. Next up in this section

- [ ] [[04 - Creating the State and Graph Builder]] — define a `TypedDict` state and create a `StateGraph` builder.

---

## Related
- [[02 - What is LangGraph]] — why graphs beat loops.
- [[04 - Creating the State and Graph Builder]] — first hands-on step.
- [[05 - Coding the Nodes]] — nodes as functions, in code.

## Sources
- [LangGraph documentation](https://langchain-ai.github.io/langgraph/)
- [LangGraph low-level concepts](https://langchain-ai.github.io/langgraph/concepts/low_level/)
