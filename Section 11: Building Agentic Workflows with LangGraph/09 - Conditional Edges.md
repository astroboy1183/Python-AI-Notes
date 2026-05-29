---
title: Conditional Edges
date: 2026-05-29
source: "Section 11 / Lecture 9"
type: lecture-notes
status: in-progress
section: "Section 11: Building Agentic Workflows with LangGraph"
tags:
  - langgraph
  - conditional-edges
  - routing
  - llm-as-judge
  - literal
  - hands-on
related:
  - "[[08 - Adding Real LLM Support]]"
  - "[[02 - What is LangGraph]]"
---

# Conditional Edges

> [!abstract] TL;DR
> A **conditional edge** is the diamond in the flowchart — "go this way *or* that way" depending on a condition. The pattern: write a **routing function** that takes the state, decides, and **returns the name of the next node** to jump to (its return type is a `Literal[...]` of the possible destinations). Register it with `graph_builder.add_conditional_edges("from_node", routing_fn)`. The worked example: take a user query → answer it with GPT-4.1-mini (`chatbot` node) → an `evaluate_response` router decides if the answer is good → if **good**, route to an `end_node`; if **not good**, route to a `chatbot_gemini` node that retries with a different/bigger model → then end. A subtle but critical bug: `add_conditional_edges` routing must return **actual node names** (strings registered via `add_node`), not arbitrary values. (Hardcoding "good" for now; making the judge a real LLM call is the homework.)

> [!info] Where this fits
> Ninth and final note of **Section 11**. It completes the picture from [[02 - What is LangGraph]] — the flowchart's decision diamonds are now real code. Builds directly on the LLM node from [[08 - Adding Real LLM Support]].

---

## 1. What a conditional edge is

A normal edge always goes from A to B. A **conditional edge** branches: from a node, go to **one of several** next nodes depending on a runtime decision.

```
                    ◇ evaluate_response ◇
                       │             │
            good ──────┘             └────── not good
              │                              │
              ▼                              ▼
        ┌──────────┐                 ┌────────────────┐
        │ end_node │                 │ chatbot_gemini │
        └──────────┘                 │   (retry)      │
                                     └────────────────┘
```

This is the **diamond** from the flowchart in [[02 - What is LangGraph]]. It's how LangGraph expresses `if/else` without me hand-writing the control flow.

---

## 2. The workflow being built

```
START → chatbot → evaluate_response ─┬─ good ─────► end_node ──► END
                                     └─ not good ─► chatbot_gemini ──► end_node ──► END
```

1. **`chatbot`** — answer the user's query with GPT-4.1-mini.
2. **`evaluate_response`** (router) — is the answer good?
   - **Good** → go to `end_node`.
   - **Not good** → go to `chatbot_gemini` (retry with a different model), then `end_node`.
3. **`end_node`** — a do-nothing terminal node, then `END`.

---

## 3. A richer state

This example uses a different state than the chatbot — plain fields, no message accumulation:

```python
from typing_extensions import TypedDict
from typing import Optional

class State(TypedDict):
    user_query: str
    llm_output: Optional[str]
    is_good: Optional[bool]
```

| Key | Type | Purpose |
|---|---|---|
| `user_query` | `str` | The incoming question |
| `llm_output` | `Optional[str]` | The model's answer (filled by `chatbot`) |
| `is_good` | `Optional[bool]` | Quality verdict (filled by the evaluator) |

`Optional` because `llm_output` and `is_good` don't exist until a node produces them.

---

## 4. The chatbot node (using raw OpenAI here)

```python
from openai import OpenAI

def chatbot(state: State):
    client = OpenAI()
    response = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[{"role": "user", "content": state.get("user_query")}],
    )
    return {"llm_output": response.choices[0].message.content}
```

Reads `user_query` from state, calls the model, writes the answer into `llm_output`. (This node uses the raw OpenAI client — a reminder that nodes can use whatever they want internally.)

