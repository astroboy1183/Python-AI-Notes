---
title: Semantic Memory in LLMs
date: 2026-05-28
source: Video transcript
type: lecture-notes
status: in-progress
parent: "[[02 - Long-Term Memory in LLMs]]"
tags:
  - llm
  - memory
  - long-term-memory
  - semantic-memory
  - world-knowledge
  - ai-agents
  - rag
  - knowledge-base
  - on-demand-retrieval
related:
  - "[[00 - Types of Memory in LLMs]]"
  - "[[02 - Long-Term Memory in LLMs]]"
  - "[[03 - Factual Memory in LLMs]]"
  - "[[04 - Episodic Memory in LLMs]]"
  - "[[01 - Short-Term Memory in LLMs]]"
---

# Semantic Memory in LLMs

> [!abstract] TL;DR
> **Semantic memory** is the **third (and final) sub-type of [[02 - Long-Term Memory in LLMs|Long-Term Memory]]**. It stores **general world knowledge** — facts about reality, not about the user, not about past events. Things like *"Paris is the capital of France"* or curated domain templates. It's retrieved **on demand** when the conversation needs that knowledge. You usually don't need to worry about it much in early agent designs.

> [!info] Where this fits
> Semantic memory is the third LTM sub-type, alongside [[03 - Factual Memory in LLMs]] (about the user) and [[04 - Episodic Memory in LLMs]] (past interactions). See [[00 - Types of Memory in LLMs]] for the full taxonomy.

---

## 1. The Core Idea

Semantic memory is:
- A **subtype of long-term memory** (persistent, DB-backed).
- **General-purpose knowledge** — about the world, not the user.
- **Not tied to a specific user** — shared knowledge base.
- **Not tied to specific past events** — timeless facts, not episodes.
- **Retrieved on demand** — pulled in when the topic comes up.

> **In one sentence:** Semantic memory = the agent's general-knowledge encyclopedia, fetched when relevant.

---

## 2. Definition (From the Lecture)

> **Semantic memory = general knowledge.**
>
> - **Nothing about the user.**
> - **Nothing about a specific episode.**
> - Just general, real-world information.
> - Examples: *"Paris is the capital of France"*, *"Delhi is the capital of India"*, reusable templates / patterns.

---

## 3. Examples of Semantic Memories

| Type of Knowledge | Example |
|---|---|
| **Geographic / civic facts** | "Paris is the capital of France." |
| **Scientific facts** | "Water boils at 100°C at sea level." |
| **Domain facts** | "REST APIs use HTTP verbs (GET, POST, PUT, DELETE)." |
| **Reusable templates** | A standard JSON-parsing snippet, a boilerplate email format. |
| **Definitions** | "A vector database stores embeddings for similarity search." |
| **Patterns / heuristics** | "When debugging null errors, always check inputs first." |

> [!note]
> All of these are **not about the user** and **not tied to a specific event** in the user's life. They're just **timeless, general truths** or **reusable patterns**.

---

## 4. The Library Analogy

If we extend the previous analogies:

- [[03 - Factual Memory in LLMs|Factual]] = your friend's **profile card** in your head.
- [[04 - Episodic Memory in LLMs|Episodic]] = your **diary** of moments with them.
- **Semantic** = the **library / encyclopedia** you both share — generic knowledge anyone could look up.

> [!tip] Mental model
> Semantic memory is the **library** the agent walks over to whenever the conversation needs a generic fact or template. It's not personal — it's reference material.

---

## 5. Why Semantic Is "Not Always Injected"

Like episodic memory, semantic memory is **on-demand**, not always-loaded. Why?

1. **It's potentially huge** — a curated knowledge base can contain millions of facts.
2. **Most facts are irrelevant** to any given conversation.
3. **Context window** is finite — would be wasted on unrelated knowledge.
4. **Cost** — paying tokens for unused background knowledge is wasteful.

So you **retrieve only what's relevant** to the current question.

---

## 6. Semantic vs. the LLM's Pretrained Knowledge

This is a subtle but important point.

> [!warning] Important nuance
> The LLM already "knows" Paris is the capital of France **from its training data**. So why store it in semantic memory?

You'd add semantic memory when you need:
- **Curated, vetted facts** — sources you trust.
- **Up-to-date knowledge** — newer than the model's training cutoff.
- **Domain-specific knowledge** — internal company docs, niche field info.
- **Reusable templates** — code snippets, boilerplates, formats the agent should reuse.
- **Authoritative reference** — when "the model might know" isn't good enough.

In other words: **semantic memory is for knowledge you want the agent to use reliably**, not just stuff it might have absorbed at training time.

---

## 7. On-Demand Retrieval Flow

```
┌──────────────────────────────────────────────────────────┐
│  User: "What's the capital of France?"                   │
│      │                                                    │
│      ▼                                                    │
│  LLM (or orchestrator) recognizes a knowledge query      │
│      │                                                    │
│      ▼                                                    │
│  Trigger RAG / tool call → semantic memory store          │
│      │                                                    │
│      ▼                                                    │
│  Vector search returns matching knowledge entries        │
│      │                                                    │
│      ▼                                                    │
│  Knowledge injected into prompt as context               │
│      │                                                    │
│      ▼                                                    │
│  LLM responds: "Paris is the capital of France."         │
└──────────────────────────────────────────────────────────┘
```

This is essentially a classic **RAG (Retrieval-Augmented Generation)** pipeline — semantic memory and RAG are very close cousins.

---

## 8. How Semantic Memory Is Stored

Typical storage choices:

