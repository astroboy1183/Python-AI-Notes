---
title: Short-Term Memory in LLMs
date: 2026-05-28
source: "Notes from working through the material"
type: lecture-notes
status: in-progress
parent: "[[00 - Types of Memory in LLMs]]"
tags:
  - llm
  - memory
  - short-term-memory
  - stm
  - working-memory
  - ai-agents
  - conversation-history
  - mem0
related:
  - "[[00 - Types of Memory in LLMs]]"
---

# Short-Term Memory in LLMs (STM)

> [!NOTE]
> **TL;DR**
> **Short-Term Memory (STM)** in an LLM agent is simply the **ongoing conversation history** of the current session. It's held only while a task is in progress, and discarded once the task ends. Any chatbot that passes the message history back to the LLM on every turn is already using STM.

> [!NOTE]
> **Where this fits**
> First memory type in the syllabus. STM lives under the broader [[00 - Types of Memory in LLMs]] taxonomy and is the volatile counterpart to **Long-Term Memory (LTM)**.

---

## 1. The core idea

Short-Term Memory is:
- **Short-lived** — exists only for the duration of an active session/task.
- **Session-scoped** — tied to the current conversation, not the user permanently.
- **Volatile** — deleted/discarded once the task is complete.
- **Working memory** — also called *working memory* in agentic AI literature.

> **In one sentence:** STM = the conversation history of the session currently in progress.

---

## 2. Real-world analogy: the restaurant order

This analogy captures what STM is.

### The scenario
1. Walk into a restaurant and order a burger.
2. The cashier hands over **order number 132**.
3. The number is **held in mind** while waiting — glancing at the screen showing ready orders.
4. The number comes up → grab the food → **transaction complete**.
5. A week later, when asked *"What was the order number last time?"* — no idea.

### Why this is STM
- The number was held **only during the transaction**.
- The brain didn't bother committing it to long-term storage — no reason to.
- Once the goal (getting the food) was achieved, the data was **purged**.

> [!TIP]
> **The key insight**
> The brain made an implicit decision: *"This number matters right now, but won't matter tomorrow."* That's exactly how STM works in LLM agents.

---

## 3. Concrete LLM example: a food-ordering agent

Imagine an **AI agent that takes food orders** for a hotel/restaurant.

### The interaction

