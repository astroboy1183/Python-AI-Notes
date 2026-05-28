---
title: Long-Term Memory in LLMs
date: 2026-05-28
source: Video transcript
type: lecture-notes
status: in-progress
parent: "[[00 - Types of Memory in LLMs]]"
tags:
  - llm
  - memory
  - long-term-memory
  - ltm
  - ai-agents
  - mem0
  - qdrant
  - graph-database
  - vector-store
  - rag
  - factual-memory
  - episodic-memory
  - semantic-memory
related:
  - "[[00 - Types of Memory in LLMs]]"
  - "[[01 - Short-Term Memory in LLMs]]"
---

# Long-Term Memory in LLMs (LTM)

> [!abstract] TL;DR
> **Long-Term Memory (LTM)** is information about the **user** that is stored in an external database and **persists forever** — across sessions, devices, and time. Unlike STM (which is session-scoped), LTM is **user-scoped**. The big challenge: LTM **keeps growing**, and dumping it all into the LLM's context window isn't viable. That's why LTM is further split into **factual**, **episodic**, and **semantic** memory — each with different retrieval rules.

> [!info] Where this fits
> LTM is the **persistent counterpart** to [[01 - Short-Term Memory in LLMs]]. Together they form the two halves of the [[00 - Types of Memory in LLMs]] taxonomy.

---

## 1. The core idea

Long-Term Memory is:
- **Persistent** — stored in a real database; not lost when the session ends.
- **User-scoped** — tied to a specific user, not a specific conversation.
- **Cross-session** — survives days, weeks, and months.
- **Injected as context** — pulled from the DB and added to the prompt when needed.
- **Growing** — accumulates over time → requires **selective retrieval**.

> **In one sentence:** LTM = facts about the user that should never be forgotten, stored in a database, injected into the conversation when needed.

---

## 2. Real-world analogy: the restaurant remembers

Continuing the restaurant analogy from [[01 - Short-Term Memory in LLMs]].

### The scenario
1. **First visit**: Walk in, tell the agent *"My name is Jayanth."* Order #132.
2. **#132 is STM** — temporary; gone once the burger's served.
3. **"Name is Jayanth" is LTM** — stored in the database **forever**.

### Second visit (weeks later)
On returning, the agent says:

> **"Hey Jayanth! What's your order number?"**

Notice:
- The agent **doesn't ask the name** — pulled from LTM.
- The agent **does ask the order number** — that's session-specific (STM).

> [!tip] The key insight
> LTM lets the agent **personalize** by carrying user-level facts across sessions. Without LTM, every visit feels like the first time.

---

## 3. What goes into LTM

Things worth **always remembering about a specific user**:
- Name
- Age
- Preferences (e.g., "prefers spicy food", "vegetarian", "concise replies")
- Location / timezone
- Goals and ongoing projects
- Past behavior patterns
- Important relationships and history

Things that do **NOT** belong in LTM:
- The current order number
- Today's specific question
- Transient session state

---

## 4. Where LTM gets stored

LTM lives in **external storage** — outside the LLM itself. Common choices:

| Storage | Best For | Why |
|---|---|---|
| **MongoDB** (or any document DB) | Structured user facts | Flexible schema, easy lookup by user_id |
| **Qdrant** (vector store) | Semantic search over memories | Find "similar" past facts via embeddings |
| **Graph databases** (Neo4j, etc.) | Relationships between facts/users | Capture "Jayanth works with Rahul on Project X" |
| **PostgreSQL** | Strict relational facts | Solid transactional integrity |
| **Redis** | Fast key-value lookups | Speed when memory must be retrieved frequently |

> [!quote] From the transcript
> "This database can be anything. It can be a MongoDB, it can be a Qdrant vector store, it can be a graph database. It is stored forever."

The course will demonstrate **Qdrant** and **GraphDB** alongside **Mem0** to build LTM systems.

---

## 5. How LTM plugs into a conversation

The flow:

```
┌────────────────────────────────────────────────────────┐
│  User opens a new session                              │
│      │                                                  │
│      ▼                                                  │
│  System loads LTM for this user from DB                │
│      │                                                  │
│      ▼                                                  │
│  LTM facts are injected as the initial system prompt:  │
│    "User's name is Jayanth.                             │
│     Age is 28.                                          │
│     Prefers vegetarian food.                            │
│     ..."                                                │
│      │                                                  │
│      ▼                                                  │
│  Normal conversation begins                            │
│  (STM grows during the session)                        │
│      │                                                  │
│      ▼                                                  │
│  Important new facts → written back to LTM             │
│      │                                                  │
│      ▼                                                  │
│  Session ends → STM discarded, LTM persists            │
└────────────────────────────────────────────────────────┘
```

### The pattern is similar to RAG

> [!example] Mental model
> The pattern mirrors **RAG (Retrieval-Augmented Generation)**:
> 1. Fetch relevant info from a DB beforehand.
> 2. Inject it as system prompt / context.
> 3. Let the LLM use it during the conversation.
>
> LTM works the **exact same way** — except instead of retrieving documents, the system retrieves **facts about the user**.

---

## 6. The big problem: LTM grows forever

The catch the speaker emphasized:

> Over time, a single user might accumulate **4,000+ memories**.
> Can all 4,000 be dumped into the system prompt?
> **No.**

### Why not
- **Context window is finite** (8k / 128k / 1M tokens — but still bounded).
- **Cost** — every token sent costs money + latency.
- **Signal-to-noise** — irrelevant facts confuse the model.
- **Performance** — too much context degrades reasoning quality.