A near-identical `chatbot_gemini` node does the same thing but with a different/bigger model (e.g. GPT-4.1, or an actual Gemini call) — the "retry with something better" path.

---

## 5. The routing function — the heart of it

A conditional edge needs a function that **decides where to go next** and **returns the destination node's name**:

```python
from typing import Literal

def evaluate_response(state: State) -> Literal["chatbot_gemini", "end_node"]:
    # TODO (homework): make this a real LLM-as-judge call
    is_good = True   # hardcoded for now

    if is_good:
        return "end_node"
    else:
        return "chatbot_gemini"
```

Key points:

- It **takes the state** (so it can inspect `llm_output`).
- It **returns a node name** — a string that must match a registered node.
- Its return type annotation is **`Literal[...]`** listing every possible destination. This tells LangGraph (and me) exactly which nodes this edge can route to.

```
evaluate_response(state) ──► "end_node"        (if good)
                         └─► "chatbot_gemini"   (if not good)
```

> [!important] The router returns a *destination*, not state
> Unlike normal nodes (which return state updates), a conditional-edge routing function returns the **name of the next node**. That string is the decision. This is the one place in LangGraph where a function's job is "pick the path," not "transform data."

---

## 6. The end node

A trivial terminal node that just passes the state through — a clean single exit point for both branches:

```python
def end_node(state: State):
    return state   # does nothing, just a convergence point
```

Having an explicit `end_node` (rather than routing straight to `END`) gives both branches a common place to land before finishing — handy if I later want a final step that always runs.

---

## 7. Registering nodes and wiring edges

```python
from langgraph.graph import StateGraph, START, END

graph_builder = StateGraph(State)

graph_builder.add_node("chatbot", chatbot)
graph_builder.add_node("chatbot_gemini", chatbot_gemini)
graph_builder.add_node("evaluate_response", ...)   # see note below
graph_builder.add_node("end_node", end_node)

# normal edges
graph_builder.add_edge(START, "chatbot")
graph_builder.add_edge("chatbot", "evaluate_response")

# conditional edge: from evaluate_response, route via the function
graph_builder.add_conditional_edges("evaluate_response", evaluate_response)

# after the retry branch, converge to end_node
graph_builder.add_edge("chatbot_gemini", "end_node")

# end_node → END
graph_builder.add_edge("end_node", END)

graph = graph_builder.compile()
```

> [!note] `add_conditional_edges` vs `add_edge`
> - `add_edge(from, to)` — an **unconditional** hop.
> - `add_conditional_edges(from, routing_fn)` — runs `routing_fn(state)` and jumps to whatever node **name** it returns.

---

## 8. The bug to watch for

> [!warning] Conditional edges route to node *names*, and the API name is plural
> Two easy mistakes here:
> 1. The method is **`add_conditional_edges`** (plural "edges"), not `add_conditional_edge`. Using the singular form raises an error.
> 2. The routing function must return a **registered node name** (a string that exists in `add_node`). Returning some other value — or an object where a node-name string is expected — fails. The `Literal[...]` return annotation is there precisely to keep the possible return values pinned to real node names.

---

## 9. Running it and tracing the path

```python
updated_state = graph.invoke({"user_query": "What is 2 plus 2?"})
print(updated_state)
```

With `is_good = True` hardcoded:

```
chatbot node   → llm_output = "2 plus 2 equals 4"
evaluate node  → returns "end_node"   (good)
end_node       → done
```

Path taken: `chatbot → evaluate_response → end_node`.

Flip the verdict (`is_good = False`) and the path changes:

```
chatbot node        → llm_output = "..."
evaluate node       → returns "chatbot_gemini"  (not good)
chatbot_gemini node → retries with a bigger model
end_node            → done
```

Path taken: `chatbot → evaluate_response → chatbot_gemini → end_node`.

Dropping `print` statements in each node (`"chatbot node"`, `"evaluate node"`, `"chatbot_gemini node"`, `"end_node"`) makes the chosen path visible at runtime — proof the conditional edge really does redirect.

