---
title: Section Intro - RAG
date: 2026-05-28
source: "Section 8 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - rag
  - retrieval-augmented-generation
  - section-overview
  - enterprise-ai
  - production-ai
  - foundations
related:
  - "[[01 - Section Intro - Welcome to Agentic AI]]"
  - "[[04 - Episodic Memory in LLMs]]"
  - "[[07 - Vector Embeddings]]"
---

# Section Intro — RAG

> [!NOTE]
> **TL;DR**
> **RAG (Retrieval-Augmented Generation)** is the most common and most economically important agentic-AI pattern in industry — roughly **90% of what big companies are doing right now**. The section covers the full pipeline: indexing documents into a vector database, then retrieving relevant chunks at query time and injecting them into the LLM's context. By the end: a chat-with-PDF system that answers questions about a 100-page Node.js book with page-level citations, running locally with **Qdrant** as the vector database and **LangChain** for the glue code. This is production-grade material — most enterprise AI products are some flavor of this pipeline.

> [!NOTE]
> **Where this fits**
> First lecture of **Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)**. Builds on the agent loop from [[01 - Section Intro - Welcome to Agentic AI|Section 7]] by giving the agent access to **private domain data** the LLM was never trained on. The next section ([[Section 22]]) makes this RAG pipeline asynchronous and scalable for production.

---

## 1. Why RAG matters

RAG is one of the most important and most common use cases in agentic AI and agentic workflows. Roughly 90% of what big companies and industries are shipping right now is RAG in some form — worth paying extra attention to this section.

Almost every "enterprise AI" product is RAG underneath:

| Product | What RAG does for it |
|---|---|
| **Chat with your docs** (Notion AI, Confluence AI) | Ground answers in the company's wiki |
| **Customer support bots** | Retrieve relevant FAQ + ticket history |
| **Legal AI** (Harvey, etc.) | Pull relevant case law + contracts |
| **Code search** (Cursor, Cody) | Retrieve relevant repo code |
| **Research assistants** | Ground in private paper libraries |
| **Internal knowledge** (Glean, etc.) | Find relevant content across SaaS apps |

That's why this section is production-grade material.

---

## 2. What this section will build

The deliverable: a **chat-with-PDF** application that can answer questions about a 100-page Node.js book with **page-level citations**.

```
User: "Can you help me understand debugging in Node.js?"

RAG: Here's a quick overview based on the guide:
     [explanation drawn from actual book content]

     For more details, see page 23 and 24.
```

Behind the scenes:
1. The PDF was chunked into ~200 paragraphs.
2. Each chunk was embedded into a vector.
3. Vectors are stored in **Qdrant** (local vector database).
4. User query is embedded.
5. Vector similarity search returns the top-K most relevant chunks.
6. Those chunks + query are sent to the LLM.
7. LLM answers with citations.

Every step gets its own dedicated lecture in this section.

---

## 3. The section's progression

| # | Lecture | What it covers |
|---|---|---|
| 02 | [[02 - The Problem RAG Solves]] | The enterprise problem (private data + context window limits) |
| 03 | [[03 - What is RAG and the Naive Approach]] | Definition + naive "stuff everything in system prompt" approach |
| 04 | [[04 - The Indexing Phase]] | Chunking → embedding → vector storage |
| 05 | [[05 - The Retrieval Phase]] | Query embedding → similarity search → context injection |
| 06 | [[06 - Setting up Qdrant with Docker]] | Vector DB setup |
| 07 | [[07 - Introduction to LangChain]] | The Swiss-army knife for AI plumbing |
| 08 | [[08 - Loading PDFs with PyPDFLoader]] | Read PDF page-by-page |
| 09 | [[09 - Smart Chunking with RecursiveCharacterTextSplitter]] | Chunk size + overlap |
| 10 | [[10 - Creating Vector Embeddings and Storing in Qdrant]] | OpenAI embeddings → Qdrant |
| 11 | [[11 - Building the Retrieval (chat.py)]] | The chat application |

