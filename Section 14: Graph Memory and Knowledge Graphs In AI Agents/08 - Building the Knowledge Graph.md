---
title: Building the Knowledge Graph
date: 2026-05-29
source: "Section 14 / Lecture 8"
type: lecture-notes
status: in-progress
section: "Section 14: Graph Memory and Knowledge Graphs In AI Agents"
tags:
  - mem0
  - neo4j
  - knowledge-graph
  - graph-memory
  - hands-on
related:
  - "[[07 - Adding Neo4j Graph Store to Mem0]]"
  - "[[06 - Cypher Queries]]"
  - "[[09 - Building a Memory-Aware Assistant]]"
---

# Building the Knowledge Graph

> [!NOTE]
> **TL;DR**
> Run the Mem0 client with the Neo4j `graph_store` enabled — but first install the missing integration packages (`langchain-neo4j`, plus one more it asks for; just follow the errors). Then chat: *"My name is Jayanth and I like pizza with tomato topping and some hot tea."* Mem0's LLM extracts not just facts but **entities and relationships**, generates the Cypher, and writes a **knowledge graph** into Neo4j — refresh Aura and nodes appear (`User`, `food`, `beverage`) with `LIKES` edges: `(Jayanth)-[:LIKES]->(pizza)`, `(Jayanth)-[:LIKES]->(hot tea)`. Add more (*"I'm a full-stack developer; my stack is Node.js and JavaScript with Postgres"*) and the graph grows further. All automatic — no hand-written Cypher. This is the payoff: a self-building knowledge graph of the user, complementing the vector memory.

> [!NOTE]
> **Where this fits**
> Eighth and final note of **Section 14**. It runs the config from [[07 - Adding Neo4j Graph Store to Mem0]] and shows Mem0 auto-building the graph the manual Cypher in [[06 - Cypher Queries]] hinted at. Together with [[09 - Building a Memory-Aware Assistant]], it completes the dual (vector + graph) memory.

---

## 1. First run → install the missing packages

With the `graph_store` block added, the Mem0 client now has access to a graph store — but the first run fails because the Neo4j integration isn't installed:

```
Cannot import memory graph for provider neo4j:
langchain_neo4j is not installed
```

Fix it — install and re-run, following each error:

```bash
pip install langchain-neo4j
# re-run → it asks for one more package → install that too
```

> [!TIP]
> **Just follow the errors**
> Enabling a new provider often surfaces one or two missing dependencies in sequence. Read each error, `pip install` what it names, re-run. After the Neo4j packages are in, the client connects (the first connection takes a moment).

---

## 2. Feeding it a conversation

Run the memory client and chat normally:

```
You: My name is Jayanth and I like pizza with tomato topping and some hot tea.
```

