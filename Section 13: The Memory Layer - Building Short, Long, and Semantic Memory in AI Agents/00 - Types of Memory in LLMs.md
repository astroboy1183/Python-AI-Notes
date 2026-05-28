---
title: Types of Memory in LLMs
date: 2026-05-28
source: "Notes from working through the material"
type: lecture-notes
status: in-progress
tags:
  - llm
  - memory
  - ai
  - short-term-memory
  - long-term-memory
  - episodic-memory
  - semantic-memory
  - factual-memory
  - ai-agents
  - context-window
related: []
---

# Types of Memory in LLMs

> [!abstract] Overview
> Memory is what lets an LLM (or AI agent) **remember context, learn about the user, and stay coherent across interactions**. Without memory, every conversation starts from zero. This note breaks down the **two broad categories** (short-term and long-term) and the **three sub-types** of long-term memory (factual, episodic, semantic), with examples, analogies, and how they show up in real LLM systems.

> [!info] Why this matters
> LLMs by themselves are **stateless** — the model doesn't "remember" anything after a response is generated. Memory systems are **built on top** of the LLM (via context windows, databases, vector stores, etc.) to create the illusion (and reality) of continuity. Picking *which* type of memory to use for *which* problem is core to designing good AI agents.

---

## 1. The big picture

LLM memory splits into **two categories**:

```
                        LLM Memory
                            |
            ┌───────────────┴───────────────┐
            |                               |
     Short-Term Memory               Long-Term Memory
          (STM)                            (LTM)
                                            |
                            ┌───────────────┼───────────────┐
                            |               |               |
                       Factual         Episodic         Semantic
                        Memory          Memory           Memory
```

| Dimension | Short-Term Memory | Long-Term Memory |
|---|---|---|
| **Lifespan** | Seconds → minutes (one session) | Days → forever |
| **Scope** | Current task / conversation | Across all sessions |
| **Storage** | In context / RAM-like | Database, vector store, file |
| **Cleared when** | Task or session ends | Rarely — only on explicit deletion |
| **Purpose** | Maintain coherence *now* | Personalize and learn *over time* |

---

## 2. Short-Term Memory (STM)

### 2.1 Definition
Short-Term Memory is a **temporary, session-scoped** memory that lives only **while a conversation or task is actively going on**. The moment the task completes — or the session ends — the memory is wiped.

### 2.2 Key characteristics
- **Short-lived** — exists only during active interaction.
- **Session-bound** — tied to a single chat / task / agent run.
- **Volatile** — discarded once the task ends; no persistence by default.
- **Fast access** — stored in-memory, often inside the LLM's **context window**.
- **Limited capacity** — bounded by the model's context length (e.g., 8k, 128k, 1M tokens).

### 2.3 Concrete example
A user sends:
> *"Hey, I want to create a project on tracking expenses. Use Python and SQLite. Make sure to add unit tests."*

While the project is being built, the model **remembers** Python, SQLite, and unit tests across multiple messages. **The moment the project is completed and the chat closes**, all of that context is gone. A follow-up tomorrow saying *"Add a new feature"* finds an LLM with no idea what project is meant.

### 2.4 Real-world analogies
- A **scratchpad** torn up after the task is done.
- A **whiteboard** wiped clean at the end of every meeting.
- **Working memory** during mental math: the digits exist while computing, then evaporate.

### 2.5 How STM is typically implemented
- **Context window** of the LLM (passing chat history along with each prompt).
- **Conversation buffer** in frameworks like LangChain / LlamaIndex.
- **Scratchpad / thought log** in agentic systems (ReAct loops, planning agents).

> [!warning] STM gotchas
> - Once the context window fills up, **older messages get truncated** — the model "forgets" earlier parts of the same session.
> - STM is **not the same** as the model's training data — training is baked-in knowledge; STM is runtime context.

---

## 3. Long-Term Memory (LTM)

### 3.1 Definition
Long-Term Memory is **persistent** memory about the user that **stays forever** — across sessions, across days, across months. Even after 30 days away, the model still "remembers" the user.

