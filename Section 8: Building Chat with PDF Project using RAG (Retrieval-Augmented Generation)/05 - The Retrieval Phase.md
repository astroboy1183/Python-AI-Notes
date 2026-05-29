---
title: The Retrieval Phase
date: 2026-05-28
source: "Section 8 / Lecture 5"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - rag
  - retrieval
  - similarity-search
  - vector-search
  - top-k
  - citations
  - foundations
related:
  - "[[04 - The Indexing Phase]]"
  - "[[07 - Vector Embeddings]]"
  - "[[11 - Building the Retrieval (chat.py)]]"
---

# The Retrieval Phase

> [!NOTE]
> **TL;DR**
> The **retrieval phase** is the online, per-query side of RAG. Four sub-steps every time a user asks something: (1) take the **user query**, (2) embed it using the **same embedding model** as the index, (3) do a **vector similarity search** against the vector DB → get the top-K most semantically related chunks, (4) build a **system prompt** containing those chunks (with page numbers + source for citations) and send it along with the user query to the LLM. The LLM produces a grounded answer citing the chunks. End-to-end: ~1-3 seconds, ~$0.001-0.01 per query. The pattern works for **any external knowledge** (PDFs, code, wiki pages, customer history) — change the indexed corpus, the retrieval logic stays the same.

> [!NOTE]
> **Where this fits**
> Fifth lecture of **Section 8: Building Chat with PDF Project using RAG**. Completes the RAG architecture (after [[04 - The Indexing Phase]]). Notes 6-10 implement indexing in code; Note 11 implements retrieval. By the end of the section: a working chat-with-PDF system.

---

## 1. When the retrieval phase fires

```
User query arrives → retrieval phase runs → response goes back
```

Unlike indexing (batch, offline), retrieval is **per-query, online, real-time**. Every chat turn re-runs it. The retrieval phase kicks off when the user sends a query / message.

---

## 2. The four steps

```
┌──────────────────────────────────────────────────────────────┐
│  RETRIEVAL PIPELINE                                            │
│                                                                │
│  ① QUERY     User: "Can you tell me about case 32?"            │
│              │                                                 │
│              ▼                                                 │
│  ② EMBED     Convert query → vector (same model as indexing)   │
│              │                                                 │
│              ▼                                                 │
│  ③ SEARCH    Vector similarity search → top-K relevant chunks  │
│              │                                                 │
│              ▼                                                 │
│  ④ AUGMENT   Build prompt with chunks + query → LLM → answer   │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

The full implementation appears in [[11 - Building the Retrieval (chat.py)]]. This note covers the **conceptual** shape.

---

## 3. Step 1 — User query

Straightforward — read user input:

```python
user_query = input("> ")
# or: from FastAPI request body, from a chat UI, etc.
```

No special handling at this step. The raw natural-language query goes to the next step.

---

## 4. Step 2 — Embed the query

Convert the query into the same vector space as the indexed chunks:

```python
query_vector = embedding_model.embed_query(user_query)
```

> [!WARNING]
> **Must use the same embedding model as indexing**
> If chunks were indexed with `text-embedding-3-large`, the query **must** be embedded with `text-embedding-3-large` too. Different models → different vector spaces → meaningless similarity scores.

Cost per query embedding: **negligible** (microcents). Latency: ~100-300 ms for OpenAI's API.

Whatever the user is trying to ask, whatever they mean in the real world, gets converted to a vector embedding using the same embedding model used at index time.

---

## 5. Step 3 — Vector similarity search

The heart of RAG. Ask the vector DB: *"Which K chunks have vectors closest to my query vector?"*

```python
relevant_chunks = vector_db.similarity_search(
    query=user_query,           # or query_vector
    k=5,                          # top-5 most similar
)
```

### How "closest" is measured

Vector DBs typically use one of:

| Metric | What it measures | Standard for text? |
|---|---|---|
| **Cosine similarity** | Angle between vectors (direction) | ✅ Default |
| **Euclidean (L2)** | Straight-line distance | Occasional |
| **Dot product** | Combined direction + magnitude | When vectors are normalized |

For text embeddings, **cosine similarity** is the standard. Both query and chunk vectors get normalized; closest match = smallest angle = highest dot product.

### Top-K

K is a tunable parameter:

| K | When |
|---|---|
| **1** | Single most relevant chunk only — risky |
| **3-5** | Standard for chat-with-PDF |
| **5-10** | More context, more tokens, slightly slower |
| **20+** | Wide retrieval; needs re-ranking |

> [!TIP]
> Start with K=5 and tune. If retrievals miss obvious matches, increase. If retrievals include irrelevant chunks, decrease (or add a reranker).

### What comes back

For each of the K results:

| Field | Value |
|---|---|
| `score` | Cosine similarity score (0-1) |
| `text` | The original chunk content |
| `metadata.page` | Page number |
| `metadata.source` | Source document |
| `metadata.chunk_id` | Within-doc chunk index |

The vector itself is **discarded** — only the original text + metadata is needed for the next step.

What this gives you: **only the relevant chunks**, not all of them. The vector DB might hold 50,000 chunks total — but the query only needs the two (or top-K) that actually matter.

---

## 6. Step 4 — Augment + generate

Build a system prompt that includes:
- Instructions ("answer based on the context").
- The retrieved chunks (with source + page metadata).
- The user query.

```python
context = "\n\n".join([
    f"[Page {c.metadata['page']}, from {c.metadata['source']}]\n{c.page_content}"
    for c in relevant_chunks
])

