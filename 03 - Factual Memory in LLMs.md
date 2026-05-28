---
title: Factual Memory in LLMs
date: 2026-05-28
source: Video transcript
type: lecture-notes
status: in-progress
parent: "[[02 - Long-Term Memory in LLMs]]"
tags:
  - llm
  - memory
  - long-term-memory
  - factual-memory
  - user-facts
  - ai-agents
  - personalization
  - context-injection
related:
  - "[[00 - Types of Memory in LLMs]]"
  - "[[02 - Long-Term Memory in LLMs]]"
  - "[[01 - Short-Term Memory in LLMs]]"
---

# Factual Memory in LLMs

> [!abstract] TL;DR
> **Factual memory** is the **first sub-type of [[02 - Long-Term Memory in LLMs|Long-Term Memory]]**. It stores **stable facts about the user** — name, age, location, preferences. It's **small**, **slow-changing**, and **always injected into the context** of every session. Think of it as the "profile card" the agent never forgets.

> [!info] Where this fits
> Factual memory is one of three LTM sub-types, alongside [[04 - Episodic Memory in LLMs]] (past interactions) and [[05 - Semantic Memory in LLMs]] (world knowledge). See [[00 - Types of Memory in LLMs]] for the full taxonomy.

---

## 1. The Core Idea

