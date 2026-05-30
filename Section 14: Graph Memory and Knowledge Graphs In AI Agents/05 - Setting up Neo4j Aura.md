---
title: Setting up Neo4j Aura
date: 2026-05-29
source: "Section 14 / Lecture 5"
type: lecture-notes
status: in-progress
section: "Section 14: Graph Memory and Knowledge Graphs In AI Agents"
tags:
  - neo4j
  - aura
  - cloud
  - graph-database
  - setup
  - hands-on
related:
  - "[[04 - Graph Databases]]"
  - "[[06 - Cypher Queries]]"
---

# Setting up Neo4j Aura

> [!NOTE]
> **TL;DR**
> Neo4j is **heavy** to self-host, so the easy path is a managed cloud instance: **Neo4j Aura**. Sign in to Aura (free with a Google account), create a **free ($0) instance**, and on creation it shows the credentials **once** — username `neo4j` and a generated **password** that cannot be retrieved later. **Copy them immediately** into the `.env` (and download the credentials file it offers). Wait for the instance to spin up, then **Connect**. The console is where **Cypher queries** are written; a fresh instance shows **0 nodes, 0 relationships**. Also grab the **connection URI** — it's needed to wire Neo4j into Python/Mem0 later.

> [!NOTE]
> **Where this fits**
> Fifth note of **Section 14**. It provisions the Neo4j chosen in [[04 - Graph Databases]]. [[06 - Cypher Queries]] then uses the console to create nodes and relationships.

---

## 1. Why cloud (Aura) instead of Docker

Neo4j can be self-hosted via Docker, but it's a **heavy** database — running it locally is resource-intensive. A managed cloud instance is simpler and faster to get going, and Aura has a **free tier**.

```
self-host (Docker):  full control, but heavy on the local machine
Neo4j Aura (cloud):  managed, free tier, fastest to start  ◄── chosen
```

---

## 2. Creating a free instance

1. Go to **Neo4j Aura** and log in (free — e.g. *Continue with Google*).
2. The dashboard shows existing instances (none on a fresh account).
3. **Create instance** → choose the **Free** plan (**$0**).

---

## 3. The credentials — copy them NOW

On creation, Aura shows the connection credentials **exactly once**:

| Field | Value |
|---|---|
| **Username** | `neo4j` (default) |
| **Password** | auto-generated (e.g. a random string) |
| **Connection URI** | `neo4j+s://<id>.databases.neo4j.io` |

> [!WARNING]
> **The password is shown only once and cannot be changed/retrieved later**
> Aura generates the password at creation and does **not** let you view it again. **Copy it immediately** — also use the **Download** option to save the credentials file. If lost, the instance is effectively locked out. Save username + password (and the URI) straight into the project `.env`.

Stash them in `.env` right away:

```
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=<the-generated-password>
NEO4J_URI=neo4j+s://<id>.databases.neo4j.io
```

Then **Download and continue** — Aura begins provisioning.

---

## 4. Waiting for the instance

Instance creation takes a little time. Once it shows **running**, it's ready to connect.

```
[creating...] ──► [running ✅] ──► Connect
```

---

## 5. Connecting and the console

Hit **Connect** (it goes through a connecting stage). Once connected, the **query console** opens — this is where **Cypher queries** are written to talk to the database.

A brand-new instance is empty:

```
Nodes:         0
Relationships: 0
```

That's the expected starting state — nothing has been created yet (that's [[06 - Cypher Queries]]).

---

## 6. The connection URI (needed later)

From the instance's **connection details**, copy the **connection URI**. It's the address Python/Mem0 will use to reach this graph:

```
NEO4J_URI = neo4j+s://<id>.databases.neo4j.io
```

> [!TIP]
> **`neo4j+s://` = secure (TLS)**
> Aura uses the `neo4j+s://` scheme (encrypted connection). Keep the full URI, username, and password together — all three are required to connect from code ([[07 - Adding Neo4j Graph Store to Mem0]]).

---

## 7. Common gotchas

> [!WARNING]
> **Aura setup issues**

| Symptom | Cause | Fix |
|---|---|---|
| Can't log in / no password | Password not copied at creation | Recreate the instance; copy immediately |
| Connection fails from code | Wrong URI scheme/host | Use the exact `neo4j+s://...` URI |
| Instance "not ready" | Still provisioning | Wait for **running** state |
| Auth error | Username/password mismatch | Username is `neo4j`; recheck password |
| Free instance paused | Aura free tier auto-pauses when idle | Resume it from the dashboard |

---

## 8. Main takeaways

- Neo4j is **heavy to self-host** → use **Neo4j Aura** (managed cloud, free tier).
- Create a **Free ($0)** instance after logging in (Google works).
- Credentials show **once**: username `neo4j` + a **generated password** that can't be retrieved later — **copy them immediately** (and download).
- Save username, password, and **connection URI** into `.env`.
- The **console** is where Cypher queries run; a fresh instance has **0 nodes / 0 relationships**.
- The URI uses the secure `neo4j+s://` scheme.

---

## 9. Things I still want to figure out

- Does the **free tier** have node/relationship limits or auto-pause?
- How to **rotate** the password if it leaks (recreate, or reset)?
- Aura vs **self-hosted Docker** for a real project?
- Where to see **usage/metrics** for the instance?

---

## 10. Things to dig into

- **Neo4j Aura**: https://neo4j.com/cloud/aura/
- **Connecting to Aura** (drivers, URIs): https://neo4j.com/docs/
- Next: writing data with **Cypher**.

---

## 11. Next up in this section

- [ ] [[06 - Cypher Queries]] — create nodes and relationships in the console.

---

## Related
- [[04 - Graph Databases]] — why Neo4j.
- [[06 - Cypher Queries]] — querying the instance.
- [[07 - Adding Neo4j Graph Store to Mem0]] — using the URI/credentials from code.

## Sources
- [Neo4j Aura](https://neo4j.com/cloud/aura/)