system_prompt = f"""
You are a helpful AI assistant who answers user queries based on the
context retrieved from a PDF, along with the page content and page number.

Only answer based on the following context. Navigate the user to the right
page number to learn more.

Available context:
{context}
"""

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": user_query},
    ],
)
```

The LLM now answers with:
- Information drawn from the chunks (not its training).
- Page-level citations the user can verify.
- A natural reply tone.

The prompt only contains the available data — just the top-K chunks plus what the user originally asked. It tells the LLM: *"here is the relevant context (page number, document, paragraph content); here is what the user is asking."* The model can then reply with the data about case number 32 **plus** the page number where that data lives.

---

## 7. End-to-end latency budget

A breakdown for one query:

| Step | Latency |
|---|---|
| Embed query (OpenAI API) | 100-300 ms |
| Vector similarity search (Qdrant local) | 5-50 ms |
| Build prompt | < 1 ms |
| LLM API call (GPT-4o) | 500-2000 ms |
| Token streaming completes | + 500-3000 ms |
| **Total perceived latency** | **1-5 seconds** |

The user experiences ~1-3 seconds to first token, then streaming for the rest. Acceptable for chat UX.

---

## 8. Cost per query

| Step | Cost |
|---|---|
| Query embedding | ~$0.00001 |
| Vector search | $0 (local) or ~$0.0001 (cloud) |
| LLM call (5 chunks × 1k tokens + 200-token reply) | ~$0.015 (GPT-4o) or ~$0.001 (GPT-4o-mini) |
| **Total** | **~$0.001-0.02 per query** |

At a million queries / month, total runs $1k-$20k — affordable. The bulk of the cost is the LLM inference, not the retrieval itself.

---

## 9. Why this works — the "semantic recall" magic

The retrieval works even when the user's query doesn't share exact keywords with the relevant chunk. Examples:

| User query | Relevant chunk | Why retrieval works |
|---|---|---|
| "Tell me about case 32" | A chunk that mentions "Case No. 32" | Direct match via vectors. |
| "How do I debug Node.js?" | A chunk titled "Troubleshooting your Node app" | Semantic similarity captures "debug" ≈ "troubleshoot". |
| "What's the firing policy?" | A chunk on "Termination procedures" | Semantic similarity again. |
| "When was Galileo born?" | A biography page in Italian | Cross-lingual embeddings handle this. |

This is impossible with **keyword search** (Elasticsearch, grep, SQL `LIKE`). Vector search retrieves on **meaning**, not text.

> [!WARNING]
> **But it can also fail**
> Semantic search misses when:
> - The query is too vague.
> - Embedding the query produces a "wrong" vector (the query language style differs from the corpus's).
> - The relevant chunk is short / generic and gets out-scored by longer, more specific but irrelevant chunks.
>
> Mitigations: hybrid search (vector + keyword), reranking, query expansion. Covered in later sections / advanced RAG.

---

## 10. The retrieval phase in one picture

```
   ┌──────────────────────┐
   │  User query          │
   └─────────┬────────────┘
             │
             ▼
   ┌──────────────────────┐
   │  Embedding model     │  (same as indexing)
   └─────────┬────────────┘
             │
   query vector
             │
             ▼
   ┌──────────────────────┐         ┌──────────────────────┐
   │  Vector DB           │ ←────── │  All indexed chunks  │
   │  similarity search   │         │  (from indexing)     │
   └─────────┬────────────┘         └──────────────────────┘
             │
   top-K chunks (text + metadata)
             │
             ▼
   ┌──────────────────────┐
   │  Build system prompt │
   │  (context + query)   │
   └─────────┬────────────┘
             │
             ▼
   ┌──────────────────────┐
   │  LLM (GPT-4o)        │
   └─────────┬────────────┘
             │
   grounded answer
             │
             ▼
   ┌──────────────────────┐
   │  User                │
   └──────────────────────┘
