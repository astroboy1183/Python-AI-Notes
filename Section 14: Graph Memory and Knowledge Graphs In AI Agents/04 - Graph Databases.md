---
title: Graph Databases
date: 2026-05-29
source: "Section 14 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 14: Graph Memory and Knowledge Graphs In AI Agents"
tags:
  - graph-database
  - neo4j
  - kuzudb
  - cypher
  - infrastructure
related:
  - "[[03 - Why Graphs for Memory]]"
  - "[[05 - Setting up Neo4j Aura]]"
---

# Graph Databases

> [!NOTE]
> **TL;DR**
> Graphs need **special databases** built for nodes-and-edges, not rows-and-tables. The dominant one is **Neo4j** — very mature, very scalable, self-hostable, and the **industry standard** for graph data. A newer alternative is **KuzuDB** (an embedded graph DB), but its ecosystem support is still limited because it's relatively new. For anything production-shaped, Neo4j is what teams reach for, so it's the choice for this section. Neo4j stores graphs as nodes + relationships (e.g. `(Person)-[:ACTED_IN]->(Movie)`) and is queried with the **Cypher** language.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 14**. Having seen *why* a graph helps memory ([[03 - Why Graphs for Memory]]), this picks the storage engine. [[05 - Setting up Neo4j Aura]] stands one up in the cloud.

---

## 1. Why a special database

Relational databases (Postgres, MySQL) model data as tables and rows. Relationships there mean **JOINs**, which get expensive and awkward for deep, many-hop connections. A **graph database** stores nodes and edges natively, so traversing relationships ("friends of friends of friends") is fast and natural.

```
relational DB:  relationships = JOINs across tables (slow for deep links)
graph DB:       relationships = first-class edges (fast traversal)
```

This is the right home for the knowledge-graph memory from [[03 - Why Graphs for Memory]].

---

## 2. The options

| Database | Maturity | Notes |
|---|---|---|
| **Neo4j** | Very mature | The most popular graph DB; large, scalable, self-hostable; **industry standard** |
| **KuzuDB** | New | Embedded graph DB, fast, but **limited ecosystem support** (relatively new to market) |

### Neo4j
- Big, battle-tested, widely adopted.
- **Self-hostable** (Docker) *or* run as a managed cloud service (Aura).
- Stores graphs like `(Person)-[:ACTED_IN]->(Movie)`.
- Queried with **Cypher** (covered in [[06 - Cypher Queries]]).

### KuzuDB
- One of the newer graph databases — embedded, performance-focused.
- The catch: **support and ecosystem are still limited** because it's young.

---

## 3. Why Neo4j for this section

> [!TIP]
> **Industry standard wins**
> By industry standards, **Neo4j is what everyone uses** — it "really shines out." Mature tooling, broad integration support (including with memory frameworks like Mem0), and a huge community. So this section uses **Neo4j** as the graph database and stores all the memory relationships there.

```
choice:  Neo4j  (mature, standard, well-integrated)
over:    KuzuDB (promising, but limited support today)
```

---

## 4. How Neo4j thinks about data

Neo4j uses the **property-graph** model:

```
( :Person {name: "Jayanth"} ) ─[:WORKS_AT]─► ( :Company {name: "Google"} )
   │              │                   │              │
  label        property            relationship    label + property
```

- **Nodes** have **labels** (`:Person`, `:Company`) and **properties** (`name: "..."`).
- **Relationships** have a **type** (`:WORKS_AT`) and can also carry properties.

This is the structure the Cypher queries in [[06 - Cypher Queries]] create and read.

---

## 5. Deployment options (preview)

| Option | When |
|---|---|
| **Self-host (Docker)** | Full control; but Neo4j is **heavy** to run locally |
| **Neo4j Aura (cloud)** | Managed, free tier available, easiest to start |

Because Neo4j is resource-heavy locally, the next note uses the **cloud (Aura)** free instance instead of Docker.

---

## 6. Main takeaways

- Graphs need **graph databases** — relationships are first-class, not JOINs.
- **Neo4j** is the mature, scalable, self-hostable **industry standard**.
- **KuzuDB** is a newer embedded option but has **limited support** today.
- This section uses **Neo4j**.
- Neo4j uses a **property-graph** model: labelled nodes + typed relationships, both with properties.
- Query language is **Cypher**.
- Neo4j is **heavy to self-host** → the next note uses **Aura (cloud)**.

---

## 7. Things I still want to figure out

- When would **KuzuDB**'s embedded model actually be the better pick?
- How does Neo4j **scale** (clustering, sharding) for large graphs?
- What does the **Mem0 ↔ Neo4j** integration require? (See [[07 - Adding Neo4j Graph Store to Mem0]].)
- Self-host vs Aura **cost/perf** trade-offs at scale?

---

## 8. Things to dig into

- **Neo4j**: https://neo4j.com/
- **Cypher language**: https://neo4j.com/docs/cypher-manual/
- **KuzuDB**: https://kuzudb.com/
- **Neo4j Aura** (managed cloud): https://neo4j.com/cloud/aura/

---

## 9. Next up in this section

- [ ] [[05 - Setting up Neo4j Aura]] — spin up a free managed Neo4j instance in the cloud.

---

## Related
- [[03 - Why Graphs for Memory]] — why this storage is needed.
- [[05 - Setting up Neo4j Aura]] — provisioning Neo4j.
- [[06 - Cypher Queries]] — the query language.

## Sources
- [Neo4j](https://neo4j.com/)
- [KuzuDB](https://kuzudb.com/)
