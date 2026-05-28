---
title: Episodic Memory in LLMs
date: 2026-05-28
source: Video transcript
type: lecture-notes
status: in-progress
parent: "[[02 - Long-Term Memory in LLMs]]"
tags:
  - llm
  - memory
  - long-term-memory
  - episodic-memory
  - past-interactions
  - ai-agents
  - vector-database
  - rag
  - on-demand-retrieval
  - semantic-search
related:
  - "[[00 - Types of Memory in LLMs]]"
  - "[[02 - Long-Term Memory in LLMs]]"
  - "[[03 - Factual Memory in LLMs]]"
  - "[[01 - Short-Term Memory in LLMs]]"
---

# Episodic Memory in LLMs

> [!abstract] TL;DR
> **Episodic memory** is the **second sub-type of [[02 - Long-Term Memory in LLMs|Long-Term Memory]]**. It stores **specific past events and interactions** with the user — long, detailed, ever-growing. Unlike [[03 - Factual Memory in LLMs|factual memory]] (always injected), episodic memory is **retrieved on demand** via a tool call / RAG / vector search — only when the conversation touches something relevant. Think of it as the agent's **journal** of past moments with the user.

> [!info] Where this fits
> Episodic is the **middle** sub-type of LTM: bigger than [[03 - Factual Memory in LLMs]], more user-specific than [[05 - Semantic Memory in LLMs]]. See [[00 - Types of Memory in LLMs]] for the full taxonomy.

---

## 1. The Core Idea

Episodic memory is:
- A **subtype of long-term memory** (persistent, DB-backed).
- **Information about past interactions / events** with the user.
- **Large** — grows continuously as users chat over weeks and months.
- **Retrieved on demand** — *not* always in context.
- Triggered by conversational cues like *"Remember when..."* or *"Last time we..."*.

> **In one sentence:** Episodic memory = the agent's recallable log of past events with the user, fetched only when the conversation needs it.

---

## 2. Definition (From the Lecture)

> **Episodic memory = information about previous interactions / specific past events.**
>
> - Long, detailed, conversation-like.
> - **Not always sent to the LLM** — would blow up the context.
> - Retrieved **on demand** via tool call / RAG when the user references the past.

---

## 3. Examples of Episodic Memories

| Type of Episode | Example |
|---|---|
| **Past trip / event** | "User went to Paris in 2023." |
| **Past decision** | "We chose PostgreSQL over MongoDB last sprint." |
| **Past outcome** | "Last time we deployed this model, latency increased." |
| **Past topic** | "User asked about LangChain last week and found it verbose." |
| **Past frustration / preference signal** | "User dislikes long answers — confirmed during chat on May 15." |
| **Past goal** | "User started prepping for AWS cert exam in March." |

> [!note]
> Notice these are all **specific, dated, contextual events** — not stable facts. They're the kinds of things you'd write in a diary, not on a profile card.

---

## 4. The Diary Analogy

If [[03 - Factual Memory in LLMs|factual memory]] is your friend's **profile card** (name, where they live), then episodic memory is your **diary of moments with them**:

- "Last summer, we hiked in the Alps."
- "She told me she's switching jobs in March."
- "We disagreed about that movie."

You don't recite the whole diary every time you meet them. Instead, when something **triggers a memory** — *"Oh, this reminds me of when we..."* — you flip back to the relevant page.

> [!tip] Mental model
> Episodic memory = the agent's **diary** with the user. Always recorded. Selectively recalled.

---

## 5. Why It's NOT Always Injected

Why can't we just dump episodic memory into the system prompt like factual?

1. **It's huge** — months of chats = thousands of entries.
2. **Context window** — would blow the model's token budget instantly.
3. **Cost** — paying tokens for irrelevant old episodes is wasteful.
4. **Noise** — irrelevant past episodes confuse the model and degrade reasoning.

> [!warning] The key constraint
> You **cannot** preload all episodic memories. You **must** retrieve **only the relevant ones**, **when** they become relevant.

---

