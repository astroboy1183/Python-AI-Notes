---
title: Section Intro - Graph Memory
date: 2026-05-29
source: "Section 14 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 14: Graph Memory and Knowledge Graphs In AI Agents"
tags:
  - graph-memory
  - knowledge-graph
  - neo4j
  - memory
  - section-intro
related:
  - "[[02 - What is a Graph]]"
  - "[[09 - Building a Memory-Aware Assistant]]"
---

# Section Intro — Graph Memory

> [!NOTE]
> **TL;DR**
> Having built vector-based memory in Section 13, this section adds a sharper tool: **graph memory**. The plan — understand what a **graph** is, what a **graph database** is, set up **Neo4j**, and most importantly see the role a **knowledge graph** plays in a memory assistant: what problem it solves and why a graph-like structure stores memories *more efficiently* than vectors alone. The key gap it fills: vectors store facts well but lose **relationships** between them. This section is squarely for **power users** of memory.

> [!NOTE]
> **Where this fits**
> First note of **Section 14: Graph Memory and Knowledge Graphs in AI Agents**. It builds directly on the Mem0 + Qdrant memory assistant from [[09 - Building a Memory-Aware Assistant]]. The conceptual groundwork starts in [[02 - What is a Graph]].

---

## 1. Why this section exists

Section 13 ended with a working memory-aware assistant: facts about me get extracted, embedded, and stored in a vector DB (Qdrant), then the relevant ones are pulled back per query. That covers *"what do I know about the user?"* well.

What it **doesn't** capture is **how facts relate to each other**. Vectors are great at "this text is similar to that text," but they don't natively model *"Jayanth works at Google, and so does Jane, therefore they're co-workers."* Those connections are exactly what a **graph** is built for.

```
vector memory:   stores facts          (Jayanth likes pizza)
graph memory:    stores facts + EDGES  (Jayanth)──[likes]──►(pizza)
                                        (Jayanth)──[works_at]──►(Google)◄──[works_at]──(Jane)
```

---

## 2. What the section will cover

| Topic | Note |
|---|---|
| What a graph is (nodes, edges, directed/undirected) | [[02 - What is a Graph]] |
| Why graphs help memory (relationships vectors miss) | [[03 - Why Graphs for Memory]] |
| Graph databases — Neo4j vs alternatives | [[04 - Graph Databases]] |
| Standing up a Neo4j Aura cloud instance | [[05 - Setting up Neo4j Aura]] |
| Cypher query basics | [[06 - Cypher Queries]] |
| Wiring Neo4j into Mem0 as a graph store | [[07 - Adding Neo4j Graph Store to Mem0]] |
| Watching Mem0 auto-build a knowledge graph | [[08 - Building the Knowledge Graph]] |

---

## 3. The mental shift

```
Section 13:  memory = facts in a vector DB
Section 14:  memory = facts in a vector DB  +  relationships in a graph DB
```

The two are complementary, not competing. Mem0 can use **both** a vector store (Qdrant) for semantic recall *and* a graph store (Neo4j) for relationship-aware recall — which is exactly what gets configured later in this section.

---

## 4. What I want to remember

- This section adds **graph memory** on top of vector memory.
- The core motivation: vectors store facts, **graphs store relationships**.
- Tooling: **Neo4j** as the graph database, queried with **Cypher**.
- A **knowledge graph** lets the assistant reason over *connections*, not just similarity.
- It's a **power-user** layer — optional, but powerful for richer memory.

---

## 5. Things to dig into

- **Neo4j**: https://neo4j.com/
- **Mem0 graph memory**: https://docs.mem0.ai/
- How vector recall and graph traversal **combine** in one memory system.

---

## 6. Next up in this section

- [ ] [[02 - What is a Graph]] — the data structure: nodes, edges, directed vs undirected.

---

## Related
- [[09 - Building a Memory-Aware Assistant]] — the vector-memory build this extends.
- [[02 - What is a Graph]] — the conceptual starting point.

## Sources
- [Neo4j](https://neo4j.com/)
- [Mem0 documentation](https://docs.mem0.ai/)
