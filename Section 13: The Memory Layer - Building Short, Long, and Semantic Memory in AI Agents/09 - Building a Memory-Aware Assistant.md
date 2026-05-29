---
title: Building a Memory-Aware Assistant
date: 2026-05-29
source: "Section 13 / Lecture 9"
type: lecture-notes
status: in-progress
section: "Section 13: The Memory Layer - Building Short, Long, and Semantic Memory in AI Agents"
tags:
  - mem0
  - memory
  - retrieval
  - semantic-memory
  - assistant
  - hands-on
related:
  - "[[07 - Configuring the Mem0 Memory Client]]"
  - "[[08 - Setting up Qdrant for Mem0]]"
  - "[[05 - Semantic Memory in LLMs]]"
---

# Building a Memory-Aware Assistant

> [!NOTE]
> **TL;DR**
> Put it all together into an assistant that remembers across turns **without** stuffing the full chat history into the prompt. Two halves: **(1) Write** — after each exchange, `memory.add([{user msg}, {assistant msg}], user_id="jayanth")`; Mem0 uses its LLM to extract durable facts and stores them in Qdrant. **(2) Read** — *before* answering, `memory.search(query, user_id="jayanth")`, pull `["results"]`, format the relevant memories into a **system prompt**, and prepend it. The magic: I only ever send the *current* question plus the *relevant* memories — not the whole conversation — yet the bot knows my name, that I like pizza, etc. Mem0 even handles **contradictions** (say "I like ice cream", then "I don't" → it updates/deletes the old memory). Memories are scoped by **`user_id`**, so users never see each other's facts. Two bugs to dodge: pass `user_id` to `search` too, and read results from `search(...)["results"]`.

> [!NOTE]
> **Where this fits**
> Ninth note of **Section 13** and the capstone of the hands-on memory build. Uses the client from [[07 - Configuring the Mem0 Memory Client]] and the Qdrant from [[08 - Setting up Qdrant for Mem0]]. It's the concrete payoff of the **semantic/factual memory** theory in [[03 - Factual Memory in LLMs]] and [[05 - Semantic Memory in LLMs]].

---

## 1. The core idea

A normal chatbot remembers by **replaying the entire conversation** every turn — expensive and unbounded. A memory-aware assistant instead:

1. **Extracts and stores facts** from each exchange.
2. On a new question, **retrieves only the relevant facts** and feeds those in.

```
normal chatbot:           send ALL past messages every turn
memory-aware assistant:   send current question + only RELEVANT memories
```

The result feels like long-term memory, at a fraction of the token cost.

---

## 2. Setup: env + OpenAI client

```python
from dotenv import load_dotenv
load_dotenv()

from openai import OpenAI

client = OpenAI()       # for the chat completion
# `memory` = the Mem0 client from note 07
```

Copy the `.env` over so `OPENAI_API_KEY` loads. There are now **two** clients: the OpenAI `client` (for chatting) and the Mem0 `memory` client (for facts).

---

## 3. Half 1 — writing memories (`add`)

The principle: **every message in the conversation gets handed to the memory client.** Whatever model I chat with, I also pass the exchange to Mem0.

```python
USER_ID = "jayanth"

user_query = input("What do you want to ask? ")

response = client.chat.completions.create(
    model="gpt-4.1-mini",
    messages=[{"role": "user", "content": user_query}],
)
ai_response = response.choices[0].message.content
print("AI:", ai_response)

# store the exchange as memory
memory.add(
    messages=[
        {"role": "user", "content": user_query},
        {"role": "assistant", "content": ai_response},
    ],
    user_id=USER_ID,
)
print("Memory has been saved")
```

`memory.add(...)` automatically **extracts semantic/factual memories** from the messages and stores them. I don't tell it *what* to remember — its LLM (gpt-4.1 from the config) decides.

> [!IMPORTANT]
> **`user_id` scopes the memory**
> Just like a LangGraph `thread_id`, every `add` needs a **`user_id`**. Memories are stored *per user* — facts for `"jayanth"` live under "jayanth" and never bleed into another user's recall.

### Watching it land in Qdrant
Run it, say *"Hi, my name is Jayanth"*, and refresh the Qdrant dashboard (`localhost:6333/dashboard`): a **`mem0` collection** appears with a point like *"Name is Jayanth"*. That's the extracted fact, stored as a vector — a concrete instance of the factual memory from [[03 - Factual Memory in LLMs]].

---

## 4. A continuous conversation (`while True`)

Wrap it in a forever loop so it's an actual chat:

