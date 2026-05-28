---
title: Creating Vector Embeddings and Storing in Qdrant
date: 2026-05-28
source: "Section 8 / Lecture 10"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - langchain
  - openai
  - embeddings
  - qdrant
  - vector-database
  - rag
  - indexing
  - text-embedding-3-large
  - hands-on
related:
  - "[[09 - Smart Chunking with RecursiveCharacterTextSplitter]]"
  - "[[06 - Setting up Qdrant with Docker]]"
  - "[[07 - Vector Embeddings]]"
  - "[[11 - Building the Retrieval (chat.py)]]"
---

# Creating Vector Embeddings and Storing in Qdrant

> [!abstract] TL;DR
> Final indexing step: convert each chunk into a vector and persist it in Qdrant. Use **`OpenAIEmbeddings(model="text-embedding-3-large")`** for the embedding model and **`QdrantVectorStore.from_documents(...)`** to do the embed-and-store in one call. Pass: `documents=chunks`, `embedding=embedding_model`, `url="http://localhost:6333"`, `collection_name="learning_rag"`. Behind the scenes: each chunk → OpenAI embeddings API → 3072-dim vector → Qdrant. Set `OPENAI_API_KEY` in a `.env` file and `load_dotenv()`. After running, the Qdrant dashboard at `http://localhost:6333/dashboard` shows the new collection with ~192 points, each storing the vector + chunk text + page metadata. **Indexing pipeline complete** — corpus is now semantically searchable.

> [!info] Where this fits
> Tenth lecture of **Section 8: Building Chat with PDF Project using RAG**. Completes the **indexing phase**. The next (and final) note ([[11 - Building the Retrieval (chat.py)]]) implements the retrieval side using the index built here.

---

## 1. The goal

Take the ~192 chunks from [[09 - Smart Chunking with RecursiveCharacterTextSplitter]] and persist them in Qdrant as searchable vectors.

```
192 chunks (Document objects with text + metadata)
         │
         ▼
OpenAI Embeddings API (per chunk)
         │
         ▼
192 vectors of size 3072 each
         │
         ▼
Qdrant collection "learning_rag"
  └── 192 points: { vector, payload: { text, page, source } }
```

---

## 2. The two helpers needed

| Helper | Package | What it does |
|---|---|---|
| `OpenAIEmbeddings` | `langchain-openai` | Calls OpenAI's embedding API |
| `QdrantVectorStore` | `langchain-qdrant` | Wraps Qdrant — handles inserts + queries |

Both abstract away the underlying API calls — no manual HTTP requests.

---

## 3. Install the packages

```bash
pip install langchain-openai
pip install langchain-qdrant
pip freeze > requirements.txt
```

Two more LangChain modules added.

---

## 4. Set up the embedding model

```python
from langchain_openai import OpenAIEmbeddings

embedding_model = OpenAIEmbeddings(
    model="text-embedding-3-large",
)
```

The instance:
- Reads `OPENAI_API_KEY` from environment (next section).
- Knows how to call OpenAI's embeddings API.
- Will be used by Qdrant to embed both chunks (at indexing) and queries (at retrieval).

### Why `text-embedding-3-large`?

OpenAI's flagship embedding model as of mid-2024:

| Model | Dimensions | Cost / 1M tokens | Quality |
|---|---|---|---|
| `text-embedding-3-small` | 1,536 | ~$0.02 | Good |
| `text-embedding-3-large` | 3,072 | ~$0.13 | **Better** (my choice here) |
| Older `text-embedding-ada-002` | 1,536 | ~$0.10 | Legacy, avoid |

The "large" model produces higher-quality embeddings — better semantic search. Cost per query is still measured in cents, so usually worth it.

> [!tip]
> Both 3-large and 3-small support **dimension reduction** via the `dimensions=...` parameter. Useful when storage cost matters: a 256-dim embedding is 1/12 the storage of full 3072 with surprisingly modest quality loss.

---

## 5. Set up `.env` for the API key

OpenAI calls require an API key. Standard pattern from earlier sections:

### `.env` file
Create `rag/.env`:
```
OPENAI_API_KEY=sk-...
```

### Load it in `index.py`
```python
from dotenv import load_dotenv
load_dotenv()
```

If `python-dotenv` isn't installed:
```bash
pip install python-dotenv
```

> [!warning] Don't commit `.env`
> Add to `.gitignore`:
> ```
> .env
> ```
> The key is sensitive. See [[01 - Setting up OpenAI Account]].