## 6. The "On-Demand" Retrieval Flow

Here's what happens when an episodic-style question comes in:

```
┌──────────────────────────────────────────────────────────┐
│  User: "Do you remember when I visited Paris?"           │
│      │                                                    │
│      ▼                                                    │
│  LLM recognizes: this is an episodic-memory query        │
│      │                                                    │
│      ▼                                                    │
│  LLM triggers a tool call / RAG retrieval                │
│      │                                                    │
│      ▼                                                    │
│  Vector DB (Qdrant, Pinecone, ...) searched for          │
│    semantically similar past episodes                    │
│      │                                                    │
│      ▼                                                    │
│  Top-K matching episodes returned (e.g., the Paris one)  │
│      │                                                    │
│      ▼                                                    │
│  Episodes injected into the prompt as context            │
│      │                                                    │
│      ▼                                                    │
│  LLM responds: "Yes — based on our past chat, you        │
│   went to Paris in 2023..."                              │
└──────────────────────────────────────────────────────────┘
```

> [!quote] From the transcript
> "If user asks a question which you feel is episodic memory… your LLM decides, oh, it's kind of an episodic memory. So now you can do a tool call, you can do a RAG, you can go into your vector DB or wherever these conversations are stored, you can retrieve that particular point."

---

## 7. Trigger Phrases (How LLM Decides to Look)

The LLM (or your orchestration layer) usually recognizes episodic-memory cues like:

- *"Do you remember when..."*
- *"Last time we..."*
- *"What did I tell you about..."*
- *"Have we discussed... before?"*
- *"What was the result when we tried..."*
- Any reference to a **specific past event** or **time**.

When these triggers fire → **run a retrieval** → inject results → answer.

---

## 8. How Episodic Memory Is Stored

Because it must be **searchable by meaning**, episodic memory typically lives in a **vector database**:

| Storage | Why it fits |
|---|---|
| **Qdrant** | Open-source vector DB; great for similarity search over past chats |
| **Pinecone** | Managed vector DB |
| **Weaviate / Chroma / Milvus** | Other vector DB options |
| **Mem0** | Abstracts episodic storage + retrieval |
| **PostgreSQL + pgvector** | Vector search inside a relational DB |
| **Graph DB (Neo4j)** | When episodes are richly connected (people, places, projects) |

### Why not a regular DB?
- You don't know **which episode** you'll need ahead of time.
- You need to search by **meaning**, not exact keywords.
- Vector embeddings let you ask *"find episodes similar to 'Paris trip'"* — even if the user said *"my visit to France"*.

---

## 9. Pseudocode

```python
def handle_user_message(user_id, user_msg, message_history):
    # 1. Decide: is this an episodic-memory query?
    if needs_episodic_recall(user_msg):
        # 2. Embed the question
        query_vec = embed(user_msg)

        # 3. Search vector DB for top-K similar past episodes
        episodes = vector_db.search(
            user_id=user_id,
            vector=query_vec,
            top_k=5
        )

        # 4. Inject retrieved episodes into context
        message_history.insert(0, {
            "role": "system",
            "content": f"Relevant past episodes:\n{format(episodes)}"
        })

    # 5. Call the LLM
    return llm.chat(messages=message_history)

def end_session(user_id, message_history):
    # 6. Summarize and store new episodes from this session
    new_episodes = extract_episodes(message_history)
    for ep in new_episodes:
        vector_db.upsert(user_id=user_id, vector=embed(ep), payload=ep)
```

> [!example] Two phases
> - **Write**: at the end of (or during) sessions, extract and embed memorable episodes → vector DB.
> - **Read**: during sessions, when a trigger fires → semantic search → inject top-K.

---

## 10. Concrete Walkthrough — The Paris Example