```python
while True:
    user_query = input("You: ")
    response = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[{"role": "user", "content": user_query}],
    )
    ai_response = response.choices[0].message.content
    print("AI:", ai_response)

    memory.add(
        messages=[
            {"role": "user", "content": user_query},
            {"role": "assistant", "content": ai_response},
        ],
        user_id=USER_ID,
    )
```

Now I can chat turn after turn, each one generating memories.

---

## 5. Mem0 handles contradictions

A striking behaviour: tell it *"I like to have ice cream at night"* → Qdrant gets a memory *"likes to have ice cream at night."* Then say *"actually I don't like ice creams"* → on refresh, the **old memory is deleted/updated**. Mem0's extraction LLM reconciles the conflict instead of blindly piling up contradictory facts.

```
"I like ice cream at night"   → memory: likes ice cream at night
"actually I don't like it"    → memory: (old one removed / replaced)
```

> [!TIP]
> **This is why an LLM does the extraction**
> Naive storage would keep both contradictory statements. Because gpt-4.1 *reasons* about the new info against the old, it can **update or delete** stale memories — the kind of consolidation a real memory system needs.

---

## 6. The gap: storing ≠ remembering

After all that, ask *"What is my name?"* — and it **fails**. Why? The loop only *saves* memories; it never *reads* them back. The chat completion still only sees the current question, with no memories injected.

```
add()  ✅  facts go into Qdrant
search() ❌  nothing pulls them back into the prompt
```

> [!WARNING]
> **Saving is only half the loop**
> Memory is useless if it's never retrieved. The assistant needs a **retrieval layer** before the LLM call — search for relevant memories and inject them.

---

## 7. Half 2 — reading memories (`search`)

Before answering, search the user's memories for ones relevant to the current query:

```python
search_result = memory.search(query=user_query, user_id=USER_ID)
memories = search_result["results"]
```

- `search(query, user_id)` returns **only relevant** memories — not all of them. It embeds the query and does a similarity search in Qdrant.
- The results live under the **`["results"]`** key.

> [!WARNING]
> **Two bugs that bite here**
> **Bug 1 — missing `user_id` in `search`.** `search` needs the **same `user_id`** as `add`, or it errors / finds nothing. Easy to forget since `add` already had it.
> **Bug 2 — `["results"]`.** `search(...)` returns a dict; the memories are inside `search_result["results"]`, not the top-level object. Iterating the raw return value fails.

---

## 8. Formatting memories into a system prompt

Turn the retrieved memories into context the model can use. Each memory has an `id` and the `memory` text:

```python
import json

# simple version: dump relevant memories as JSON into a system prompt
memories_text = json.dumps(memories)

system_prompt = f"""
Here is the context (memories) about the user:
{memories_text}
"""

print("Found memories:", memories)
```

Or build a cleaner string by iterating:

```python
memories_str = ""
for mem in memories:
    memories_str += f"{mem.get('id')}\n{mem.get('memory')}\n"
```

| Field | Meaning |
|---|---|
| `mem.get("id")` | Auto-assigned memory ID |
| `mem.get("memory")` | The actual fact text (e.g. "Name is Jayanth") |

---

## 9. Injecting memory into the chat call

Prepend the memory system prompt to the messages:

```python
response = client.chat.completions.create(
    model="gpt-4.1-mini",
    messages=[
        {"role": "system", "content": system_prompt},   # ← relevant memories
        {"role": "user", "content": user_query},
    ],
)
```

Now the model answers the current question **with the relevant facts in context** — without me ever sending the full chat history.

---

## 10. The full loop assembled

```python
from dotenv import load_dotenv
load_dotenv()

import json
from openai import OpenAI
# `memory` = Mem0 client from note 07

client = OpenAI()
USER_ID = "jayanth"

while True:
    user_query = input("You: ")

    # 1. retrieve relevant memories
    search_result = memory.search(query=user_query, user_id=USER_ID)
    memories = search_result["results"]
    print("Found memories:", memories)

    system_prompt = f"Context (memories) about the user:\n{json.dumps(memories)}"

    # 2. answer with memory injected
    response = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_query},
        ],
    )
    ai_response = response.choices[0].message.content
    print("AI:", ai_response)

    # 3. store the new exchange as memory
    memory.add(
        messages=[
            {"role": "user", "content": user_query},
            {"role": "assistant", "content": ai_response},
        ],
        user_id=USER_ID,
    )
```

---

## 11. It works — the payoff