> [!warning] The retrieval problem
> All of LTM can't be injected. Choices have to be made:
> - What gets retrieved **always**?
> - What gets retrieved **on demand** (only when relevant)?
> - What gets retrieved **rarely / occasionally**?

This question — *"what to retrieve when"* — is what drives the **sub-division of LTM** into three types.

---

## 7. The three sub-types of LTM (preview)

| Sub-type | Retrieval Pattern | Example |
|---|---|---|
| **Factual** | Always retrieve | Name, age, language |
| **Episodic** | Retrieve when relevant (semantic search) | "Last week's auth debugging session" |
| **Semantic** | Retrieve on demand (RAG-style) | "Delhi is the capital of India" |

Each gets its own dedicated note:
- [[03 - Factual Memory in LLMs]]
- [[04 - Episodic Memory in LLMs]]
- [[05 - Semantic Memory in LLMs]]

> [!info]
> These sub-types aren't arbitrary — they come from cognitive science (Tulving's work) and map to different **retrieval strategies** in production AI systems.

---

## 8. STM vs LTM — side by side

| Dimension | STM | LTM |
|---|---|---|
| **Lifespan** | Session only | Forever |
| **Scope** | Current conversation | The user across all sessions |
| **Storage** | In-memory / context window | External DB (MongoDB, Qdrant, Neo4j, ...) |
| **Cleared when** | Task completes | Rarely — only on explicit deletion |
| **Example** | "Order #132" | "User's name is Jayanth" |
| **Retrieval** | Just pass the message history | Fetch from DB → inject into prompt |
| **Growth concern** | Limited (one session) | Unbounded → needs selective retrieval |

---

## 9. Implementation patterns

### Basic pattern (pseudocode)

```python
# Pseudocode
def start_session(user_id):
    # 1. Load LTM from the database
    ltm_facts = db.fetch_user_memories(user_id)

    # 2. Build the initial system prompt
    system_prompt = f"""
    You are an AI assistant.
    Here is what is known about the user:
    {format_facts(ltm_facts)}
    """

    # 3. Start STM (empty history)
    message_history = [{"role": "system", "content": system_prompt}]

    return message_history

def end_session(user_id, message_history):
    # 4. Extract noteworthy facts from the session
    new_facts = extract_important_facts(message_history)

    # 5. Write them back to LTM
    db.upsert_user_memories(user_id, new_facts)
```

### Production patterns (covered later in the course)
- **Mem0** — abstracts LTM management; handles writes + retrieval.
- **Qdrant + embeddings** — store memories as vectors, retrieve by semantic similarity.
- **GraphDB (Neo4j)** — model relationships between people, projects, events.
- **Hybrid** — Qdrant for episodic + Mongo for factual + Graph for relationships.

---

## 10. Tools & frameworks

### Mem0 (used later in this course)
- Framework specifically designed for LLM memory management.
- Handles both writing to and retrieving from LTM.

### Qdrant
- Open-source vector database.
- Excellent for **episodic** and **semantic** memory (search by similarity).

### Graph databases (Neo4j, ArangoDB)
- Model relationships explicitly.
- Useful when memories form a network ("Jayanth → works with → Rahul → on → ProjectX").

### Others
- **LangChain memory modules**, **LangGraph checkpointers**, **LlamaIndex** memory.
- **OpenAI Memory** (managed) for ChatGPT-style persistence.

---

## 11. Gotchas & best practices

> [!warning] Common pitfalls

- **Don't store everything** — be selective; not every chat detail belongs in LTM.
- **Mind the context window** — retrieve only what's needed, not all 4,000 memories.
- **Stale memories** — preferences change. Add timestamps; periodically refresh or expire.
- **Conflicting facts** — "User loves coffee" later contradicted by "User quit caffeine." Conflict resolution / recency rules needed.
- **Privacy & consent** — LTM stores real personal data. Honor deletion requests.
- **User isolation** — one user's LTM must never leak into another's session.
- **Backups** — losing LTM means the agent "forgets" everyone.

---

## 12. Main takeaways

- LTM = persistent, **user-scoped**, **database-backed** memory.
- Stored in MongoDB / Qdrant / GraphDB / etc. — **outside** the LLM.
- Injected as **initial context** when a session starts (RAG-like pattern).
- LTM **grows over time** → injecting everything isn't viable → **selective retrieval** required.
- That selection problem is why LTM splits into **factual**, **episodic**, and **semantic** sub-types.
- Once LTM is in place, agents can **personalize** across sessions ("Hey Jayanth!").

---

## 13. Things I still want to figure out

- **What's worth storing?** What's the heuristic for promoting session facts to LTM?
- **When to retrieve?** Always-on vs. on-demand vs. rare retrieval — triggered by what?
- **Conflict resolution** — when new facts contradict old ones, which wins?
- **Memory decay** — should some memories expire? When?
- **Cross-user inference** — is there a case where one user's LTM informs answers to others (anonymized patterns)?

---

## 14. Next up in this section

- [[03 - Factual Memory in LLMs]] — facts about the user (name, age, preferences) — **always retrieve**.
- [[04 - Episodic Memory in LLMs]] — past interactions and patterns — retrieve **when relevant**.
- [[05 - Semantic Memory in LLMs]] — general world knowledge — retrieve **on demand**.

---

## Related
- [[00 - Types of Memory in LLMs]] — parent overview
- [[01 - Short-Term Memory in LLMs]] — the volatile counterpart

## Sources
- Video transcript (dedicated long-term memory lecture).
- Referenced tools: [Mem0](https://mem0.ai), [Qdrant](https://qdrant.tech), graph databases.