---

## 6. The one-shot indexer

`QdrantVectorStore.from_documents(...)` does everything in one call: embed all chunks → connect to Qdrant → create collection → insert all points.

```python
from langchain_qdrant import QdrantVectorStore

vector_store = QdrantVectorStore.from_documents(
    documents=chunks,
    embedding=embedding_model,
    url="http://localhost:6333",
    collection_name="learning_rag",
)
```

Parameters:

| Parameter | Value |
|---|---|
| `documents` | The list of chunks from the splitter |
| `embedding` | The `OpenAIEmbeddings` instance |
| `url` | Where Qdrant is running |
| `collection_name` | Logical namespace for these vectors |

Behind the scenes:
1. Connect to Qdrant.
2. Create the collection if it doesn't exist (with the right vector size).
3. For each chunk:
   - Call OpenAI to embed `chunk.page_content`.
   - Insert into Qdrant with vector + payload (text + metadata).
4. Return a `QdrantVectorStore` handle for further use.

The whole story: take a PDF path, load the PDF, split it into chunks, turn each chunk into a vector embedding, and store everything in the vector database. That's it.

---

## 7. The complete `index.py`

Putting it all together:

```python
from pathlib import Path

from dotenv import load_dotenv
from langchain_community.document_loaders import PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_openai import OpenAIEmbeddings
from langchain_qdrant import QdrantVectorStore

load_dotenv()

# 1. Load PDF
pdf_path = Path(__file__).parent / "nodejs.pdf"
loader = PyPDFLoader(file_path=pdf_path)
docs = loader.load()
print(f"Loaded {len(docs)} pages")

# 2. Chunk
text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,
    chunk_overlap=400,
)
chunks = text_splitter.split_documents(docs)
print(f"Split into {len(chunks)} chunks")

# 3. Embedding model
embedding_model = OpenAIEmbeddings(model="text-embedding-3-large")

# 4. Embed + store in Qdrant
print("Indexing chunks to Qdrant…")
vector_store = QdrantVectorStore.from_documents(
    documents=chunks,
    embedding=embedding_model,
    url="http://localhost:6333",
    collection_name="learning_rag",
)
print("✅ Indexing of documents done.")
```

Run:

```bash
python index.py
```

Output (illustrative):
```
Loaded 104 pages
Split into 192 chunks
Indexing chunks to Qdrant…
✅ Indexing of documents done.
```

Duration: ~30 seconds for this PDF (mostly OpenAI API latency).

---

## 8. Verifying in the Qdrant dashboard

Visit:
```
http://localhost:6333/dashboard
```

Click into **Collections** → **learning_rag**:

| What's visible | Meaning |
|---|---|
| Number of **segments** | Qdrant's internal storage units (~7 for this dataset) |
| Number of **points** | One per chunk (192) |
| **Vector size** | 3072 (matches `text-embedding-3-large`) |
| Sample point | Vector (3072 floats) + payload (text, page, source) |

Refresh the Qdrant dashboard and the `learning_rag` collection should appear — about seven segments, 192 points. Clicking into a point shows the vector embedding alongside its payload.

Each point looks roughly like:

```json
{
  "id": "abc123...",
  "vector": [0.21, -0.45, 0.78, ...],         // 3072 floats
  "payload": {
    "page_content": "Functions are first-class citizens in JavaScript...",
    "metadata": {
      "source": "/path/to/nodejs.pdf",
      "page": 12
    }
  }
}
```

The original chunk text + page metadata are preserved alongside the vector. Crucial for retrieval to show citations.

---

## 9. Cost breakdown

For this PDF (~150,000 characters across 192 chunks):
- ~50,000 tokens to embed (chunks have overlap, so total tokens > total chars / 4).
- At `text-embedding-3-large` rate (~$0.13 / 1M tokens): **~$0.007**.

Less than a cent. Embedding is genuinely cheap.

For a much bigger corpus (e.g., 50,000 documents × 10 pages × 500 chars/page = 250M chars ≈ 62M tokens):
- ~$8 total embedding cost.

Still cheap. **Storage** in Qdrant is also negligible for these sizes. The cost story for RAG is dominated by **inference at query time**, not indexing.

---

## 10. Idempotency / re-running

What if `python index.py` runs twice?

By default, `from_documents` **adds** to the collection — doesn't clear it. So running twice = 384 points (each chunk indexed twice). Usually not what's wanted.

Two ways to handle:

