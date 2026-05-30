---
title: What is a Graph
date: 2026-05-29
source: "Section 14 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 14: Graph Memory and Knowledge Graphs In AI Agents"
tags:
  - graph
  - data-structure
  - nodes
  - edges
  - directed-graph
  - foundations
related:
  - "[[01 - Section Intro - Graph Memory]]"
  - "[[03 - Why Graphs for Memory]]"
---

# What is a Graph

> [!NOTE]
> **TL;DR**
> A **graph** is a set of **nodes** (which carry data) connected by **edges** (the connections). The whole point of a graph is to represent **relationships** — how one node relates to another, and *what kind* of relationship it is (e.g. node A —[X]→ node B). Edges come in two flavours: a **directed** edge has an arrow (one-way, like "A is parent of B" — but B is not parent of A), while an **undirected** edge has no arrow (mutual, like "A and B are friends"). That's the entire data structure — nodes, edges, and optionally direction. Everything in this section's knowledge graph builds on these three ideas.

> [!NOTE]
> **Where this fits**
> Second note of **Section 14** — a quick refresher on the graph data structure, independent of memory. [[03 - Why Graphs for Memory]] connects it to why graphs make memory better.

---

## 1. The two building blocks

A graph has exactly two ingredients:

| Element | What it is |
|---|---|
| **Node** | A thing that carries data (a person, a company, a food) |
| **Edge** | A connection between two nodes (a relationship) |

```
   (A)───────(B)
    │          
    │          
   (C)        
```

`(A)`, `(B)`, `(C)` are **nodes**. The lines between them are **edges**.

---

## 2. Edges represent relationships

A graph doesn't just say "these two nodes are connected" — an edge can carry **what kind** of relationship it is:

```
(A) ──[ X ]──► (B)
```

Read as: *node A is connected to node B with relationship X.* That label is what makes a graph expressive — it's not just structure, it's **meaning**.

Concretely:

```
(Jayanth) ──[ works_at ]──► (Google)
(Jayanth) ──[ likes ]─────► (pizza)
```

A graph **represents a flow / relationships** — how nodes relate, and the nature of each relation.

---

## 3. Directed vs undirected graphs

The one nuance worth knowing: edges may or may not have a **direction**.

### Directed graph — one-way

```
(A) ──────► (B)
```

The arrow points one way. A relates to B, but **B does not (necessarily) relate back to A**.

> Example: `(A) ──[parent_of]──► (B)`. A is parent of B. B is **not** parent of A. The relationship only makes sense in one direction.

### Undirected graph — mutual

```
(A) ────── (B)
```

No arrow. The relationship is **symmetric** — it holds both ways.

> Example: `(A) ──[friends]── (B)`. On Facebook, when you accept a friend request, **both** become friends of each other. There's no direction — it's mutual.

| Type | Arrow? | Meaning | Example |
|---|---|---|---|
| **Directed** | Yes (one-way) | Relationship holds A→B only | parent_of, works_at, follows |
| **Undirected** | No | Relationship is mutual | friends_with, married_to |

---

## 4. Why direction matters for memory

Most real relationships are **directional**, and the direction carries information:

```
(Jane) ──[employee_of]──► (Google) ◄──[owns]── (Alex)
```

From this I can traverse: Jane is an *employee of* Google; Alex *owns* Google. The directions tell me Alex is "above" Jane in the org — something a directionless link couldn't express. (This traversal idea is the heart of [[03 - Why Graphs for Memory]].)

---

## 5. The whole structure in one picture

```
        ┌─────────┐  works_at   ┌─────────┐  owns   ┌──────┐
        │ Jayanth │ ──────────► │ Google  │ ◄────── │ Alex │
        └─────────┘             └─────────┘         └──────┘
             │ likes                ▲
             ▼                      │ works_at
        ┌─────────┐             ┌──────┐
        │  pizza  │             │ Jane │
        └─────────┘             └──────┘

   nodes  = Jayanth, Google, Alex, Jane, pizza
   edges  = works_at, owns, likes  (directed, labelled)
```

That's a graph: data in nodes, meaning in labelled, directed edges.

---

## 6. Main takeaways

- A **graph** = **nodes** (carry data) + **edges** (connections).
- Edges represent **relationships**, and can be **labelled** (`A —[X]→ B`).
- A graph's purpose is to model **how things relate**, not just store them.
- **Directed** edge = one-way (arrow): `parent_of`, `works_at`.
- **Undirected** edge = mutual (no arrow): `friends_with`.
- Direction itself carries meaning — useful for traversing relationships.

---

## 7. Things I still want to figure out

- Can a node have **many edges** of different types at once? (Yes — that's the norm.)
- How are **edge properties** (e.g. "since 2020") stored?
- What's a **path** / traversal, and how is it queried? (Cypher — [[06 - Cypher Queries]].)
- How do graphs handle **cycles** (A→B→C→A)?

---

## 8. Things to dig into

- **Graph theory basics** — nodes, edges, directed/undirected, weighted graphs.
- **Property graphs** vs RDF triple stores (Neo4j uses the property-graph model).
- Cross-link: [[06 - Cypher Queries]] for how these get created in practice.

---

## 9. Next up in this section

- [ ] [[03 - Why Graphs for Memory]] — how relationships (which vectors miss) make memory better.

---

## Related
- [[01 - Section Intro - Graph Memory]] — the section framing.
- [[03 - Why Graphs for Memory]] — applying graphs to memory.

## Sources
- [Neo4j graph concepts](https://neo4j.com/docs/getting-started/)
