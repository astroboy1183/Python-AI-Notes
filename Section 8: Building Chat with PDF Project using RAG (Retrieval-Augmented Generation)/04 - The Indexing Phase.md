---
title: The Indexing Phase
date: 2026-05-28
source: "Section 8 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - rag
  - indexing
  - chunking
  - vector-embeddings
  - vector-database
  - qdrant
  - pinecone
  - foundations
related:
  - "[[03 - What is RAG and the Naive Approach]]"
  - "[[05 - The Retrieval Phase]]"
  - "[[07 - Vector Embeddings]]"
---

# The Indexing Phase

> [!abstract] TL;DR
> The **indexing phase** is the offline, batch step where the entire corpus is pre-processed into a searchable form. Four sub-steps: (1) **load** the documents, (2) **chunk** them into smaller pieces (paragraph-level, page-level, or fixed character size — engineering decision), (3) **embed** each chunk into a vector using an embedding model (OpenAI's `text-embedding-3-large` or similar), and (4) **store** the vectors + original text + metadata in a **vector database** (Pinecone, Qdrant, Weaviate, Chroma, pgvector, etc.). Runs once when data arrives or updates; the cost is amortized across all future queries. By the end, every chunk of the corpus is **semantically searchable** in milliseconds.

> [!info] Where this fits
> Fourth lecture of **Section 8: Building Chat with PDF Project using RAG**. The first of the two phases. The next note ([[05 - The Retrieval Phase]]) covers how this index is **used** at query time. Notes 6-10 implement this phase in code.

---

## 1. Why "indexing" is the right word

The term is borrowed from search engines:
- **Index** = a pre-built structure that makes lookups fast.
- Google indexes the web so queries return in milliseconds.
- RAG indexes a corpus so semantic queries return in milliseconds.

The indexing phase is where users provide the data. Indexing and retrieval are two completely different phases with different code paths.

The separation matters because:
- Indexing is **slow, expensive, batchable**.
- Retrieval is **fast, cheap, real-time**.
- Splitting them = paying the high cost once, reaping the benefit forever.

---

## 2. The four steps

```
┌──────────────────────────────────────────────────────────────┐
│  INDEXING PIPELINE                                            │
│                                                               │
│  ① LOAD     PDFs / Word / HTML / DB rows → raw text          │
│             │                                                 │
│             ▼                                                 │
│  ② CHUNK    Long documents → small chunks (paragraphs etc.)  │
│             │                                                 │
│             ▼                                                 │
│  ③ EMBED    Each chunk → 1,536-dim vector                    │
│             │                                                 │
│             ▼                                                 │
│  ④ STORE    Vector DB: vectors + text + metadata             │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

Each step gets a dedicated implementation note later in the section ([[08 - Loading PDFs with PyPDFLoader]], [[09 - Smart Chunking with RecursiveCharacterTextSplitter]], [[10 - Creating Vector Embeddings and Storing in Qdrant]]).

---

## 3. Step 1 — Load

Convert source files into text + metadata.

| Source | Loader |
|---|---|
| PDF | `PyPDFLoader` (LangChain), `pdfplumber`, `pymupdf` |
| Word (.docx) | `Docx2txtLoader`, `python-docx` |
| HTML / Web pages | `WebBaseLoader`, `BeautifulSoup` |
| Markdown | `UnstructuredMarkdownLoader` |
| CSV / Excel | `CSVLoader`, `pandas` |
| Database rows | Custom: `SELECT * FROM ...` |
| Slack / Notion / Google Drive | LangChain integrations |

For this section's deliverable: a single PDF, loaded via `PyPDFLoader` ([[08 - Loading PDFs with PyPDFLoader]]).

Output of the load step: a list of `Document` objects, each containing:
- `page_content`: the text.
- `metadata`: source, page number, etc.

---

## 4. Step 2 — Chunk

Split long documents into smaller pieces.

### Why chunking is needed

Two reasons:

| Reason | Detail |
|---|---|
| **Embedding model context limits** | Most embedding models have ~8k token input limits |
| **Retrieval precision** | Smaller chunks = more targeted retrieval, better signal-to-noise |

### Chunking strategies

| Strategy | How it splits |
|---|---|
| **Fixed character count** | Every N characters (e.g., 1,000) |
| **Page-level** | Every page is one chunk |
| **Paragraph-level** | Every paragraph is one chunk |
| **Sentence-level** | Every sentence is one chunk |
| **Recursive character** | Split on a hierarchy of separators (newlines → periods → spaces) |
| **Semantic chunking** | Split where embedding distance changes a lot (advanced) |
| **Document-structure-aware** | Use headings / sections / chapters |

Chunking simply means splitting the data into smaller parts. You can chunk page-by-page (one page per chunk), paragraph-by-paragraph, or by fixed character counts (e.g., 250 characters at a time) — it's an engineering choice.

This section uses the **recursive character splitter** (covered in [[09 - Smart Chunking with RecursiveCharacterTextSplitter]]) — a reasonable default.

### Chunk size + overlap

Two knobs:

| Parameter | What it controls | Typical |
|---|---|---|
| **Chunk size** | Max characters per chunk | 500-2000 |
| **Chunk overlap** | Characters shared between adjacent chunks | 100-500 |

Overlap exists because **important information often spans chunk boundaries**. Without it, the model loses context at every boundary. With it, the previous chunk's last few sentences appear at the start of the next chunk.

```
[chunk 1: A B C D E F]
              [chunk 2: D E F G H I]   ← E,F overlap
                        [chunk 3: G H I J K L]
```

Trade-offs:
- **Bigger chunks** = more context per retrieval, but less precise + higher per-chunk cost.
- **Smaller chunks** = more precise retrieval, but lose surrounding context.
- **More overlap** = better continuity, but more storage and embedding cost.

> [!tip] Practical starting point
> `chunk_size=1000, chunk_overlap=200` — covered explicitly later in the section.

---

## 5. Step 3 — Embed

Convert each chunk into a vector using an **embedding model**.

### What embeddings are
A reminder from [[07 - Vector Embeddings]]:
- A vector is a list of floats (1,536 of them for OpenAI's `text-embedding-3-large`).
- The vector captures the **semantic meaning** of the chunk.
- Two chunks with similar meanings → similar vectors.

### Which embedding models

| Model | Provider | Dimensions | Notes |
|---|---|---|---|
| `text-embedding-3-large` | OpenAI | 3,072 (configurable) | Section's choice |
| `text-embedding-3-small` | OpenAI | 1,536 | Cheaper |
| `BGE-large-en-v1.5` | BAAI (open) | 1,024 | Top free model |
| `voyage-large-2` | Voyage AI | 1,536 | Strong proprietary |
| `cohere-embed-v3` | Cohere | 1,024 | Multilingual |

Every chunk is passed to the embedding model, which produces a vector embedding for it.

Important: **same embedding model must be used at index time and query time**. Switching models = whole corpus must be re-embedded.

### Cost
OpenAI embeddings (rough):
- `text-embedding-3-large`: ~$0.13 per 1M input tokens.
- Indexing a 100-page book (~50k tokens) costs ~$0.007 — a cent.
- Indexing 50,000 PDFs at 10 pages each (~25M tokens) ≈ $3.

Embedding cost is **negligible** compared to LLM inference cost. Embed everything.

---

## 6. Step 4 — Store in a vector database

The embeddings + original chunks + metadata get stored in a **vector database** — a specialized database optimized for similarity search.

### Vector DB landscape

| Database | Type | Strength |
|---|---|---|
| **Pinecone** | Managed SaaS | Production-ready, easiest cloud setup |
| **Weaviate** | Open source + cloud | Strong hybrid search |
| **Qdrant** | Open source + cloud | Fast, lightweight (section's choice) |
| **Chroma** | Open source | Embedded, simple |
| **Milvus** | Open source | Scale-out, big data |
| **pgvector** | Postgres extension | Re-use existing Postgres infra |
| **Elasticsearch** | Search engine | Hybrid keyword + vector |
| **Redis** | Cache + vector | Fast, in-memory |

My pick: **Qdrant** — very easy to set up, lightweight, and fast. Self-hostable via Docker. Covered in [[06 - Setting up Qdrant with Docker]].

### What gets stored per chunk

| Field | Value |
|---|---|
| **id** | Unique ID for the chunk |
| **vector** | The embedding (e.g., 1,536 floats) |
| **payload.text** | The original chunk content |
| **payload.metadata** | Page number, document name, chunk index, timestamps, etc. |

Vectors are stored alongside their **payload** so retrieval returns both the vector match and the original text.

---

## 7. The full state after indexing

For a 100-page PDF chunked at ~1,000 characters / 200 overlap, expect roughly:

| Step | Approximate count |
|---|---|
| Pages loaded | 100 |
| Chunks produced | 150-250 |
| Vectors generated | 150-250 |
| Vector DB rows | 150-250 |
| Storage size | A few MB |
| Time to index | 10-60 seconds (mostly OpenAI API latency) |
| Cost | ~$0.01 (one cent) |

---

## 8. Mental model — what you've built

After indexing, the corpus has become a **searchable knowledge graph**:

```
Vector DB:
  ┌──────┐
  │ id=1 │ vector=[0.21, -0.45, 0.78, …]
  │      │ payload: { text: "<chunk 1 text>",
  │      │            page: 1,
  │      │            source: "nodejs.pdf" }
  └──────┘
  ┌──────┐
  │ id=2 │ vector=[0.18, -0.40, 0.71, …]
  │      │ payload: { text: "<chunk 2 text>",
  │      │            page: 1,
  │      │            source: "nodejs.pdf" }
  └──────┘
  ...
```

Each row knows: where the text came from + a vector encoding of its meaning. The retrieval phase will exploit both.

---

## 9. Variations of indexing in production

The pipeline above is the canonical version. Production setups vary in several ways:

| Variation | What it adds |
|---|---|
| **Async indexing** | Use queues (RabbitMQ, Kafka) — Section 9 covers this |
| **Incremental updates** | Re-index only changed docs |
| **Deduplication** | Identical chunks across docs only stored once |
| **Reranking embeddings** | Rerank with cross-encoders before final results |
| **Multi-vector per chunk** | Multiple representations (title + body) per chunk |
| **Image / table extraction** | OCR + table-to-text for complex PDFs |
| **Access control metadata** | Tag chunks with user/role permissions |

For learning, the canonical pipeline is plenty. Section 9 layers on async.

---

## 10. When indexing happens

| Trigger | When |
|---|---|
| **Initial bulk import** | One-off, at launch |
| **New document uploaded** | On upload event |
| **Document modified** | Re-chunk + re-embed |
| **Document deleted** | Remove vectors from DB |
| **Embedding model upgrade** | Re-embed everything |
| **Scheduled** | Nightly batch for updates |

Most production RAG systems run a mix: bulk import at launch + event-driven updates + periodic re-embedding when the embedding model is upgraded.

---

## 11. Main takeaways

- **Indexing** = offline pre-processing of the corpus into a searchable vector form.
- Four steps: **load → chunk → embed → store**.
- **Chunking strategy** matters: page / paragraph / fixed character / recursive.
- **Chunk size + overlap** are tunable knobs (start with `1000` / `200`).
- **Embedding model** must be consistent at index time and query time.
- **Vector DB** stores: vector + original text + metadata per chunk.
- Section uses **Qdrant** (open-source, fast, lightweight).
- Indexing is **slow + expensive**; retrieval is **fast + cheap**. The split is the win.
- A 100-page PDF indexes in ~30 seconds for ~$0.01.
- Production variations: async, incremental, dedup, reranking — covered in Section 9.

---

## 12. Things I still want to figure out

- How to **pick chunk size** for a specific corpus type (code vs prose vs legal docs)?
- For **PDFs with tables and images**, what's the best loader / processing approach?
- What's the **cost / quality** trade-off between `text-embedding-3-small` and `text-embedding-3-large`?
- How does **vector compression** (Matryoshka embeddings) work?
- For really large corpora (100M+ chunks), what's the right DB?
- How is **embedding model drift** handled when upgrading?

---

## 13. Things to dig into

- **OpenAI embeddings docs**: https://platform.openai.com/docs/guides/embeddings
- **Chunking guide**: https://www.pinecone.io/learn/chunking-strategies/
- **Vector DB comparison**: https://benchmark.vectorview.ai
- **Hands-on**: index the same PDF with three chunk sizes (500, 1000, 2000) and observe retrieval differences.

---

## 14. Next up in this section

- [ ] [[05 - The Retrieval Phase]] — how the index is used at query time.

---

## Related
- [[03 - What is RAG and the Naive Approach]] — the problem this phase addresses.
- [[07 - Vector Embeddings]] — what the embeddings are.
- [[04 - Episodic Memory in LLMs]] — analogous pattern, different use case.

## Sources
- OpenAI embeddings docs — https://platform.openai.com/docs/guides/embeddings
- Pinecone chunking guide — https://www.pinecone.io/learn/chunking-strategies/
- Vector DB benchmark — https://benchmark.vectorview.ai