| Storage | Why it works |
|---|---|
| **Vector DB** (Qdrant, Pinecone, Weaviate, Chroma) | Semantic search over knowledge chunks |
| **PostgreSQL + pgvector** | Relational + vector hybrid |
| **Elasticsearch / OpenSearch** | Full-text + vector hybrid search |
| **Knowledge graph** (Neo4j) | When facts are deeply related (entities + relationships) |
| **Markdown / docs in a folder** + RAG | Simple knowledge bases (e.g., team wikis) |
| **Mem0** | Abstracted semantic store |

Just like [[04 - Episodic Memory in LLMs|episodic]], semantic memory typically wants **semantic search** capability → **vector DBs** dominate.

---

## 9. Pseudocode

```python
def handle_user_message(user_id, user_msg, message_history):
    # 1. Is the user asking a general-knowledge question?
    if needs_world_knowledge(user_msg):
        # 2. Embed the question
        query_vec = embed(user_msg)

        # 3. Search the semantic knowledge base (shared, not per-user)
        knowledge = semantic_store.search(
            vector=query_vec,
            top_k=5
        )

        # 4. Inject as context
        message_history.insert(0, {
            "role": "system",
            "content": f"Relevant background knowledge:\n{format(knowledge)}"
        })

    return llm.chat(messages=message_history)
```

> [!note] Key difference from episodic
> Notice: semantic memory is **not scoped by `user_id`**. It's a shared knowledge base across all users.

---

## 10. The Three LTM Sub-types — Final Recap

| Sub-type | About | Scope | Retrieval | Size | Storage |
|---|---|---|---|---|---|
| **Factual** | The user | Per-user | **Always inject** | Tiny (5–20) | KV / Document DB |
| **Episodic** | Past interactions with the user | Per-user | **On demand** | Large, growing | Vector DB |
| **Semantic** | The world / domain | **Shared (no user)** | **On demand** | Large, curated | Vector DB / RAG |

> [!tip] One-liners
> - **Factual** = who the user **is** → always loaded.
> - **Episodic** = what happened **with** the user → recalled when triggered.
> - **Semantic** = what is **true** in the world → fetched when topic appears.

---

## 11. Why You Often Don't Need to Worry About It

The speaker says:

> *"You usually don't have to worry about a semantic memory a lot."*

Why?
- The LLM already has **massive pretrained world knowledge**.
- For most agents, factual + episodic memory carries the personalization weight.
- Semantic memory becomes important when:
  - You're building a **domain-specific assistant** (legal, medical, enterprise docs).
  - You need **authoritative or up-to-date** info.
  - You want to **constrain** the agent's answers to a known knowledge base.

> [!info]
> If you're starting out, prioritize **factual** first, then **episodic**. Add **semantic** only when you have curated knowledge worth retrieving.

---

## 12. Gotchas & Best Practices

> [!warning] Watch out for these

- **Don't duplicate pretrained knowledge** unless you need authoritative / fresher sources.
- **Source attribution** — track where each semantic fact came from; useful for trust + audit.
- **Versioning / freshness** — world knowledge can become outdated (e.g., political leadership changes). Add timestamps.
- **Chunking strategy** — for big docs, how you split affects retrieval quality (paragraphs vs sentences vs semantic chunks).
- **Embedding consistency** — same embedding model across writes + queries.
- **Hybrid search** — combine vector similarity with keyword/BM25 for robust retrieval.
- **Don't confuse with user data** — semantic memory has **no user scoping**.

---

## 13. Key Takeaways

- Semantic memory = **general world knowledge** stored in an external knowledge base.
- **Not user-specific.** **Not episode-specific.** Just **facts about reality / domain**.
- A **subtype of LTM** — persistent, DB-backed (usually a vector DB).
- Retrieved **on demand** (RAG-style) when the topic comes up.
- Often **not the first memory you build** — pretrained LLM knowledge handles a lot already.
- Becomes critical for **domain-specific** or **knowledge-grounded** agents.

---

## 14. Open Questions

- **When to override pretrained knowledge** — should retrieved semantic facts always win over the model's prior?
- **Conflict between semantic and episodic** — what if a user remembered something that contradicts a "known" fact?
- **Building the knowledge base** — manual curation vs auto-ingest from docs vs hybrid?
- **Citation** — should the agent always cite which semantic source a fact came from?
- **Privacy** — semantic memory is usually safe, but is anything inferred from user data leaking in?

---

## 15. Series Complete — The Full Memory Taxonomy

This wraps up the **four memory types**:

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
                     (always)        (on demand)      (on demand)
```

| Memory | Lives in | When loaded |
|---|---|---|
| [[01 - Short-Term Memory in LLMs\|Short-Term]] | Context window / message history | Active session only |
| [[03 - Factual Memory in LLMs\|Factual]] | KV / Document DB | **Every** session — always |
| [[04 - Episodic Memory in LLMs\|Episodic]] | Vector DB | **When triggered** (e.g., "remember when...") |
| **Semantic** (this note) | Vector DB / RAG store | **When topic comes up** |

---

## 16. Coming Up Next

The next video sets up the practical infrastructure:

- [ ] [[Mem0 with Qdrant - Setup]] — installing & configuring Mem0 with Qdrant DB to start building a real memory-enabled agent.

---

## Related
- [[00 - Types of Memory in LLMs]] — top-level taxonomy
- [[02 - Long-Term Memory in LLMs]] — the parent LTM concept
- [[03 - Factual Memory in LLMs]] — sibling: user facts (always)
- [[04 - Episodic Memory in LLMs]] — sibling: past interactions (on demand)
- [[01 - Short-Term Memory in LLMs]] — the volatile counterpart

## Sources
- Video transcript (dedicated semantic memory lecture).
- Referenced tools: [Qdrant](https://qdrant.tech), [Mem0](https://mem0.ai), vector databases for RAG-style retrieval.
