---
title: Cypher Queries
date: 2026-05-29
source: "Section 14 / Lecture 6"
type: lecture-notes
status: in-progress
section: "Section 14: Graph Memory and Knowledge Graphs In AI Agents"
tags:
  - cypher
  - neo4j
  - create
  - match
  - merge
  - hands-on
related:
  - "[[05 - Setting up Neo4j Aura]]"
  - "[[07 - Adding Neo4j Graph Store to Mem0]]"
---

# Cypher Queries

> [!NOTE]
> **TL;DR**
> **Cypher** is Neo4j's query language. Create a node with `CREATE (u:User {name: "Jayanth"})`. Read with `MATCH (n:User {name: "Jayanth"}) RETURN n`, or get everything with `MATCH (n) RETURN n`. Make a relationship by **matching both nodes first, then merging an edge**: `MATCH (u:User {name:"Jayanth"}), (c:Company {name:"Google"}) MERGE (u)-[:EMPLOYEE]->(c)`. The big lesson: if you `CREATE` a company node every time instead of `MATCH`-ing the existing one, you end up with **duplicate Google nodes** and messy relationships — use `MATCH`/`MERGE` to reuse. Delete a stray node by its id: `MATCH (n) WHERE elementId(n) = "..." DELETE n`. And the practical punchline: **you rarely write Cypher by hand** — an LLM generates it from a plain-English description of the relationship, runs it, and reads results back.

> [!NOTE]
> **Where this fits**
> Sixth note of **Section 14**. It uses the Aura console from [[05 - Setting up Neo4j Aura]] to create a small graph by hand, so the auto-generated graph in [[08 - Building the Knowledge Graph]] makes sense.

---

## 1. What Cypher is

Cypher is the language for talking to Neo4j — the graph-DB equivalent of SQL. Its syntax is **visual**: it draws the pattern you want with ASCII-art arrows.

```
(node)-[:RELATIONSHIP]->(node)
```

That `()-[]->()`shape *is* the query. You don't need to be a Cypher pro — the basics cover most needs, and an LLM handles the rest.

---

## 2. Creating a node

```cypher
CREATE (u:User {name: "Jayanth"})
```

- `(u:User {...})` — a node, variable `u`, label `User`, property `name`.
- Run it → one `User` node named Jayanth exists.

> [!WARNING]
> **`CREATE` vs `MATCH` — a common first mistake**
> If you ask for "create a node" but run a `MATCH` query, you get **"no records"** — `MATCH` only *finds* existing data, it doesn't make any. Use `CREATE` to add, `MATCH` to read. (An LLM asked for "a Cypher query to create a node" will correctly produce `CREATE (...) RETURN ...`.)

Create a few more people and a company:

```cypher
CREATE (u:User {name: "Alex"})
CREATE (u:User {name: "John"})
CREATE (u:User {name: "Jane"})
CREATE (c:Company {name: "Google"})
```

Now there are four `User` nodes and one `Company` node — but **no relationships** yet.

---

## 3. Reading nodes

Find one specific node:

```cypher
MATCH (n:User {name: "Jayanth"})
RETURN n
```

Get **everything** (any label):

```cypher
MATCH (n)
RETURN n
```

This returns all nodes — the four users + the company — still disconnected.

---

## 4. Creating a relationship — match both, then connect

A relationship connects two **existing** nodes. The pattern: `MATCH` the two nodes, then create the edge between them.

```cypher
MATCH (u:User {name: "Jayanth"})
MATCH (c:Company {name: "Google"})
MERGE (u)-[:EMPLOYEE]->(c)
```

Read it as:
1. Find the user Jayanth → bind to `u`.
2. Find the company Google → bind to `c`.
3. Create (merge) an `EMPLOYEE` edge from `u` to `c`.

```
(Jayanth:User) ──[:EMPLOYEE]──► (Google:Company)
```

Tip used along the way: add `RETURN n` after a `MATCH` first, just to **confirm you're selecting the right node** before connecting it; then remove the `RETURN` and add the `MERGE`.

Repeat for John and Jane and everyone points at Google:

```
(Jayanth) ─┐
(John) ────┼──[:EMPLOYEE]──► (Google)
(Jane) ────┘
```

---

## 5. The duplicate-node trap

> [!IMPORTANT]
> **Don't `CREATE` the same entity repeatedly — `MATCH`/`MERGE` it**
> A classic bug: while wiring relationships, you accidentally `CREATE` a new `Google` node each time instead of `MATCH`-ing the one that already exists. Result — **multiple Google nodes**, and the `EMPLOYEE` edges get spread across the duplicates, so the graph looks messy and wrong.
>
> The fix is to **match the existing company once** and merge everyone onto it:

