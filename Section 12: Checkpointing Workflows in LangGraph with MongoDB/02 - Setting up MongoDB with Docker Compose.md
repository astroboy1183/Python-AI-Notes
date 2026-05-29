---
title: Setting up MongoDB with Docker Compose
date: 2026-05-29
source: "Section 12 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 12: Checkpointing Workflows in LangGraph with MongoDB"
tags:
  - mongodb
  - docker
  - docker-compose
  - checkpointing
  - infrastructure
  - hands-on
related:
  - "[[01 - The State Persistence Problem]]"
  - "[[03 - Implementing Checkpointing with MongoDBSaver]]"
---

# Setting up MongoDB with Docker Compose

> [!abstract] TL;DR
> Checkpointing needs a database to hold the state. A **checkpoint** is a *snapshot of the graph state saved at each super-step*, stored in a persistent store — here, **MongoDB**. Stand it up with a tiny `docker-compose.yml`: one `mongodb` service on the `mongo` image, port `27017:27017`, env vars for the root username/password (`admin`/`admin` for local dev), and a named volume so data survives container restarts. Bring it up with `docker compose up -d`, wait for the (fairly large) image to pull, then confirm with `docker ps` or Docker Desktop that a `mongo` container is running on `27017`. With Mongo live, the next note plugs it into LangGraph as a checkpointer.

> [!info] Where this fits
> Second note of **Section 12**. It provisions the storage motivated by [[01 - The State Persistence Problem]]. [[03 - Implementing Checkpointing with MongoDBSaver]] connects the graph to it.

---

## 1. What a checkpoint actually is

> [!note] Definition
> A **checkpoint** is a **snapshot of the graph state** saved at a particular point in time (each "super-step" of execution), represented as a *state snapshot*. The thing that writes these snapshots to storage is a **checkpointer**.

So persisting state = repeatedly saving checkpoints to a database. I need a database first — MongoDB.

```
graph runs ──► state snapshot (checkpoint) ──► saved to MongoDB
                                                 (survives restarts)
```

---

## 2. Why MongoDB (and what else works)

LangGraph supports several checkpoint backends — Postgres, SQLite, in-memory, and **MongoDB**. MongoDB is a natural fit because state is essentially a JSON-like document, which maps cleanly onto Mongo's document model. (The choice here is MongoDB; the mechanism is the same for the others.)

---

## 3. The `docker-compose.yml`

Created inside the LangGraph project folder:

```yaml
# docker-compose.yml
services:
  mongodb:
    image: mongo
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: admin
    volumes:
      - mongodb_data:/data/db

volumes:
  mongodb_data:
```

### Line by line

| Piece | Meaning |
|---|---|
| `services:` | The containers to run |
| `mongodb:` | Name of this service |
| `image: mongo` | Official MongoDB image from Docker Hub |
| `ports: "27017:27017"` | Map host `27017` → container `27017` (Mongo's default port) |
| `MONGO_INITDB_ROOT_USERNAME` | Root username — `admin` (local dev only) |
| `MONGO_INITDB_ROOT_PASSWORD` | Root password — `admin` (local dev only) |
| `volumes: mongodb_data:/data/db` | Persist Mongo's data dir to a named volume |
| top-level `volumes:` | Declares the `mongodb_data` volume referenced above |

> [!warning] `admin/admin` is for local dev only
> Hardcoded root credentials like `admin/admin` are fine on my own machine for learning, but **never** for anything exposed or production. Real deployments use strong, secret-managed credentials.

> [!tip] Why the named volume matters
> Without `volumes`, MongoDB's data lives only inside the container's writable layer — destroy the container and the data (and all my checkpoints) vanish. The named volume `mongodb_data` keeps the data on the host, so it survives `docker compose down` / restarts. Persisting state is the whole point — losing it on a container restart would defeat the exercise.

---

## 4. Bringing it up

First make sure the **Docker daemon / engine is running** (Docker Desktop started). Then, from the project folder:

```bash
docker compose up -d
```

`-d` = detached (runs in the background). Docker pulls the `mongo` image — it's a **fairly large image**, so the first pull takes a bit.

```
Pulling mongodb ... downloading (large image, be patient)
...
Container langgraph_learn-mongodb-1  Started
```

---

## 5. Verifying it's running

Two ways to confirm:

```bash
docker ps
```

```
CONTAINER ID   IMAGE   ...   PORTS                       NAMES
abc123def456   mongo   ...   0.0.0.0:27017->27017/tcp    ...mongodb...
```

One container, image `mongo`, listening on `27017`. Or check **Docker Desktop → Containers** and look for the MongoDB container running on `27017`.

---

## 6. Mental model

```
host machine
   │  localhost:27017
   ▼
┌─────────────────────────────┐
│  Docker container: mongo    │
│   ├─ MongoDB server         │
│   └─ /data/db  ◄── volume ──┼──► mongodb_data (persisted on host)
└─────────────────────────────┘
```

Anything the LangGraph app writes through `localhost:27017` lands in Mongo, and the volume keeps it safe across restarts.

---

## 7. Common gotchas

> [!warning] MongoDB setup issues

| Symptom | Cause | Fix |
|---|---|---|
| `Cannot connect to the Docker daemon` | Docker engine not running | Start Docker Desktop |
| `port 27017 already allocated` | Another Mongo already running | Stop it, or map a different host port |
| Data lost after restart | No named volume | Add the `volumes` mapping |
| Pull seems stuck | Large image download | Wait — `mongo` is big |
| Auth fails later from the app | Wrong user/pass or missing creds in URI | Match the env vars in the connection string (next note) |

---

## 8. Main takeaways

- A **checkpoint** = a snapshot of graph state saved at each super-step.
- A **checkpointer** writes those snapshots to a database; this section uses **MongoDB**.
- LangGraph also supports **Postgres / SQLite / in-memory** checkpointers.
- `docker-compose.yml`: one `mongo` service, port `27017:27017`, root user/pass, named volume.
- Use **`admin/admin` only for local dev** — never production.
- The **named volume** keeps checkpoints alive across container restarts.
- Bring up with `docker compose up -d`; verify with `docker ps` or Docker Desktop.

---

## 9. Things I still want to figure out

- Where exactly does LangGraph **store checkpoints** in Mongo (which DB/collection)?
- Can I **inspect** the saved checkpoints directly with a Mongo client?
- What's the right **production** auth/connection setup (TLS, secrets)?
- How big do checkpoint documents get for long conversations?

---

## 10. Things to dig into

- **MongoDB Docker image**: https://hub.docker.com/_/mongo
- **LangGraph checkpointer backends**: https://langchain-ai.github.io/langgraph/concepts/persistence/
- **mongosh / Compass** to browse the stored state after note 03.

---

## 11. Next up in this section

- [ ] [[03 - Implementing Checkpointing with MongoDBSaver]] — connect the graph to this MongoDB with a checkpointer.

---

## Related
- [[01 - The State Persistence Problem]] — why this database is needed.
- [[03 - Implementing Checkpointing with MongoDBSaver]] — the code that uses it.

## Sources
- [MongoDB official image](https://hub.docker.com/_/mongo)
- [LangGraph persistence](https://langchain-ai.github.io/langgraph/concepts/persistence/)
