---
title: Why Graphs for Memory
date: 2026-05-29
source: "Section 14 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 14: Graph Memory and Knowledge Graphs In AI Agents"
tags:
  - knowledge-graph
  - memory
  - relationships
  - vector-db
  - graph-traversal
related:
  - "[[02 - What is a Graph]]"
  - "[[04 - Graph Databases]]"
  - "[[09 - Building a Memory-Aware Assistant]]"
---

# Why Graphs for Memory

> [!NOTE]
> **TL;DR**
> Vector memory stores **facts** well — "your name is Jayanth," "you like pizza" — but it **loses relationships** between them. That's the gap a graph fills. Example: a company X *employs* John and *employs* Jane. From those two edges a graph can **infer** that John and Jane are **co-workers** — a relationship nobody stored explicitly. It also enables **traversal**: Jane asks "who's my owner?" → follow Jane→company→owner → "Alex owns X, report to Alex." Vectors can't do this — they match similar text, not connected entities. Graphs give you **direct relationships**, **inferred/indirect relationships** ("you like X, so you may like Y and Z"), and **multi-hop traversal**. Humans reason this way too — by connection, not just similarity.

> [!NOTE]
> **Where this fits**
> Third note of **Section 14**. It motivates *why* to bolt a graph onto the vector memory from [[09 - Building a Memory-Aware Assistant]]. [[04 - Graph Databases]] then picks the tool (Neo4j).

---

## 1. What vectors store — and what they miss

The Section 13 memory assistant stored facts in a vector DB:

```
✅ "your name is Jayanth"
✅ "you like pizza"
```

That works for recall by similarity. But ask it about **connections between facts** and it has nothing:

```
❌ "how is Jayanth related to Jane?"
❌ "who should Jane report to?"
```

> [!IMPORTANT]
> **Vectors store facts; they don't store relationships**
> Vector embeddings answer *"what text is similar to this query?"*. They have no notion of *"entity A is connected to entity B via relationship R."* Relationships are precisely what a graph adds.

---

## 2. The worked example — a company and its people

Set up a few nodes and edges:

```
(Company X) ──[employs]──► (John)
(Company X) ──[employs]──► (Jane)
(Alex) ──[owns]──► (Company X)
```

So: Company X employs John and Jane; Alex owns Company X.

---

## 3. Inferred relationships — co-workers for free

Here's the magic. Nobody ever stored *"John and Jane are co-workers."* But the graph can **derive** it:

```
(John) ◄──[employs]── (Company X) ──[employs]──► (Jane)
        │                                          │
        └──────────── co-workers (inferred) ───────┘
```

Because both John and Jane share an `employs` edge from the same company, the graph **figures out** they're co-workers. This kind of **semantic, structural inference is not possible with vectors**.

So if John says *"I want to talk about Jane,"* the graph can establish the relationship between them: **co-working**.

---

## 4. Traversal — answering "who do I talk to?"

Graphs let you **walk** edges to answer relational questions:

> Jane asks: *"Who is my owner? Who should I talk to?"*

The graph traverses:

```
(Jane) ──[employee_of]──► (Company X) ◄──[owns]── (Alex)
   start                      hop 1                answer
```

1. Start at Jane.
2. Follow her `employee_of` edge → Company X.
3. Find who `owns` Company X → Alex.
4. Answer: *"You're employed by Company X, which is owned by Alex — report to Alex."*

Likewise, if Jane wants a **co-worker to chat with**, traverse Jane → Company X → all `employees` → pick one. Pure graph traversal; impossible by vector similarity.

---

## 5. The three things graphs add

| Capability | What it means | Vector DB? |
|---|---|---|
| **Direct relationships** | A is connected to B via R | ❌ |
| **Inferred / indirect relationships** | "you like X → you may like Y, Z" | ❌ |
| **Multi-hop traversal** | walk edges to answer "who/what is reachable" | ❌ |

```
direct:    (Jayanth) ──[likes]──► (pizza)
inferred:  (Jayanth) ──[likes]──► (pizza) ◄──[likes]── (Jane)   ⇒ shared taste
traversal: (Jane) → (Company X) → (Alex)                        ⇒ reporting line
```

---

## 6. Why this matches how humans think

Human memory is associative — we recall by **connection**, not just by content similarity. "Who do I know at Google?" triggers a walk through related people, not a fuzzy text search. A knowledge graph models memory the way our minds actually link things, which is why it complements vector recall so well.

---

## 7. The takeaway: use both

> [!TIP]
> **Graph + vector, not graph vs vector**
> Keep the vector store for "recall facts similar to this query," and add a **knowledge graph** for "recall how these facts/entities relate." Together they give a richer, more human-like memory. This is exactly the dual-store setup configured later ([[07 - Adding Neo4j Graph Store to Mem0]]).

---

## 8. Main takeaways

- Vector memory stores **facts**; it **misses relationships**.
- A **graph** captures relationships between entities — and can **infer** new ones (co-workers from shared employer).
- Graphs enable **traversal**: walk edges to answer "who/what is connected" (Jane → company → owner).
- Three additions: **direct** relationships, **indirect/inferred** relationships, **multi-hop traversal**.
- Use a **knowledge graph alongside** vector memory, not instead of it.
- This mirrors **human associative memory** — recall by connection.

---

## 9. Things I still want to figure out

- How does the system **decide which entities/edges** to extract from a conversation? (Mem0's LLM does it — [[08 - Building the Knowledge Graph]].)
- How are **inferred** relationships computed — at write time or query time?
- How deep can **multi-hop** traversal go before it's too slow/noisy?
- How do graph results get **merged** with vector results in one answer?

---

## 10. Things to dig into

- **Knowledge graphs** in production memory systems.
- **Graph traversal / pathfinding** queries (Cypher — [[06 - Cypher Queries]]).
- Cross-link: [[09 - Building a Memory-Aware Assistant]] (the vector half).

---

## 11. Next up in this section

- [ ] [[04 - Graph Databases]] — where to store all this: Neo4j and the alternatives.

---

## Related
- [[02 - What is a Graph]] — the structure being applied here.
- [[04 - Graph Databases]] — the storage choice.
- [[09 - Building a Memory-Aware Assistant]] — the vector memory this complements.

## Sources
- [Neo4j: graphs for knowledge](https://neo4j.com/use-cases/knowledge-graph/)
- [Mem0 graph memory](https://docs.mem0.ai/)