### Option A — Delete the collection first
```python
from qdrant_client import QdrantClient

client = QdrantClient(url="http://localhost:6333")
client.delete_collection("learning_rag")    # if exists
```

### Option B — Use deterministic IDs
Pass `ids=[stable_id_for_each_chunk]` so re-inserts overwrite rather than duplicate.

For learning, deleting + reindexing is fine. For production: deterministic IDs + incremental updates.

---

## 11. Common gotchas

> [!warning] First-time indexing issues

| Symptom | Cause | Fix |
|---|---|---|
| `OPENAI_API_KEY missing` | `.env` not loaded | Add `load_dotenv()` before any imports that need the key |
| `RateLimitError` | Burst of embedding calls | LangChain handles batching; just wait and retry |
| `Connection refused on localhost:6333` | Qdrant container not running | `docker compose ps`; `docker compose up -d` |
| `Vector dimensions mismatch` | Changed embedding model between runs | Delete collection, re-index |
| Indexing takes forever | Network slowness | Check network; OpenAI's API can be slow during peak times |
| `tiktoken_ext` errors | Old Python or missing build tools | Update Python, install build deps |
| Collection has wrong number of points | Re-ran without clearing | Delete + re-index, or use deterministic IDs |

---

## 12. State after this note

| Component | Status |
|---|---|
| Qdrant running | ✅ |
| PDF loaded | ✅ |
| Chunks generated | ✅ |
| **Embeddings created** | ✅ (192 vectors) |
| **Stored in Qdrant** | ✅ (collection `learning_rag` with 192 points) |
| Indexing pipeline | ✅ **COMPLETE** |
| Retrieval pipeline | ❌ (final note) |

The full indexing phase is done in **about 30 lines of Python**.

---

## 13. The indexing phase in one line

> ```
> PDF → PyPDFLoader → RecursiveCharacterTextSplitter → OpenAIEmbeddings → QdrantVectorStore
> ```

Each step is one LangChain helper. The whole pipeline = configuration, not code.

---

## 14. Main takeaways

- **`OpenAIEmbeddings(model="text-embedding-3-large")`** is the embedding model.
- **`QdrantVectorStore.from_documents(...)`** does embed + store in one call.
- Pass: `documents`, `embedding`, `url`, `collection_name`.
- Each chunk becomes a Qdrant **point**: vector (3072 dims) + payload (text + metadata).
- API key from `.env` via `python-dotenv`.
- Indexing this PDF: **~30 seconds, ~$0.01**.
- Verify in Qdrant dashboard at `localhost:6333/dashboard`.
- Re-running without clearing **duplicates** entries — use deterministic IDs or delete-first.
- **Indexing pipeline complete** in ~30 lines.

---

## 15. Things I still want to figure out

- For **incremental indexing** (new docs added daily), what's the cleanest pattern?
- How does **Matryoshka dimension reduction** trade off storage vs quality in practice?
- What's the right **batch size** for bulk indexing — LangChain handles it, but is the default optimal?
- For **multilingual** corpora, does `text-embedding-3-large` handle them well or does a multilingual-specific model do better?
- How to handle **embedding failures** gracefully (one chunk fails to embed)?
- For **really large corpora** (10M+ chunks), what's the right architecture?

---

## 16. Things to dig into

- **OpenAI embeddings docs**: https://platform.openai.com/docs/guides/embeddings
- **Qdrant Python client**: https://qdrant.tech/documentation/frameworks/langchain/
- **MTEB leaderboard** (best embedding models): https://huggingface.co/spaces/mteb/leaderboard
- **Hands-on**: compare `text-embedding-3-large` vs `text-embedding-3-small` on the same retrieval task. Note quality difference.

---

## 17. Next up in this section

The index is built. Now query it from chat.py:

- [ ] [[11 - Building the Retrieval (chat.py)]] — the user-facing chat loop.

---

## Related
- [[09 - Smart Chunking with RecursiveCharacterTextSplitter]] — provides the input.
- [[06 - Setting up Qdrant with Docker]] — the database this writes to.
- [[07 - Vector Embeddings]] — the underlying concept.
- [[04 - The Indexing Phase]] — the conceptual pipeline.
- [[01 - Setting up OpenAI Account]] — for the API key.

## Sources
- OpenAI embeddings docs — https://platform.openai.com/docs/guides/embeddings
- Qdrant LangChain integration — https://qdrant.tech/documentation/frameworks/langchain/
- MTEB leaderboard — https://huggingface.co/spaces/mteb/leaderboard
