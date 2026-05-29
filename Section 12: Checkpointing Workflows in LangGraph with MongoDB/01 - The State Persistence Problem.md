---
title: The State Persistence Problem
date: 2026-05-29
source: "Section 12 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 12: Checkpointing Workflows in LangGraph with MongoDB"
tags:
  - langgraph
  - state
  - persistence
  - checkpointing
  - memory
  - foundations
related:
  - "[[02 - Setting up MongoDB with Docker Compose]]"
  - "[[09 - Conditional Edges]]"
---

# The State Persistence Problem

> [!abstract] TL;DR
> The LangGraph chatbot from Section 11 has a hidden flaw: its **state lives only in memory**. While a graph is being invoked, every node sees the up-to-date state — but the moment `invoke` finishes, **that state is gone**. Re-run the app and it starts from a blank slate. Demo: tell it "my name is Jayanth" → it replies "Hello Jayanth"; but run it again asking "what is my name?" → "I don't know your name." Each run is a fresh, empty state with just the one new message. For a real assistant I need the conversation to **survive across runs (and days)**. The fix is **checkpointing** — persisting the graph's state to a database so it can be reloaded later. That's what this whole section is about.

> [!info] Where this fits
> First note of **Section 12: Checkpointing Workflows in LangGraph with MongoDB**. It diagnoses the problem; [[02 - Setting up MongoDB with Docker Compose]] sets up the storage, and [[03 - Implementing Checkpointing with MongoDBSaver]] wires it in.

---

## 1. Recap: where state lives now

From Section 11, a graph run looks like:

```python
graph.invoke({"messages": ["Hi, my name is Jayanth"]})
```

During that call, the state flows node → node, each one reading and appending to it (thanks to the `add_messages` reducer). That all works. The catch is **where** the state lives.

---

## 2. The flaw: state is in-memory and ephemeral

```
┌──────────────── one invoke() call ────────────────┐
│                                                    │
│  initial state ─► node ─► node ─► final state      │  ← state in RAM
│                                                    │
└────────────────────────────────────────────────────┘
                        │
                        ▼
              invoke() returns
                        │
                        ▼
                 STATE DELETED        ← gone from memory
```

The state is maintained in memory **only for the duration of the invocation**. Once the graph finishes, it's discarded. Re-running the program creates a **brand-new, empty state** — there's no memory of anything that happened before.

---

## 3. The demo that exposes it

### Run 1 — tell it my name

```python
graph.invoke({"messages": ["Hi, my name is Jayanth"]})
```

```
AI: "Hello Jayanth, how can I assist you today?"
```

The model clearly knows the name — *within this run*.

### Run 2 — ask it my name (separate run)

```python
graph.invoke({"messages": ["What is my name?"]})
```

```
AI: "I don't know your name based on the current conversation."
```

It has no idea. Why? Because run 2 is a **completely fresh state** that starts from scratch with a single message — the previous run's history was never saved.

| | Run 1 | Run 2 |
|---|---|---|
| Starting state | `[Human("...name is Jayanth")]` | `[Human("what is my name?")]` |
| History available | none before | **none** — run 1 is gone |
| Result | knows the name | doesn't know the name |

---

## 4. Why this matters

A real chatbot/assistant must remember across sessions. If I close the app and come back **tomorrow**, it should still know who I am and what we discussed. In-memory state can't do that — it dies with the process.

> [!warning] No persistence = no memory
> Without a way to store state, every run is a stranger meeting me for the first time. Multi-turn conversations that span app restarts are impossible.

This is exactly the kind of "memory layer" problem explored conceptually back in Section 13 — here it shows up concretely inside LangGraph, and the solution is mechanical: persist the state.

---

## 5. The solution: checkpointing

> [!note] The idea
> **Checkpointing** = saving the graph's state to a **persistent store** (a database) so it can be reloaded on the next run. The conversation survives across invocations, restarts, and days.

```
in-memory state            checkpointed state
───────────────            ──────────────────
dies with the process  ──► saved to a database
fresh every run            reloaded every run
no cross-run memory        full history persists
```

The rest of the section implements this with **MongoDB** as the backing store.

---

## 6. What's coming

| Step | Note |
|---|---|
| Stand up MongoDB (Docker) | [[02 - Setting up MongoDB with Docker Compose]] |
| Wire a `MongoDBSaver` checkpointer into the graph | [[03 - Implementing Checkpointing with MongoDBSaver]] |

---

## 7. Main takeaways

- LangGraph state is **in-memory** — alive only during a single `invoke`.
- When the invocation ends, **the state is deleted**.
- Re-running the app starts from a **fresh, empty state** — no memory.
- Demo: "my name is Jayanth" works in one run; "what is my name?" fails in the next.
- A real assistant must **persist** state across runs and days.
- The fix is **checkpointing** — saving state to a database.
- This section uses **MongoDB** as the persistent store.

---

## 8. Things I still want to figure out

- Does checkpointing save the **full state** every step, or just deltas?
- How is one user's conversation **kept separate** from another's? (Answered in note 03 via thread IDs.)
- What databases besides MongoDB are supported (Postgres, SQLite, in-memory)?
- What's the **storage cost** of persisting every step of every conversation?

---

## 9. Things to dig into

- **LangGraph persistence concepts**: https://langchain-ai.github.io/langgraph/concepts/persistence/
- **Checkpointers** overview — the class that does the saving.
- Cross-link: the conceptual **memory layer** in Section 13.

---

## 10. Next up in this section

- [ ] [[02 - Setting up MongoDB with Docker Compose]] — stand up the database that will hold the state.

---

## Related
- [[09 - Conditional Edges]] — the LangGraph build this extends.
- [[02 - Setting up MongoDB with Docker Compose]] — the storage backend.
- [[03 - Implementing Checkpointing with MongoDBSaver]] — the implementation.

## Sources
- [LangGraph persistence](https://langchain-ai.github.io/langgraph/concepts/persistence/)