Factual memory is:
- A **subtype of long-term memory** (so it's persistent and DB-backed).
- **Facts about the user** — not about the world, not about past chats.
- **Small** — typically 5–20 data points per user.
- **Slow-changing** — name/age don't change often; preferences change occasionally.
- **Always in context** — injected into **every** session's system prompt.

> **In one sentence:** Factual memory = the user's profile facts, always loaded into the LLM's context.

---

## 2. Definition (From the Lecture)

> **Factual memory = facts about the user**
>
> - Examples: name, age, location, email, phone, preferences.
> - **Always present** in the LLM's context.
> - A **small** chunk of memory — never thousands of entries.

---

## 3. What Counts as a Fact?

| Type of Fact | Example |
|---|---|
| **Identity** | First name, last name, full name |
| **Contact** | Email, phone number |
| **Location** | City, country, timezone |
| **Demographics** | Age, gender, language |
| **Preferences** | "Prefers Markdown output", "Likes short answers" |
| **Style** | Communication style (formal / casual / technical) |
| **Domain context** | "Works in finance", "Studies AI", "Vegan" |

> [!example] Concrete factual-memory entry
> ```json
> {
>   "name": "Jayanth",
>   "age": 28,
>   "location": "Bangalore",
>   "email": "jayanth@example.com",
>   "preferences": {
>     "output_format": "markdown",
>     "answer_length": "short",
>     "tone": "casual"
>   },
>   "language": "en-IN"
> }
> ```

---

## 4. The "Friend" Analogy

The speaker uses a great human analogy:

> When you think of your friend, you **don't remember every conversation** you've ever had with them. But you **do remember**:
> - Their name
> - Where they live
> - What they wear
> - What they like
>
> Those persistent, **summary-level facts** about a person? **That's factual memory.**

The forgotten conversations? Those would be **episodic memory** (covered next).

> [!tip] Mental model
> Factual memory is the **profile card** in your head — a small, stable set of facts. Episodic memory is the **album of moments** with that person.

---

## 5. Key Property: Always Injected

This is what makes factual memory special among the LTM sub-types:

> **Factual memory is pushed into the LLM's context on EVERY session.**

### Why it's safe to always inject
1. **It's small** — 5 to 20 facts, maybe a few hundred tokens.
2. **It's high-signal** — knowing the user's name + preferences improves nearly every reply.
3. **It rarely changes** — no need to re-fetch frequently.

### Contrast with other LTM sub-types
| Sub-type | Retrieval Pattern | Why |
|---|---|---|
| **Factual** | **Always** retrieve | Small + high value |
| **Episodic** | **When relevant** (semantic search) | Can be huge — must select |
| **Semantic** | **On demand** (RAG-style) | Domain knowledge — pull only what's needed |

---

## 6. How Factual Memory Plugs Into a Session

```
┌────────────────────────────────────────────────────────┐
│  User opens a new session                              │
│      │                                                  │
│      ▼                                                  │
│  Fetch factual memory from DB (small, ~10 entries)     │
│      │                                                  │
│      ▼                                                  │
│  Build system prompt:                                  │
│    "You are helping Jayanth, 28, from Bangalore.        │
│     He prefers markdown and short answers."            │
│      │                                                  │
│      ▼                                                  │
│  Conversation begins — LLM knows the user from turn 1  │
└────────────────────────────────────────────────────────┘
```

### Pseudocode

```python
def build_system_prompt(user_id):
    facts = db.get_factual_memory(user_id)   # tiny: 5-20 fields
    return f"""
    You are an AI assistant.
    User facts:
    - Name: {facts['name']}
    - Age: {facts['age']}
    - Location: {facts['location']}
    - Preferences: {facts['preferences']}
    """
```

> [!note]
> Compare this with episodic/semantic memory — those require **semantic search** to pick *which* memories to retrieve. Factual is simple: **fetch them all, always.**

---

## 7. Why Factual Memory Is "Cheap"

Because it's so small, factual memory:
- **Doesn't blow up the context window** (a few hundred tokens at most).
- **Doesn't need vector search** — a simple key-value or document lookup works.
- **Doesn't need ranking** — every fact is relevant.
- **Is easy to update** — overwrite the field; no embeddings to recompute.

> [!tip]
> If you're starting to build memory into an AI agent, **factual memory is the easiest win** — minimal infra, maximum personalization impact.

---

## 8. Storage Patterns

Factual memory fits a wide range of storage options:

| Storage | Why it works for factual memory |
|---|---|
| **MongoDB** | One document per user, all facts inside |
| **PostgreSQL** | Structured columns, strict schema |
| **Redis** | Ultra-fast lookups — great for high-traffic agents |
| **Mem0** | Handles factual storage + retrieval automatically |
| **JSON file** | Fine for prototypes and single-user agents |

Unlike episodic/semantic memory, you generally **don't need a vector DB** for factual memory.

---

## 9. Examples in Action

### Example 1 — A coding assistant
> "Hey Jayanth, since you work mostly in **Python**, here's the snippet..."

The agent knew "works in Python" because it's in factual memory.

### Example 2 — A health app
> "Good morning! Reminder: you've set your daily protein goal at 80g."

The goal (80g) is a stable user fact → factual memory.

### Example 3 — A writing assistant
> "Here's the draft in **markdown** with **short paragraphs**, as you prefer."

Output format preference = factual memory.

---

## 10. Gotchas & Best Practices

> [!warning] Watch out for these

- **Don't overstuff** — factual memory should stay small. Long histories belong in episodic.
- **Versioning** — if a fact changes (user moves cities), update with timestamp; don't keep both.
- **Validation** — don't blindly trust new "facts" extracted from chat. Confirm with the user where it matters.
- **Privacy** — factual memory holds the most sensitive PII. Encrypt at rest. Allow deletion.
- **One source of truth** — when the same fact lives in multiple places (signup form, chat-extracted), pick one canonical source.
- **Don't mix with state** — "current order #132" is **session state / STM**, not a fact.

---

## 11. Factual vs Episodic vs Semantic

| | Factual | Episodic | Semantic |
|---|---|---|---|
| **About** | The user | Past interactions with the user | The world |
| **Size** | Tiny (5–20 entries) | Large (grows continuously) | Large (curated knowledge base) |
| **Storage** | KV / document DB | Vector DB | Vector DB / RAG store |
| **Retrieval** | Always inject | When relevant | On demand |
| **Example** | "Name is Jayanth" | "Last week debugged auth bug" | "Delhi is the capital of India" |

---

## 12. Key Takeaways

- Factual memory = **facts about the user** (name, age, location, preferences).
- It's a **subtype of LTM** — persistent, DB-backed, user-scoped.
- It's **small** — typically 5–20 entries — so it's safe to **always inject** into the system prompt.
- Uses simple storage (Mongo, Postgres, Redis) — **no vector search needed**.
- The friend analogy: it's the small, stable "profile" you carry about someone in your head.
- It's the **easiest, highest-ROI memory** to add to an AI agent.

---

## 13. Open Questions

- How does the agent decide which **new** facts to commit to factual memory (vs ignore as noise)?
- When a user says something that **contradicts** an existing fact, how do you reconcile?
- Should preferences be **inferred** from behavior or only stored when **explicitly stated**?
- What's the right strategy when factual memory **does** grow past 50+ entries — start sub-categorizing? Move into episodic?

---

## 14. Coming Up Next

- [[04 - Episodic Memory in LLMs]] — past interactions & patterns (large, retrieved when relevant)
- [[05 - Semantic Memory in LLMs]] — general world knowledge (curated, retrieved on demand)

---

## Related
- [[00 - Types of Memory in LLMs]] — top-level taxonomy
- [[02 - Long-Term Memory in LLMs]] — the parent LTM concept
- [[01 - Short-Term Memory in LLMs]] — session-scoped counterpart

## Sources
- Video transcript (dedicated factual memory lecture).