1. **Months ago**, the user mentioned: *"I went to Paris in 2023, it was amazing."*
2. The agent stored this as an episode: `{"user_id": "piyush", "text": "Visited Paris in 2023, enjoyed it", "date": "2023-..."}`. Embedded and saved in Qdrant.
3. **Today**, the user opens a new session: *"Do you remember when I went to Paris?"*
4. The LLM flags this as an episodic query → calls the retrieval tool.
5. Vector search returns the Paris episode (high similarity).
6. The episode is injected into the system prompt.
7. The LLM replies: *"Yes — you mentioned visiting Paris back in 2023 and really enjoyed it."*

---

## 11. Factual vs Episodic — Side by Side

| | Factual | Episodic |
|---|---|---|
| **About** | Who the user is | What happened with the user |
| **Size** | Small (5–20 entries) | Large (grows continuously) |
| **Updates** | Rare (name, age, prefs change slowly) | Constant (new episodes after each session) |
| **Storage** | Document DB / KV store | **Vector DB** (semantic search needed) |
| **Retrieval** | **Always inject** | **On demand** (semantic search) |
| **Trigger** | Every session | Cue phrases like "remember when..." |
| **Example** | "Name is Piyush" | "Visited Paris in 2023" |

---

## 12. Gotchas & Best Practices

> [!warning] Watch out for these

- **Don't store everything verbatim** — summarize episodes; raw chat logs are noisy + huge.
- **Top-K tuning** — too few = miss relevant memories; too many = noise + token cost. Often K=3–10 works.
- **Recency vs relevance** — sometimes recent matters more than semantically similar. Hybrid scoring helps.
- **Conflicting episodes** — old episodes may be outdated ("loved Paris" → "Paris was overrated"). Use timestamps.
- **Embedding drift** — if you change embedding models, you must re-embed everything.
- **Privacy** — episodic memory is *very* personal. Honor deletion requests and isolate per user.
- **Avoid double storage** — extract facts → push to factual; keep episodes lean.

---

## 13. The Three LTM Sub-types — Where Episodic Sits

| Sub-type | Retrieval | Size | Storage |
|---|---|---|---|
| [[03 - Factual Memory in LLMs|Factual]] | **Always** | Tiny | KV / Document DB |
| **Episodic** (this note) | **On demand** | Large | Vector DB |
| [[05 - Semantic Memory in LLMs|Semantic]] | **On demand** | Large | Vector DB / RAG store |

> [!note] Factual vs episodic vs semantic in one line each
> - **Factual** = profile facts about the user → always loaded.
> - **Episodic** = past events with the user → recalled when triggered.
> - **Semantic** = facts about the world → fetched when topic comes up.

---

## 14. Key Takeaways

- Episodic memory = **specific past interactions / events** with the user.
- Subtype of **LTM** — persistent, DB-backed.
- **Large** and **growing** → cannot always be injected.
- Retrieved **on demand** via tool call / RAG / vector search.
- Triggered by conversational cues ("Remember when…", "Last time…").
- Stored in a **vector DB** (Qdrant, Pinecone, Mem0, pgvector...) for semantic search.
- The diary analogy: the agent writes everything down, but only flips to the right page when something reminds it.

---

## 15. Open Questions

- **What counts as a memorable episode?** Every turn? Or only "significant" ones? Who decides?
- **How to summarize episodes** before storing — verbatim, summary, or structured (who/what/when/where)?
- **Hybrid retrieval** — should we combine vector similarity with recency and importance?
- **How to handle outdated episodes?** Mark stale? Decay weights?
- **Cross-session privacy** — what if a user wants to forget a specific episode?

---

## 16. Coming Up Next

- [[05 - Semantic Memory in LLMs]] — general world knowledge (not user-specific), retrieved on demand.

---

## Related
- [[00 - Types of Memory in LLMs]] — top-level taxonomy
- [[02 - Long-Term Memory in LLMs]] — the parent LTM concept
- [[03 - Factual Memory in LLMs]] — sibling: always-injected user facts
- [[01 - Short-Term Memory in LLMs]] — session-scoped counterpart

## Sources
- Video transcript (dedicated episodic memory lecture).
- Referenced tools: [Qdrant](https://qdrant.tech), [Mem0](https://mem0.ai), vector databases for semantic search.