```

---

## 11. Variations and upgrades (preview)

The version above is the **vanilla** retrieval pipeline. Production systems layer on:

| Upgrade | What it adds |
|---|---|
| **Reranking** | After top-K, re-score with a cross-encoder model for better precision |
| **Hybrid search** | Vector + keyword (BM25) blend |
| **Query rewriting** | LLM rewrites query before embedding (clarify, expand, decompose) |
| **HyDE** | Embed a hypothetical answer to the query, search with that |
| **Multi-vector** | Embed query in multiple ways, search each, merge |
| **Filtering** | Restrict search to specific docs / users / dates via metadata |
| **Self-querying** | LLM generates metadata filters from the query |

For learning, vanilla works fine. Advanced techniques layer in once baseline is hitting accuracy limits.

---

## 12. Main takeaways

- **Retrieval** = online, per-query side of RAG.
- Four steps: **query → embed → similarity search → augment + generate**.
- Must use the **same embedding model** as indexing.
- **Top-K** (typically 5) chunks come back with text + metadata + score.
- The system prompt **must include the retrieved context** before calling the LLM.
- Cite source + page in the prompt → LLM cites them in the answer.
- End-to-end latency: **1-5 seconds**. Cost: **~$0.001-0.02 per query**.
- Vector search retrieves on **meaning**, not keywords — the semantic-recall magic.
- Can fail when query phrasing diverges sharply from indexed text; **hybrid search + reranking** are common upgrades.

---

## 13. Things I still want to figure out

- For multi-turn conversations, do I embed the **full history** or just the latest query?
- What's the right value of **K** for my specific corpus + use case?
- How to handle **follow-up questions** where the relevant chunk doesn't have keyword overlap?
- For **multi-document** retrieval, how to balance results across documents?
- What's the cost / benefit of adding a **reranker**?
- How does **query rewriting** improve retrieval quality?
- For agent + RAG setups, when should the agent decide to retrieve vs answer from memory?

---

## 14. Things to dig into

- **HyDE paper**: Gao et al., 2022 — *Precise Zero-Shot Dense Retrieval without Relevance Labels*.
- **Reranking** with `cohere-rerank` or `bge-reranker`.
- **Hybrid search guide**: Pinecone / Weaviate docs.
- **Hands-on**: build the vanilla pipeline, test with 10 queries on a real corpus, note where retrieval misses. That's the input to deciding which upgrade to apply.

---

## 15. Next up in this section

Time to start implementing. The next 5 notes build the indexing + retrieval phases in code:

- [ ] [[06 - Setting up Qdrant with Docker]] — the vector DB.
- [ ] [[07 - Introduction to LangChain]] — the glue.
- [ ] [[08 - Loading PDFs with PyPDFLoader]] — step 1 of indexing.
- [ ] [[09 - Smart Chunking with RecursiveCharacterTextSplitter]] — step 2.
- [ ] [[10 - Creating Vector Embeddings and Storing in Qdrant]] — steps 3 & 4.
- [ ] [[11 - Building the Retrieval (chat.py)]] — the full retrieval phase.

---

## Related
- [[04 - The Indexing Phase]] — the offline side.
- [[07 - Vector Embeddings]] — the underlying technology.
- [[04 - Episodic Memory in LLMs]] — same retrieval pattern, different use case.

## Sources
- Gao et al., *Precise Zero-Shot Dense Retrieval without Relevance Labels* (HyDE, 2022) — https://arxiv.org/abs/2212.10496
- Cohere reranker docs — https://docs.cohere.com/docs/reranking