```cypher
MATCH (u:User {name: "Jayanth"})
MATCH (c:Company {name: "Google"})
MERGE (u)-[:EMPLOYEE]->(c)
```

`MERGE` is "create if it doesn't exist, otherwise reuse" — using it (and matching first) prevents duplicates.

```
WRONG (CREATE each time):        RIGHT (MATCH existing + MERGE):
 (Google)  (Google)  (Google)            (Google)
    ▲                                     ▲  ▲  ▲
 (Jayanth)  (John)   (Jane)        (Jayanth)(John)(Jane)
 edges scattered across copies      all edges on one node
```

---

## 6. Deleting stray nodes

To clean up the duplicate Google nodes, delete by **element id**:

```cypher
MATCH (n)
WHERE elementId(n) = "<the-element-id>"
DELETE n
```

> [!WARNING]
> **Use `elementId()`, not the deprecated `id()`**
> The old `id(n)` function is **deprecated**. Use **`elementId(n)`** to target a specific node. Grab the id from the node's details in the console, plug it into the `WHERE`, and `DELETE n` removes just that one. Repeat for each duplicate until a single `Google` remains.

---

## 7. The real workflow: let the LLM write Cypher

> [!TIP]
> **You don't hand-write Cypher in practice**
> LLMs are **very good** at generating Cypher. The real pattern: describe the relationship in plain English ("create a relation between user Jayanth and company Google") → the LLM emits the `MATCH ... MERGE ...` query → it runs against Neo4j → results come back. In the memory build ([[08 - Building the Knowledge Graph]]), Mem0 does exactly this automatically — generates the Cypher, stores the graph, fetches it back, all without you writing a single query.

```
plain English  ──►  LLM  ──►  Cypher  ──►  Neo4j  ──►  results
"Jayanth works at Google"      MATCH...MERGE
```

---

## 8. Cypher cheat-sheet

| Goal | Cypher |
|---|---|
| Create a node | `CREATE (u:User {name: "Jayanth"})` |
| Find a node | `MATCH (n:User {name: "Jayanth"}) RETURN n` |
| Find everything | `MATCH (n) RETURN n` |
| Create a relationship | `MATCH (a {...}), (b {...}) MERGE (a)-[:REL]->(b)` |
| Find relationships | `MATCH (a)-[:EMPLOYEE]->(b) RETURN a, b` |
| Delete a node by id | `MATCH (n) WHERE elementId(n) = "..." DELETE n` |

---

## 9. Main takeaways

- **Cypher** is Neo4j's SQL-like, pattern-drawing query language.
- `CREATE` adds nodes; `MATCH` finds them; mixing them up gives "no records."
- Relationships: **`MATCH` both nodes, then `MERGE` the edge** between them.
- **`MERGE` reuses** existing nodes/edges — avoids duplicates.
- `CREATE`-ing the same entity repeatedly makes **duplicate nodes** and messy edges — match the existing one instead.
- Delete a node with `MATCH ... WHERE elementId(n) = "..." DELETE n` (use **`elementId`**, not deprecated `id`).
- In practice an **LLM writes the Cypher** from plain English — Mem0 automates this.

---

## 10. Things I still want to figure out

- `MERGE` vs `CREATE` precisely — when does MERGE match vs create?
- How to add **properties to relationships** (e.g. `[:EMPLOYEE {since: 2020}]`)?
- **Multi-hop** queries — `MATCH (a)-[:EMPLOYEE]->(c)<-[:EMPLOYEE]-(b)` to find co-workers?
- How to **constrain uniqueness** (so duplicates can't happen) — unique constraints?

---

## 11. Things to dig into

- **Cypher manual**: https://neo4j.com/docs/cypher-manual/
- **MERGE semantics**: https://neo4j.com/docs/cypher-manual/current/clauses/merge/
- **Uniqueness constraints** to prevent duplicate nodes.
- Cross-link: [[08 - Building the Knowledge Graph]] (LLM-generated Cypher in action).

---

## 12. Next up in this section

- [ ] [[07 - Adding Neo4j Graph Store to Mem0]] — connect this Neo4j to Python via Mem0's config.

---

## Related
- [[05 - Setting up Neo4j Aura]] — the instance these queries run against.
- [[07 - Adding Neo4j Graph Store to Mem0]] — automating Cypher via Mem0.

## Sources
- [Cypher manual](https://neo4j.com/docs/cypher-manual/)