### 3.2 Key characteristics
- **Persistent** — survives session boundaries.
- **Stored externally** — typically in a database, vector store, or file system (not just the LLM's context).
- **User-bound** — tied to a specific user identity.
- **Selective** — only *important* facts get committed.
- **Retrievable on demand** — pulled into the context when relevant.

### 3.3 What goes into LTM
Anything worth **never forgetting** about the user:
- User's **name**
- User's **age**
- User's **preferences** (e.g., "prefers concise answers", "vegetarian", "uses Python")
- User's **goals**, **history**, **patterns**

### 3.4 Real-world analogy
A **personal assistant** who keeps a notebook on each client. Every meeting, the assistant flips open the notebook and recalls the client's birthday, their dog's name, the project they've been working on for months.

### 3.5 How LTM is typically implemented
- **Databases** (SQL / NoSQL) for structured facts.
- **Vector databases** (Pinecone, Weaviate, Chroma) for semantic search over past content.
- **Knowledge graphs** for relationships.
- **Memory modules** in frameworks (e.g., LangGraph memory, OpenAI's memory feature, Mem0).

---

## 4. The three sub-types of long-term memory

LTM further breaks down into **three distinct flavors**, each serving a different purpose.

### 4.1 Factual memory

> [!example] Definition
> Stores **concrete facts about the user** — the "profile data" of who they are.

- **What it stores**: name, age, location, job, preferences, allergies, language, timezone.
- **How it's queried**: usually a direct lookup ("What is the user's name?").
- **Updates**: rare; typically when the user explicitly shares new info.

**Example entries:**
```
- name: Jayanth
- city: Hyderabad
- preference: prefers dark mode
- diet: vegetarian
```

**Use case:** *"Hi Jayanth, since you're vegetarian, here are some recipes…"*

---

### 4.2 Episodic memory

> [!example] Definition
> Stores the **history of past interactions** — what happened with the user, how the user talks, recurring patterns.

- **What it stores**: previous conversations, decisions, tone, communication style, feedback the user has given.
- **How it's queried**: often semantic search ("What did the user ask about LLMs last week?").
- **Updates**: continuously, after each interaction.

**Example entries:**
- "Last Tuesday, user asked about LangChain and seemed frustrated by verbose answers."
- "User prefers bullet points over paragraphs."
- "User has been building an Obsidian-based knowledge system."

**Use case:** *"Last time the user mentioned LangChain felt verbose — here's a more concise alternative."*

> [!tip]
> Episodic memory is what makes an agent feel **personal** rather than generic. It's the difference between "How can I help?" and "Last time we left off debugging the auth bug — want to pick up there?"

---

### 4.3 Semantic memory

> [!example] Definition
> Stores **general world knowledge** — facts about reality that are **not specific to the user**.

- **What it stores**: real-world facts, definitions, domain knowledge.
- **How it's queried**: semantic search / retrieval-augmented generation (RAG).
- **Updates**: when new facts are learned or curated.

**Example entries:**
- *"Delhi is the capital of India."*
- *"The speed of light is ~299,792 km/s."*
- *"Python's GIL prevents true multi-threaded CPU parallelism."*

**Use case:** Reference knowledge the agent pulls from when answering domain questions — separate from the LLM's pre-trained knowledge.

> [!note] Semantic vs. LLM training data
> The LLM already "knows" Delhi is the capital of India from training. **Semantic memory** is useful when curated, up-to-date, or domain-specific facts are needed — facts the model can rely on instead of (or in addition to) its training.

---

## 5. Side-by-side comparison

| Memory Type | Category | About | Example | Lifespan |
|---|---|---|---|---|
| **Short-Term (STM)** | Volatile | Current task context | "We're using Python + SQLite right now" | Session only |
| **Factual** | LTM | User identity | "Name is Jayanth" | Permanent |
| **Episodic** | LTM | Past interactions | "Last week worked on auth bug" | Permanent |
| **Semantic** | LTM | World knowledge | "Delhi is the capital of India" | Permanent |

---

## 6. A mental model: the "human memory" parallel

Cognitive science actually inspired these categories. How they map to human memory:

| LLM Memory | Human Memory Equivalent |
|---|---|
| Short-Term | Working memory (what's held in mind right now) |
| Factual | Self-knowledge / personal identity |
| Episodic | Autobiographical memory (life events) |
| Semantic | General knowledge (facts learned in school) |

> [!info]
> Not a coincidence — the LLM memory taxonomy borrows directly from psychology, particularly **Endel Tulving's** distinction between **episodic** and **semantic** memory (1972).

---

## 7. When to use which memory

| Need | Memory type |
|---|---|
| Maintain context in the current chat | **STM** |
| Remember the user's name across sessions | **Factual** |
| Recall past conversations or learn user style | **Episodic** |
| Provide curated world/domain knowledge | **Semantic** |

---

## 8. Main takeaways

- LLMs are inherently **stateless** — memory systems are layered on top.
- **STM** = session-scoped, volatile, lives in the context window.
- **LTM** = persistent, stored externally, survives across sessions.
- LTM has **three sub-types**:
  - **Factual** → user facts
  - **Episodic** → past interactions
  - **Semantic** → real-world knowledge
- Picking the right memory type is a **design decision** when building AI agents — get it wrong, and the agent either forgets too much or "remembers" things it shouldn't.

---

## 9. Things I still want to figure out

- How is **STM** technically stored — in the prompt itself or in a separate buffer?
- How do agents decide **what to promote** from STM → LTM? (i.e., what's worth remembering?)
- How is **episodic memory retrieved** efficiently at scale (vector embeddings? summarization chains?)
- What are the **privacy implications** of persistent factual/episodic memory?
- How does memory interact with **RAG** (Retrieval-Augmented Generation)?

---

## 10. Follow-up notes (dedicated videos)

Each memory type gets its own dedicated note. Links below:

- [x] [[01 - Short-Term Memory in LLMs]] ✅
- [x] [[02 - Long-Term Memory in LLMs]] ✅
- [x] [[03 - Factual Memory in LLMs]] ✅
- [x] [[04 - Episodic Memory in LLMs]] ✅
- [x] [[05 - Semantic Memory in LLMs]] ✅

---

## Related
- [[AI-Productivity-and-Obsidian-Setup]]

