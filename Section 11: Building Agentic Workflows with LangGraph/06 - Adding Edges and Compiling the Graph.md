---
title: Adding Edges and Compiling the Graph
date: 2026-05-29
source: "Section 11 / Lecture 6"
type: lecture-notes
status: in-progress
section: "Section 11: Building Agentic Workflows with LangGraph"
tags:
  - langgraph
  - edges
  - start-end
  - compile
  - hands-on
related:
  - "[[05 - Coding the Nodes]]"
  - "[[07 - Running the Graph]]"
---

# Adding Edges and Compiling the Graph

> [!abstract] TL;DR
> Edges define **execution order**. Import the two special markers `START` and `END` from `langgraph.graph` — they tell the graph where to begin and where to stop. Then wire the flow with `graph_builder.add_edge(...)`: `add_edge(START, "chatbot")`, `add_edge("chatbot", "sample_node")`, `add_edge("sample_node", END)`. That's three edges forming `START → chatbot → sample_node → END`. Finally, **compile** the builder into a runnable graph: `graph = graph_builder.compile()`. The compiled `graph` is the object I invoke (next note). Add a `print` in each node to watch the state flow through in order.

> [!info] Where this fits
> Sixth note of **Section 11**. Nodes exist (from [[05 - Coding the Nodes]]); now I connect them with edges and compile. [[07 - Running the Graph]] invokes the compiled graph and watches the state accumulate.

---

## 1. What edges do

> An **edge is a connection between nodes** — it defines which node runs first, then what, then what.

Nodes are isolated until edges wire them into a sequence. Edges are how I encode the flowchart's arrows.

---

## 2. The special markers: START and END

```python
from langgraph.graph import START, END
```

These two are **predefined, special** nodes:

| Marker | Meaning |
|---|---|
| `START` | The virtual entry point — where execution begins |
| `END` | The virtual exit point — where execution stops |

They aren't functions I write; they're built-in anchors. Every graph needs an edge **from `START`** (so it knows where to begin) and an edge **to `END`** (so it knows where to finish).

---

## 3. Adding edges

```python
graph_builder.add_edge(START, "chatbot")
graph_builder.add_edge("chatbot", "sample_node")
graph_builder.add_edge("sample_node", END)
```

Read each as "from → to":

```
START  ──►  chatbot  ──►  sample_node  ──►  END
        edge 1       edge 2          edge 3
```

Three edges. Note that edges reference nodes **by the names** registered in `add_node` — this is why matching names matter (from [[05 - Coding the Nodes]]).

So the flow:
1. `START` hands the initial state to `chatbot`.
2. `chatbot` appends its message, passes state to `sample_node`.
3. `sample_node` appends its message, passes state to `END`.
4. `END` — done; the final state is returned.

---

## 4. Print statements to watch the flow

To *see* the state move through, drop a print in each node:

```python
def chatbot(state: State):
    print("We are inside the chatbot node. State right now:", state)
    return {"messages": ["Hi, this is a message from the chatbot node"]}

def sample_node(state: State):
    print("We are in the sample node. State right now:", state)
    return {"messages": ["Sample message, appended"]}
```

When run, these reveal the state **growing** as it passes node to node (demonstrated in [[07 - Running the Graph]]).

---

## 5. Compiling the graph

The builder isn't runnable on its own — it has to be **compiled** into a graph:

```python
graph = graph_builder.compile()
```

```
graph_builder  ──compile()──►  graph   (runnable, invokable)
 (has nodes,                    (frozen, validated workflow)
  edges)
```

`compile()` validates the structure (e.g. reachable from START, leads to END) and returns the **runnable graph** object. That `graph` is what I `invoke` in the next note.

> [!tip] Compile is also where validation happens
> If an edge points at a node that doesn't exist, or the graph can't reach END, errors surface at `compile()` time — before I ever run it. It's a useful structural sanity check.

---

## 6. Full code so far

```python
# chat.py
from typing_extensions import TypedDict
from typing import Annotated

from langgraph.graph import StateGraph, START, END
from langgraph.graph.message import add_messages


class State(TypedDict):
    messages: Annotated[list, add_messages]


graph_builder = StateGraph(State)


def chatbot(state: State):
    print("We are inside the chatbot node. State:", state)
    return {"messages": ["Hi, this is a message from the chatbot node"]}


def sample_node(state: State):
    print("We are in the sample node. State:", state)
    return {"messages": ["Sample message, appended"]}


graph_builder.add_node("chatbot", chatbot)
graph_builder.add_node("sample_node", sample_node)

graph_builder.add_edge(START, "chatbot")
graph_builder.add_edge("chatbot", "sample_node")
graph_builder.add_edge("sample_node", END)

graph = graph_builder.compile()
```

State ✅ · nodes ✅ · **edges ✅** · **compiled ✅**. The graph is ready to invoke.

---

## 7. The graph, drawn

```
        ┌─────────┐     ┌─────────────┐
START ─►│ chatbot │ ──► │ sample_node │ ──► END
        └─────────┘     └─────────────┘
```

A simple linear graph — exactly the kind of picture LangGraph makes the code mirror.

---

## 8. Common gotchas

> [!warning] Edge / compile issues

| Symptom | Cause | Fix |
|---|---|---|
| Graph never starts | No edge from `START` | `add_edge(START, "first_node")` |
| Graph never ends | No edge to `END` | `add_edge("last_node", END)` |
| `compile()` raises "unknown node" | Edge names a node not registered | Match `add_edge` names to `add_node` |
| Forgot to compile | Tried to `invoke` the builder | `graph = graph_builder.compile()` first |
| Wrong order of execution | Edges wired in wrong sequence | Re-check each `from → to` |

---

## 9. Main takeaways

- **Edges define execution order** — the arrows of the flowchart.
- Import `START` and `END` from `langgraph.graph` — special entry/exit anchors.
- `add_edge(from, to)` wires nodes; reference nodes **by name**.
- Every graph needs an edge **from START** and an edge **to END**.
- `graph_builder.compile()` turns the builder into a **runnable graph**.
- `compile()` also **validates** structure (unreachable nodes, missing END).
- Add `print`s in nodes to watch the state flow.

---

## 10. Things I still want to figure out

- Can a node have **multiple outgoing edges** (parallel branches)?
- How do I make a node loop **back** to an earlier node (for retries)?
- What's the difference between a plain edge and a **conditional edge**? (See [[09 - Conditional Edges]].)
- Can I **visualize** the compiled graph as an image?

---

## 11. Things to dig into

- **LangGraph edges**: https://langchain-ai.github.io/langgraph/concepts/low_level/#edges
- **Graph visualization**: `graph.get_graph().draw_mermaid_png()`.
- **Conditional edges** — branching (next-next note).

---

## 12. Next up in this section

- [ ] [[07 - Running the Graph]] — invoke the compiled graph with an initial state and watch the output.

---

## Related
- [[05 - Coding the Nodes]] — the nodes these edges connect.
- [[07 - Running the Graph]] — invoking the compiled graph.
- [[09 - Conditional Edges]] — branching edges.

## Sources
- [LangGraph edges documentation](https://langchain-ai.github.io/langgraph/concepts/low_level/#edges)