```
You: What is my name?
Found memories: [ ... "Name is Jayanth" ... ]
AI: Your name is Jayanth.

You: I like to eat pizza with corn and cheese.
(memory saved: likes pizza with corn and cheese)

You: Can you suggest what food I can order?
Found memories: [ ... "likes pizza with corn and cheese" ... ]
AI: Since you like pizza with corn and cheese, you could order ...
```

The crucial observation: **I never pass the chat history.** Each call sends only the current question + the *relevant* memories pulled from Qdrant — yet the assistant clearly has continuity. That's a working **memory-aware assistant** built on Mem0 + Qdrant.

---

## 12. The full architecture

```
            ┌──────────────── per turn ────────────────┐
user query ─┤                                            ├─► answer
            │  1. memory.search(query, user_id)          │
            │        │  relevant memories                │
            │        ▼                                   │
            │  2. system prompt (+ memories) → LLM        │
            │        │                                   │
            │        ▼                                   │
            │  3. memory.add([user, assistant], user_id) │
            └────────────────────────────────────────────┘
                         │                    │
                    search/add          extracts facts
                         ▼                    ▼
                  ┌──────────┐         ┌──────────────┐
                  │  Qdrant  │ ◄────── │ Mem0 (gpt-4.1)│
                  │ (vectors)│         └──────────────┘
                  └──────────┘
```

Retrieve → answer → store. The "brain" is Mem0; the storage is Qdrant; only relevant facts ever enter the prompt.

---

## 13. Common gotchas

> [!WARNING]
> **Memory-assistant issues**

| Symptom | Cause | Fix |
|---|---|---|
| Bot "forgets" everything | Only `add`, never `search` | Add the retrieval layer |
| `search` errors / empty | Missing `user_id` | Pass the same `user_id` as `add` |
| Iterating results fails | Used raw return, not `["results"]` | `search_result["results"]` |
| Cross-user fact leakage | Shared/static `user_id` | Use the real user's ID |
| Connection refused | Qdrant down | `docker compose up -d` |
| No facts extracted | LLM/embedder misconfigured | Recheck the config (note 07) |

---

## 14. Main takeaways

- A memory-aware assistant **stores facts** and **retrieves relevant ones** — it doesn't replay full history.
- **Write**: `memory.add([user, assistant], user_id=...)` — Mem0's LLM extracts facts into Qdrant.
- **Read**: `memory.search(query, user_id=...)["results"]` — returns only **relevant** memories.
- Inject retrieved memories as a **system prompt** before the LLM call.
- Memories are **scoped by `user_id`** (like a thread ID) — no cross-user leakage.
- Mem0 **reconciles contradictions** (updates/deletes stale facts) because an LLM does the extraction.
- Storing without retrieving = the bot still forgets — **both halves required**.
- Two bugs: pass `user_id` to `search`; read `["results"]`.
- The win: continuity **without** sending the whole conversation each turn.

---

## 15. Things I still want to figure out

- How does Mem0 decide a memory is "**relevant**" — pure cosine similarity, or LLM re-ranking?
- How many memories does `search` return by default — is there a `limit`?
- What's the **token/cost** profile of extraction + search vs just replaying history?
- How to **edit/delete** a specific memory programmatically?
- Combining this with **LangGraph checkpointing** (Section 12) — short-term state + long-term facts together?
- Multiple conversations per user — composite `user_id` + session?

---

## 16. Things to dig into

- **Mem0 add/search API**: https://docs.mem0.ai/
- **Qdrant dashboard** — inspect the `mem0` collection's points (payload = the fact).
- Cross-links: [[03 - Factual Memory in LLMs]], [[05 - Semantic Memory in LLMs]] (the theory this realizes), Section 12 checkpointing (short-term counterpart).
- **Hands-on**: feed contradictory facts and watch Qdrant update; try a second `user_id` and confirm isolation.

---

## 17. Section wrap-up

This closes the hands-on memory build: Mem0 + Qdrant turn a stateless chatbot into a **memory-aware assistant** that extracts durable facts, stores them as vectors, and recalls only the relevant ones per query — scoped per user. Combined with the conceptual grounding from notes 00–05, Section 13 now spans both the *theory* of memory types and a *working implementation* of long-term semantic memory.

---

## Related
- [[07 - Configuring the Mem0 Memory Client]] — the client used here.
- [[08 - Setting up Qdrant for Mem0]] — the vector store this fills.
- [[05 - Semantic Memory in LLMs]] — the concept this implements.
- [[03 - Factual Memory in LLMs]] — the kind of facts being extracted.

## Sources
- [Mem0 documentation](https://docs.mem0.ai/)
- [Qdrant documentation](https://qdrant.tech/documentation/)