The flow (same as the vector assistant, now with a graph too):
1. The LLM responds to the user.
2. Mem0 **searches** existing memories (finds Jayanth's name etc.).
3. Mem0 **adds** the exchange — extracting facts **and relationships**.

```
AI: "Great to know, Jayanth! ..."
(found memories: name is Jayanth ...)
```

---

## 3. The graph builds itself

Refresh the Neo4j Aura console after the exchange — the previously empty graph now has **nodes and relationships**:

```
(:User {name: "Jayanth"}) ──[:LIKES]──► (:food {name: "pizza"})
(:User {name: "Jayanth"}) ──[:LIKES]──► (:beverage {name: "hot tea"})
```

Querying everything shows `User`, `food`, and `beverage` nodes wired by `LIKES` edges. Querying just the likes:

```
user (Jayanth) LIKES pizza
user (Jayanth) LIKES hot tea
```

> [!IMPORTANT]
> **Mem0 generated all the Cypher automatically**
> No hand-written queries. Mem0's extraction LLM identified the **entities** (Jayanth, pizza, hot tea), classified them (`User`, `food`, `beverage`), inferred the **relationship** (`LIKES`), generated the Cypher, and stored it in Neo4j — exactly the "LLM writes the Cypher" pattern from [[06 - Cypher Queries]], fully automated.

```
"I like pizza and hot tea"
        │
        ▼  Mem0 LLM extracts entities + relationships
(Jayanth)─[:LIKES]→(pizza)   (Jayanth)─[:LIKES]→(hot tea)
        │
        ▼  Mem0 generates Cypher + writes
     Neo4j knowledge graph
```

---

## 4. The graph grows with each message

Add more about myself:

```
You: I am a full-stack developer. My main tech stack is Node.js and
     JavaScript with Postgres.
```

Mem0 extracts the new entities and relationships and extends the graph — e.g. a `User`→`role`/`skill` style of nodes and edges for the developer role and the tech stack. Each conversation turn enriches the knowledge graph automatically.

```
(Jayanth) ─[:LIKES]──► (pizza)
(Jayanth) ─[:LIKES]──► (hot tea)
(Jayanth) ─[:IS_A]───► (full-stack developer)
(Jayanth) ─[:USES]───► (Node.js)
(Jayanth) ─[:USES]───► (JavaScript)
(Jayanth) ─[:USES]───► (Postgres)
```

(Exact labels/edge names are whatever the extraction LLM chooses — the shape is the point.)

---

## 5. Vector + graph, working together

```
            user message
                 │
         ┌───────┴────────┐
         ▼                ▼
   ┌──────────┐     ┌──────────┐
   │ Qdrant   │     │ Neo4j    │
   │ facts    │     │ relations│
   │ "likes   │     │ (Jayanth)│
   │  pizza"  │     │ -[LIKES]→│
   └──────────┘     │ (pizza)  │
                    └──────────┘
   recall by         recall by
   similarity        relationship
```

The vector store answers *"what do I know that's similar?"*; the graph answers *"how are these things connected?"*. Mem0 maintains both from the same conversation — the complete memory system this two-section arc was building toward.

---

## 6. Common gotchas

> [!WARNING]
> **Knowledge-graph build issues**

| Symptom | Cause | Fix |
|---|---|---|
| `langchain_neo4j is not installed` | Missing integration package | `pip install langchain-neo4j` (+ any it then asks for) |
| Connects but no graph appears | Refresh not done / wrong instance | Hard-refresh the Aura console |
| Auth/connection error | Bad URI/credentials | Recheck `graph_store` config ([[07 - Adding Neo4j Graph Store to Mem0]]) |
| First run hangs briefly | Establishing Neo4j connection | Expected — give it a moment |
| Qdrant errors too | Vector store also needed | Keep Qdrant running (`docker compose up -d`) |

---

## 7. Main takeaways

- Enabling graph memory needs the **`langchain-neo4j`** package (and one more — follow the errors).
- Chatting normally makes Mem0 extract **entities + relationships**, not just facts.
- Mem0 **auto-generates the Cypher** and writes a **knowledge graph** to Neo4j.
- Example graph: `(Jayanth)-[:LIKES]->(pizza)`, `(Jayanth)-[:LIKES]->(hot tea)`; nodes typed `User`/`food`/`beverage`.
- Each new message **grows** the graph (developer role, tech stack, etc.).
- **No hand-written Cypher** — the LLM does it all.
- The result: **vector memory (Qdrant) + graph memory (Neo4j)** maintained together.

---

## 8. Things I still want to figure out

- How does Mem0 use the graph **at retrieval time** — does it traverse relationships to enrich answers?
- Can I control the **node labels / relationship types** it chooses?
- How does it handle **contradictions** in the graph (update edges)?
- What's the **cost** of graph extraction per message (extra LLM calls)?
- Combining graph traversal results with vector recall in a single prompt?

---

## 9. Things to dig into

- **Mem0 graph memory**: https://docs.mem0.ai/
- **`langchain-neo4j`**: the integration package.
- Explore the built graph in **Aura** with Cypher ([[06 - Cypher Queries]]).
- **Hands-on**: feed relational facts ("Jane is my co-worker at Google") and query the co-worker relationship.

---

## 10. Section wrap-up

Section 14 adds **graph memory** to the stack: understand graphs → see why relationships matter → stand up Neo4j (Aura) → learn Cypher → wire Neo4j into Mem0 → watch a knowledge graph build itself from conversation. Paired with the vector memory from [[09 - Building a Memory-Aware Assistant]], the assistant now remembers both **facts** and **how they connect** — a genuinely richer, more human-like memory.

---

## Related
- [[07 - Adding Neo4j Graph Store to Mem0]] — the config this runs.
- [[06 - Cypher Queries]] — the Cypher Mem0 generates automatically.
- [[09 - Building a Memory-Aware Assistant]] — the vector-memory counterpart.

## Sources
- [Mem0 graph memory](https://docs.mem0.ai/)
- [langchain-neo4j](https://pypi.org/project/langchain-neo4j/)
