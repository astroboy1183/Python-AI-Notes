---
title: Running the Graph
date: 2026-05-29
source: "Section 11 / Lecture 7"
type: lecture-notes
status: in-progress
section: "Section 11: Building Agentic Workflows with LangGraph"
tags:
  - langgraph
  - invoke
  - state
  - hands-on
related:
  - "[[06 - Adding Edges and Compiling the Graph]]"
  - "[[08 - Adding Real LLM Support]]"
---

# Running the Graph

> [!abstract] TL;DR
> Run a compiled graph with **`graph.invoke(initial_state)`**. The initial state for the chatbot is a single human message: `{"messages": ["Hi, my name is Jayanth"]}`. `invoke` returns the **final state**, which I print. Watching the prints reveals the state **accumulating** as it flows: the chatbot node sees one message (the human's), appends its own; the sample node then sees **two** messages and appends a third; the final state holds **all three** — original + chatbot + sample. This is the `add_messages` reducer doing its job at runtime: each node reads the current state, adds to it, and passes the grown state onward.

> [!info] Where this fits
> Seventh note of **Section 11**. The graph is built and compiled (from [[06 - Adding Edges and Compiling the Graph]]); now I invoke it and confirm the state lifecycle works. [[08 - Adding Real LLM Support]] swaps the static messages for a real LLM call.

---

## 1. Invoking the graph

```python
initial_state = {"messages": ["Hi, my name is Jayanth"]}

updated_state = graph.invoke(initial_state)

print("This is the updated state:", updated_state)
```

- Pass the **initial state** to `invoke`.
- It runs the whole graph (`START → chatbot → sample_node → END`).
- It returns the **final updated state**.

```
graph.invoke( {messages: [Human("Hi, my name is Jayanth")]} )
        │
        ▼  (runs all nodes in edge order)
   final state  ◄── printed
```

---

## 2. Running it

```bash
cd langgraph_learning
python chat.py
```

To make the cluttered message output readable, a couple of `\n` newlines in the prints help separate each node's view of the state.

---

## 3. Watching the state grow

This is the payoff — the prints show the state **accumulating** node by node.

### Inside the `chatbot` node
State has **one** message (the human's):

```
We are inside the chatbot node. State:
    messages = [ HumanMessage("Hi, my name is Jayanth") ]
```

The chatbot then returns its message, which gets appended.

### Inside the `sample_node`
State now has **two** messages:

```
We are in the sample node. State:
    messages = [
        HumanMessage("Hi, my name is Jayanth"),
        "Hi, this is a message from the chatbot node",   ← added by chatbot
    ]
```

The sample node returns its message, appended.

### The final updated state
Holds **three** messages:

```
This is the updated state:
    messages = [
        HumanMessage("Hi, my name is Jayanth"),          ← original
        "Hi, this is a message from the chatbot node",   ← from chatbot
        "Sample message, appended",                      ← from sample_node
    ]
```

---

## 4. The accumulation, visualised

```
START
  │  state: [H]
  ▼
┌─────────┐
│ chatbot │  sees [H]          → returns ["chatbot msg"]
└─────────┘  reducer appends   → state: [H, chatbot]
  │
  ▼
┌─────────────┐
│ sample_node │  sees [H, chatbot]   → returns ["sample msg"]
└─────────────┘  reducer appends     → state: [H, chatbot, sample]
  │
  ▼
END
   final state: [H, chatbot, sample]
```

`H` = the human message. Each node **reads the current state, adds to it, and passes the grown state on.** Nothing is lost; the conversation builds up — exactly the behaviour the `add_messages` reducer was set up for in [[04 - Creating the State and Graph Builder]].

---

## 5. What this proves

- The graph executes in the **edge order** I defined.
- State is the **only channel** between nodes — each sees what the previous added.
- The reducer's **append** semantics work at runtime, not just in theory.
- `invoke` returns the **complete final state**.

The mechanics are now fully wired and verified. The only thing "fake" is that nodes return static strings instead of doing real work — fixed next.

---

## 6. Common gotchas

> [!warning] Invocation issues

| Symptom | Cause | Fix |
|---|---|---|
| `invoke` on the builder fails | Forgot to compile | Use the compiled `graph`, not `graph_builder` |
| Messages overwrite instead of grow | Missing `add_messages` annotation | Annotate `messages` in the state |
| Output is an unreadable blob | No formatting | Add `\n` in prints, or pretty-print |
| `KeyError: messages` | Initial state shape wrong | Pass `{"messages": [...]}` |
| Nodes run in wrong order | Edges mis-wired | Recheck `add_edge` order |

---

## 7. Main takeaways

- Run with `graph.invoke(initial_state)`; it returns the **final state**.
- Initial state for a chat is `{"messages": ["..."]}`.
- The state **accumulates**: chatbot sees 1 message, sample node sees 2, final has 3.
- Each node **reads → adds → passes on** the grown state.
- This confirms the **`add_messages` reducer** appends correctly at runtime.
- State is the **sole communication channel** between nodes.
- Add `\n` in prints to keep the output legible.

---

## 8. Things I still want to figure out

- Can I **stream** node outputs as they happen (instead of one final blob)?
- How do I pass a proper **`HumanMessage`** object vs a raw string?
- What does `invoke` return if a node **raises** mid-graph?
- Is there an **async** `ainvoke`?

---

## 9. Things to dig into

- **`graph.stream(...)`** — streaming intermediate state.
- **LangChain message types** — `HumanMessage`, `AIMessage`, `SystemMessage`.
- **`graph.invoke` config** — recursion limits, callbacks.

---

## 10. Next up in this section

- [ ] [[08 - Adding Real LLM Support]] — replace the static node message with an actual LLM call.

---

## Related
- [[06 - Adding Edges and Compiling the Graph]] — building the graph that's invoked here.
- [[04 - Creating the State and Graph Builder]] — the reducer that makes accumulation work.
- [[08 - Adding Real LLM Support]] — making the chatbot node real.

## Sources
- [LangGraph quickstart](https://langchain-ai.github.io/langgraph/)
