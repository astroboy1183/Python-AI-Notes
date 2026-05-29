---
title: Building the Retrieval (chat.py)
date: 2026-05-28
source: "Section 8 / Lecture 11"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - rag
  - retrieval
  - chat
  - qdrant
  - openai
  - similarity-search
  - citations
  - python
  - hands-on
related:
  - "[[10 - Creating Vector Embeddings and Storing in Qdrant]]"
  - "[[05 - The Retrieval Phase]]"
  - "[[02 - Using OpenAI API in Python]]"
---

# Building the Retrieval (chat.py)

> [!NOTE]
> **TL;DR**
> Final note of Section 8 — implement the **retrieval phase** as a separate `chat.py` script. Same embedding model as indexing (`text-embedding-3-large`). Connect to the existing Qdrant collection via **`QdrantVectorStore.from_existing_collection(...)`**. On each user query: call `vector_store.similarity_search(query)` → get top-K chunks → build a context string with **page numbers and source paths** → inject into a system prompt → call `client.chat.completions.create(model="gpt-4o", ...)` → return the reply. The LLM cites page numbers in its answer so users can verify. **End-to-end working chat-with-PDF system in ~50 lines.** Demo: ask *"Can you help me understand debugging in Node.js?"* → agent answers from the actual book + cites pages 23-24. Section 8 closes; Section 9 makes this async + scalable.

> [!NOTE]
> **Where this fits**
> Eleventh and final lecture of **Section 8: Building Chat with PDF Project using RAG**. Closes out the section. Next: **Section 9 (Scalable RAG with Async Queues & Distributed Workers)** — production-grade version.

---

## 1. The structure — two files

The full project now has two Python files:

| File | Phase | Run when |
|---|---|---|
| `index.py` | Indexing | Once (on data ingestion) |
| `chat.py` | Retrieval | Every user query |

The clean separation is the whole point of RAG's two-phase architecture. `index.py` is heavy; `chat.py` is light.

---

## 2. Reusing pieces from `index.py`

Several blocks of `index.py` are needed in `chat.py` too:

| Reused | Why |
|---|---|
| `load_dotenv()` | OpenAI API key still needed |
| `OpenAIEmbeddings(...)` | Must embed the user's query |
| Qdrant URL, collection name | Connect to the right collection |

The **only difference**: `chat.py` uses `from_existing_collection(...)` instead of `from_documents(...)` — it reads instead of writes.

---

## 3. Connecting to the existing collection

```python
from langchain_qdrant import QdrantVectorStore

vector_store = QdrantVectorStore.from_existing_collection(
    embedding=embedding_model,
    url="http://localhost:6333",
    collection_name="learning_rag",
)
```

vs the indexing call:

```python
# Indexing (from_documents)
vector_store = QdrantVectorStore.from_documents(
    documents=chunks,                      # CREATES from data
    embedding=embedding_model,
    url="http://localhost:6333",
    collection_name="learning_rag",
)

# Retrieval (from_existing_collection)
vector_store = QdrantVectorStore.from_existing_collection(
    embedding=embedding_model,            # CONNECTS to existing
    url="http://localhost:6333",
    collection_name="learning_rag",
)
```

Different verb (`from_documents` vs `from_existing_collection`), same connection details. Here we use `from_existing_collection` because we're not storing anything new — we're reading from an already-built collection.

---

## 4. The similarity search

Given a user query, get the top-K relevant chunks:

```python
user_query = input("> ")

search_results = vector_store.similarity_search(query=user_query)
```