By Lecture 11, the chat-with-PDF agent works end-to-end.

---

## 4. Prerequisites already covered

This section assumes deep familiarity with concepts from earlier sections:

| Prior concept | Used in Section 8 as |
|---|---|
| [[07 - Vector Embeddings]] | The core technology of RAG |
| [[04 - Episodic Memory in LLMs]] | Same retrieval pattern, different scope (docs vs interactions) |
| [[02 - Using OpenAI API in Python]] | The LLM endpoint that consumes retrieved context |
| [[02 - What is Prompting]] | System prompt that contains the retrieved context |
| [[02 - Docker Deep Dive]] | Vector DB will run in Docker |
| [[02 - What are AI Agents]] | Conceptual: an "agent with retrieval tool" |

Nothing new conceptually — RAG is **putting existing pieces together** in a particular pattern.

---

## 5. Why RAG is the agent's natural complement

In [[01 - Section Intro - Welcome to Agentic AI|Section 7]], agents got access to **the live world** via tools (APIs, file systems). RAG completes the picture by giving them access to **private knowledge**:

| Capability | Via | Section |
|---|---|---|
| Real-time data | Tool calls (e.g., weather API) | Section 7 |
| Private docs / knowledge | RAG retrieval | Section 8 (this one) |
| Persistent user facts | Memory layer | Section 13 |
| Live web search | Tool call + RAG hybrid | Section 8-9 + agents |

An agent with all three is what powers products like ChatGPT's "browse with bing," Claude with file uploads, Perplexity, etc.

---

## 6. Mindset for this section

| Mindset | Why |
|---|---|
| **Chunking is engineering, not magic** | Chunk size + overlap dramatically affects quality. Iterate. |
| **The vector DB is the heart** | Quality of retrieval = quality of the whole system. |
| **Citations are non-negotiable** | Users need to verify; without source links RAG output is just opinion. |
| **Embeddings ≠ understanding** | A vector similarity hit can be wrong; expect 70-90% accuracy, not 100%. |
| **Latency adds up** | Embed → search → LLM call = 1-5 seconds end-to-end. Optimize per-step. |
| **Production is async** | Indexing 10k docs synchronously will time out. Section 9 handles this. |

---

## 7. Main takeaways

- **RAG = retrieve relevant chunks at query time, inject into LLM context.**
- The pattern behind ~90% of enterprise AI products.
- Two phases: **indexing** (offline, batch) and **retrieval** (online, per-query).
- Section will build a chat-with-PDF system with citations.
- Tech stack: **Qdrant** (vector DB) + **LangChain** (utilities) + **OpenAI** (LLM + embeddings).
- All concepts already familiar — RAG combines them in a specific pattern.
- Section 9 makes this scalable / async / production-ready.

---

## 8. Things I want to come away with

- A clear mental model of indexing vs retrieval phases.
- Knowing **chunk size + overlap** trade-offs.
- Knowing **why** Qdrant (or any vector DB) is essential — what they store + how.
- Being able to debug "why didn't my RAG retrieve the right chunk?".
- Understanding the **cost** decomposition (embedding $, storage $, LLM $).

---

## 9. Things to dig into

- **The original paper**: Lewis et al., *Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks* (2020) — https://arxiv.org/abs/2005.11401
- **LlamaIndex docs**: a popular alternative to LangChain, specifically optimized for RAG.
- **Vector DB shootout**: comparison articles between Pinecone / Weaviate / Qdrant / Chroma / pgvector.
- **Anthropic's RAG guide**: https://docs.anthropic.com — practical patterns for Claude RAG.

---

## 10. Next up in this section

- [ ] [[02 - The Problem RAG Solves]] — the enterprise problem statement.

---

## Related
- [[07 - Vector Embeddings]] — the underlying technology.
- [[04 - Episodic Memory in LLMs]] — same pattern, different use case.
- [[02 - What are AI Agents]] — RAG is "agent + retrieval tool".

## Sources
- Lewis et al., *Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks* (2020) — https://arxiv.org/abs/2005.11401