| Turn | Speaker | Message |
|---|---|---|
| 1 | Agent | "How can I help?" |
| 2 | User | "Where is my order number 132?" |
| 3 | Agent | "It's getting prepared." |
| 4 | User | "What's the status now?" |
| 5 | Agent | *(should know it's still about 132)* |

### What goes wrong without STM

If the agent **doesn't pass the conversation history** back to the LLM on turn 4, it has no idea what the user means. It would respond:

> "Hi! What's your order number?"

The user just gave the number two turns ago. **Terrible UX** — frustrating and unprofessional.

### What goes right with STM

On every turn, the **entire conversation history** gets sent to the LLM:

```
[User]:  Where is my order number 132?
[Agent]: It's getting prepared.
[User]:  What's the status now?
```

Now the LLM sees `132` in context and correctly looks up that order in the database.

> [!WARNING]
> **Rule of thumb**
> Always pass the **full ongoing conversation history** back to the LLM during a session. The LLM is stateless — no history sent, no history known.

---

## 4. The lifecycle of STM

```
┌──────────────────────────────────────────────────────┐
│  Session Start                                        │
│      │                                                │
│      ▼                                                │
│  Empty history []                                     │
│      │                                                │
│      ▼                                                │
│  User: "Order #132 status?"                           │
│      │                                                │
│      ▼                                                │
│  history.append(user_msg)                             │
│  LLM(history) → response                              │
│  history.append(assistant_msg)                        │
│      │                                                │
│      ▼                                                │
│  User: "What's the status now?"                       │
│      │                                                │
│      ▼                                                │
│  history grows... LLM still sees full context         │
│      │                                                │
│      ▼                                                │
│  Order delivered → Task complete                      │
│      │                                                │
│      ▼                                                │
│  DELETE chat history                                  │
└──────────────────────────────────────────────────────┘
```

### What happens when a NEW order starts?
- A **brand new** chat history is created (say, for order **#432**).
- The agent has **zero memory** of order #132 — that's by design.
- It will ask: *"What's your order number?"* — correct, because this is a different transaction.

> [!NOTE]
> **The pattern**
> **One session = one STM history.** New session → fresh empty history. Old session ends → history can be deleted.

---

## 5. Why not store STM forever

Keeping every chat history forever is *possible* but **wrong** for STM data, because:

1. **Not useful long-term** — yesterday's order number is irrelevant today.
2. **Cost** — storing and retrieving stale data wastes money.
3. **Context bloat** — sending old, irrelevant history to the LLM degrades performance and increases token cost.
4. **Privacy / clutter** — keeping unneeded data is a liability.

> [!NOTE]
> Things actually worth keeping (like the user's name or preferences) belong in **Long-Term Memory** — see [[02 - Long-Term Memory in LLMs]].

---

## 6. How STM is implemented in practice

In code, STM usually looks like an **append-only list of messages** passed to the LLM on every call.

### Typical pattern

```python
# Pseudocode
message_history = []          # STM lives here

while session_active:
    user_input = get_user_message()
    message_history.append({"role": "user", "content": user_input})

    response = llm.chat(messages=message_history)   # pass full history
    message_history.append({"role": "assistant", "content": response})

    if task_complete:
        break

# Session over → discard message_history
message_history = None
```

### Common storage patterns
- **In-memory list** — simplest, fine for single-turn or short sessions.
- **MongoDB / Redis** — when sessions span multiple requests (e.g., a web app).
- **Conversation buffer** — built in to frameworks like LangChain (`ConversationBufferMemory`).

> [!TIP]
> A common setup is storing the message history in MongoDB and replaying it on every turn — that's STM in practice.

---

## 7. STM in existing code

STM is already in use in earlier examples — just unnamed.

Examples:
- **Hello World** agent — passes message history each turn.
- **Chain-of-Thought (CoT)** prompts — append every step to a running message history while the application runs.
- Any chatbot that does `messages.append(...)` and then re-sends the full `messages` list to the LLM.

> [!TIP]
> Any code with a `message_history` (or `messages`, `chat_history`, `conversation`) list that grows during a session and gets passed to the LLM repeatedly — **that's STM in action.**

---

## 8. Industry definition

From IBM's blog on agentic memory:

> *"Short-term memory (STM) enables an AI agent to remember recent inputs for immediate decision making. This type of memory is useful in conversational AI where maintaining context across multiple exchanges is required."*

Also commonly called **working memory** — maintains short-term conversational context (e.g., "what was the last question?").

---

## 9. Tools & frameworks

### Mem0
- A framework for managing memory in AI agents.
- Used later in the course.
- Website: [mem0.ai](https://mem0.ai)

### Other notable options
- **LangChain** — `ConversationBufferMemory`, `ConversationSummaryMemory`.
- **LlamaIndex** — chat engines with built-in history.
- **OpenAI Assistants API** — managed threads (history handled server-side).
- **LangGraph** — checkpointed state for stateful agents.

---

## 10. Gotchas & best practices

> [!WARNING]
> **Watch out for these**

- **Context window limits** — STM grows with every turn. Eventually it exceeds the LLM's context window (e.g., 8k, 128k tokens). Mitigations:
  - Truncate (drop oldest messages), or
  - Summarize (condense history into a shorter form), or
  - Use sliding-window memory.
- **Don't confuse STM with state** — STM is conversation history. State (e.g., "current order being placed") may be tracked separately.
- **Privacy** — even though STM is short-lived, logs/MongoDB shouldn't be keeping it around unintentionally.
- **Don't pass irrelevant history** — if the user shifts topics mid-session, old history can confuse the model.

---

## 11. Main takeaways

- STM = **ongoing conversation history** for the **current session**.
- The LLM is stateless — sending history back on every turn is the application's responsibility.
- Restaurant order #132 analogy: remember during the task, forget after.
- STM is **deleted** when the task/session ends.
- A new session = a **new, empty** STM.
- Any chatbot that appends to a `messages` list is already doing STM.

---

## 12. Things I still want to figure out

- At what point should old STM messages be **summarized vs. truncated**?
- What's the heuristic for **promoting STM → LTM** — what's worth remembering?
- For long sessions, is it better to keep history in memory (RAM) or in a DB like MongoDB/Redis?
- How does STM interact with **tool calls** — do tool outputs become part of STM?

---

## 13. Next up in this section

- [[02 - Long-Term Memory in LLMs]] — persistent memory across sessions
- [[03 - Factual Memory in LLMs]]
- [[04 - Episodic Memory in LLMs]]
- [[05 - Semantic Memory in LLMs]]

---

## Related
- [[00 - Types of Memory in LLMs]] — parent overview
- [[AI-Productivity-and-Obsidian-Setup]]

## Sources
- IBM blog on agentic memory
- [Mem0](https://mem0.ai)