---

## 10. The homework: make the judge real

Right now `is_good` is hardcoded. The real version makes `evaluate_response` an **LLM-as-judge**: send `llm_output` to a model (could be a *different* provider, e.g. Gemini) and ask "is this answer good?", then branch on its verdict.

```python
def evaluate_response(state: State) -> Literal["chatbot_gemini", "end_node"]:
    verdict = judge_llm.invoke(
        f"Is this a good answer? Reply yes/no.\n\nAnswer: {state['llm_output']}"
    )
    is_good = "yes" in verdict.content.lower()
    return "end_node" if is_good else "chatbot_gemini"
```

That closes the loop into the full pattern from [[02 - What is LangGraph]]: answer → judge → retry-or-finish. Using a *second* model as the judge is a real-world trick — one model checks another's work.

---

## 11. Conditional edge — the pattern in one box

```
1. write a routing fn:   def route(state) -> Literal["A", "B"]: ...
2. it returns a NODE NAME based on the state
3. register:             graph_builder.add_conditional_edges("from_node", route)
4. ensure each returnable name is a registered node
```

---

## 12. Common gotchas

> [!warning] Conditional edge issues

| Symptom | Cause | Fix |
|---|---|---|
| Error on `add_conditional_edge` | Wrong method name | Use `add_conditional_edges` (plural) |
| "Unknown node" at compile | Router returns a name not registered | Return only registered node names |
| Always takes one branch | Condition hardcoded | Wire it to a real check / LLM judge |
| Router has no effect | Used `add_edge` instead of conditional | Use `add_conditional_edges` |
| Branch never converges | Forgot edge from retry node onward | `add_edge("chatbot_gemini", "end_node")` |

---

## 13. Main takeaways

- A **conditional edge** is the flowchart diamond — branch based on a condition.
- Write a **routing function**: takes state, returns the **next node's name**.
- Annotate its return as **`Literal[...]`** of the possible destination node names.
- Register with **`add_conditional_edges("from_node", routing_fn)`** (plural!).
- Routing functions return a **destination name**, not a state update.
- The example: `chatbot → evaluate → (good) end_node | (bad) chatbot_gemini → end_node`.
- A do-nothing **`end_node`** gives both branches a common landing point.
- Returnable values **must be registered node names**, or compile fails.
- Real version = **LLM-as-judge**: a second model evaluates the first's answer.

---

## 14. Things I still want to figure out

- Can a conditional edge route to **more than two** nodes? (Yes — list them all in the `Literal`.)
- How does LangGraph prevent **infinite retry loops** (judge keeps saying "bad")?
- Can the routing function return a **list** of nodes for parallel fan-out?
- What's the cleanest way to pass **why** it failed into the retry node's context?
- Using a **different provider** (Gemini) as judge — how to wire two model clients cleanly?

---

## 15. Things to dig into

- **LangGraph conditional edges**: https://langchain-ai.github.io/langgraph/concepts/low_level/#conditional-edges
- **Recursion limit** config to cap retry loops.
- **LLM-as-a-judge** patterns and prompts.
- **Hands-on**: implement the real judge (the homework), then force a "bad" verdict and watch the Gemini retry branch fire.

---

## 16. Section wrap-up

This completes the LangGraph fundamentals: **state → nodes → edges → compile → invoke → conditional edges**. The same building blocks scale from a one-line chatbot to a full agent with tools, judges, and retry loops — all as a readable graph instead of nested loops, exactly the promise from [[01 - Section Intro - Welcome to LangGraph]].

---

## Related
- [[08 - Adding Real LLM Support]] — the LLM node this branches on.
- [[02 - What is LangGraph]] — the flowchart whose diamonds this implements.
- [[06 - Adding Edges and Compiling the Graph]] — unconditional edges, for contrast.

## Sources
- [LangGraph conditional edges](https://langchain-ai.github.io/langgraph/concepts/low_level/#conditional-edges)