What this does behind the scenes:
1. Embed `user_query` using the same model.
2. Send the query vector to Qdrant.
3. Qdrant computes cosine similarity to all stored vectors.
4. Return the top-K (default 4 in LangChain's `similarity_search`) by score.

Each result is a `Document` with `page_content` + `metadata` — the original chunk text + page/source info.

In plain English: ask the vector DB to run a similarity search on the user's query. Back come the relevant chunks.

---

## 5. Building the context string

Format the retrieved chunks into something the LLM can use:

```python
context = "\n\n".join([
    f"Page Content: {result.page_content}\n"
    f"Page Number: {result.metadata['page']}\n"
    f"File Location: {result.metadata['source']}"
    for result in search_results
])
```

Each retrieved chunk gets formatted with:
- The text.
- The page number (so the LLM can cite it).
- The source file (in case there are multiple PDFs).

This formatted string becomes part of the system prompt.

> [!TIP]
> **Why include page/source explicitly**
> The LLM doesn't read the `metadata` dict — it only sees text. To make page-number citations possible, the metadata must be **embedded into the prompt as text**. The format above is a simple, working convention.

---

## 6. The system prompt

```python
system_prompt = f"""
You are a helpful AI assistant who answers user queries based on the
available context retrieved from a PDF file, along with page content
and page number.

You should only answer the user based on the following context and
navigate the user to open the right page number to know more.

Available context:
{context}
"""
```

Three key instructions encoded in the prompt:
1. **Use only the provided context** — reduces hallucinations.
2. **Cite page numbers** — explicit instruction for verifiable references.
3. **Help user "navigate"** — encourages "see page X for more" phrasing.

---

## 7. The LLM call

```python
from openai import OpenAI

client = OpenAI()

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": user_query},
    ],
)

print(f"🤖 {response.choices[0].message.content}")
```

Standard OpenAI call from [[02 - Using OpenAI API in Python]] — nothing RAG-specific about this step. The retrieval has already prepared the system prompt; the LLM just consumes it.

> [!NOTE]
> Any modern chat model works here — `gpt-4o`, `gpt-4o-mini`, Claude, etc. Pick based on cost/quality preference for the use case.

---

## 8. The complete `chat.py`

Putting it all together:

```python
from dotenv import load_dotenv
from openai import OpenAI
from langchain_openai import OpenAIEmbeddings
from langchain_qdrant import QdrantVectorStore

load_dotenv()

# Same embedding model as indexing
embedding_model = OpenAIEmbeddings(model="text-embedding-3-large")

# Connect to existing Qdrant collection
vector_store = QdrantVectorStore.from_existing_collection(
    embedding=embedding_model,
    url="http://localhost:6333",
    collection_name="learning_rag",
)

# OpenAI client for the chat call
client = OpenAI()

while True:
    user_query = input("\n🙋 > ")
    if not user_query.strip():
        break

    # Step 1: similarity search → top-K chunks
    search_results = vector_store.similarity_search(query=user_query)

    # Step 2: build context string with page citations
    context = "\n\n".join([
        f"Page Content: {result.page_content}\n"
        f"Page Number: {result.metadata['page']}\n"
        f"File Location: {result.metadata['source']}"
        for result in search_results
    ])

    # Step 3: system prompt grounded in retrieved chunks
    system_prompt = f"""
You are a helpful AI assistant who answers user queries based on the
available context retrieved from a PDF file, along with page content
and page number.

You should only answer the user based on the following context and
navigate the user to open the right page number to know more.

Available context:
{context}
"""

    # Step 4: LLM call
    response = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": user_query},
        ],
    )

    print(f"\n🤖 {response.choices[0].message.content}")
```

About 50 lines. End-to-end working chat-with-PDF system.

---

## 9. Demo runs

Two queries to try against the Node.js book:

### Query 1 — debugging
```
🙋 > Can you help me understand debugging in Node.js?

🤖 Here's a quick overview of debugging Node.js based on the guide:
   - Use `node --inspect` to start a debugger.
   - Set breakpoints with `debugger;` statements.
   - Chrome DevTools can connect via the inspector.
   - Use `console.log` for quick prints.

   For full details, see page 23 and 24.
```

Verifies by opening the PDF: yes, page 23 covers debugging.

### Query 2 — arrow functions
```
🙋 > Can you help me understand the concept of arrow functions?

🤖 Arrow functions are a more concise syntax for function expressions:
   - Syntax: `const add = (a, b) => a + b`
   - They don't have their own `this` binding.
   - Cannot be used as constructors.

   See page 20 and 21 for examples.
```

Verifies in the PDF: pages 20-21 indeed cover arrow functions. Opening the PDF to those pages, the explanation and example match — the answer is sourced from the book itself, not a hallucination. The citations let users verify.

---

## 10. End-to-end pipeline visualization

```
USER QUERY: "Can you help me understand debugging in Node.js?"
       │
       ▼
┌─────────────────────────────────────┐
│  OpenAIEmbeddings (same as indexing) │
│  embeds query → 3072-dim vector      │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Qdrant similarity_search             │
│  top-4 most similar chunks            │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  context = "Page Content: ...        │
│             Page Number: 23          │
│             File: nodejs.pdf"        │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  system_prompt = f"""                │
│   You are a helpful assistant.       │
│   Available context: {context}       │
│  """                                  │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  OpenAI Chat Completions             │
│  model: gpt-4o                       │
│  messages: [system, user]            │
└─────────────────────────────────────┘
       │
       ▼
USER SEES: "Here's a quick overview based on the guide…
            For details see page 23 and 24."
```

---

## 11. Why this works for any kind of data

This is the basic recipe for RAG over big files, big data, anything — and the input doesn't have to be a PDF. It can be any kind of data.

Swap `PyPDFLoader` for any other LangChain loader and the rest of the pipeline stays identical:

| Data source | Loader |
|---|---|
| PDF | `PyPDFLoader` |
| Web page | `WebBaseLoader` |
| Slack export | `SlackDirectoryLoader` |
| Notion export | `NotionDirectoryLoader` |
| GitHub repo | `GitLoader` |
| CSV | `CSVLoader` |
| Database rows | Custom |
| API responses | Custom |

Same chunk → embed → store → retrieve → generate pipeline. Just plug a different source in at the top.

---

## 12. Limitations / next steps

This implementation is **complete but minimal**. Production setups add:

| Limitation | Production fix | Where |
|---|---|---|
| Synchronous indexing | Async queue + workers | Section 9 |
| Single PDF | Multi-document support | Add directory traversal |
| No re-ranking | Cross-encoder rerank | Advanced RAG |
| No hybrid search | Add BM25 keyword search | LangChain has BM25 retriever |
| No chat history | Multi-turn conversation | Append to `messages` list |
| No citation parsing | Structured citations | Parse `[Page X]` from LLM reply |
| No filtering by metadata | Use Qdrant filters | `similarity_search(filter={...})` |
| No streaming | `stream=True` | OpenAI streaming |
| No auth | Add API key middleware | FastAPI + tokens |
| No UI | Build a frontend | React/Next.js |

For learning, the implementation above is plenty. Section 9 productionizes it.

---

## 13. End of Section 8

This closes out **Section 8: Building Chat with PDF Project using RAG**:

| Note | Topic |
|---|---|
| 01 | Section Intro — RAG |
| 02 | The Problem RAG Solves |
| 03 | What is RAG and the Naive Approach |
| 04 | The Indexing Phase |
| 05 | The Retrieval Phase |
| 06 | Setting up Qdrant with Docker |
| 07 | Introduction to LangChain |
| 08 | Loading PDFs with PyPDFLoader |
| 09 | Smart Chunking with RecursiveCharacterTextSplitter |
| 10 | Creating Vector Embeddings and Storing in Qdrant |
| 11 | Building the Retrieval (this note) |

**Working chat-with-PDF system** delivered. ~80 lines of code total across `index.py` and `chat.py`.

**Next**: Section 9 — **Scalable RAG with Async Queues & Distributed Workers**. Same pipeline, production-grade.

---

## 14. Main takeaways

- `chat.py` mirrors `index.py` but uses **`from_existing_collection`** instead of `from_documents`.
- Same embedding model as indexing — **mandatory**.
- `vector_store.similarity_search(query)` returns top-K chunks (default 4).
- Build context string with **page + source metadata** baked in.
- System prompt instructs the LLM to **cite pages**.
- Standard OpenAI `chat.completions.create` call with `[system, user]` messages.
- End-to-end: **~50 lines** for `chat.py`.
- Works for **any data source** — just swap the loader.
- Limitations: no async, no multi-turn, no re-rank, etc. Section 9 covers production.

---

## 15. Things I still want to figure out

- How to add **multi-turn conversation** (remember past Q&A in the same session)?
- For **multiple PDFs**, how to filter retrievals by document?
- What's the right way to do **streaming** so the user sees tokens as they generate?
- How to **detect when retrieval failed** (no relevant chunks) and tell the user?
- For **better citations**, should the LLM output JSON with explicit citation fields?
- How to add **hybrid search** (vector + BM25 keyword) for better recall?

---

## 16. Things to dig into

- **LangChain retriever docs**: https://python.langchain.com/docs/integrations/retrievers/
- **Reranking with `cohere-rerank`**: https://docs.cohere.com/docs/rerank-2
- **Streaming responses**: https://platform.openai.com/docs/api-reference/streaming
- **Hands-on**: turn `chat.py` into a FastAPI endpoint. Wrap with the [[06 - Connecting FastAPI to Ollama|FastAPI pattern]] from Section 5.

---

## 17. Next up

End of Section 8. Next:

- [ ] **Section 9: Scalable RAG with Async Queues & Distributed Workers** — production-ready RAG.

---

## Related
- [[05 - The Retrieval Phase]] — the conceptual model this implements.
- [[10 - Creating Vector Embeddings and Storing in Qdrant]] — the index this queries.
- [[02 - Using OpenAI API in Python]] — the underlying chat API.
- [[06 - Setting up Qdrant with Docker]] — the database.
- [[01 - Section Intro - RAG]] — section overview.

## Sources
- LangChain retriever docs — https://python.langchain.com/docs/integrations/retrievers/
- Cohere reranker — https://docs.cohere.com/docs/rerank-2
- OpenAI streaming docs — https://platform.openai.com/docs/api-reference/streaming
