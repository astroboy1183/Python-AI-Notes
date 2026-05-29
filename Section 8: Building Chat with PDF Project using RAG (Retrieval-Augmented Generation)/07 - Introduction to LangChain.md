---
title: Introduction to LangChain
date: 2026-05-28
source: "Section 8 / Lecture 7"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - langchain
  - python
  - utilities
  - document-loaders
  - text-splitters
  - embeddings
  - vector-stores
  - hands-on
related:
  - "[[06 - Setting up Qdrant with Docker]]"
  - "[[08 - Loading PDFs with PyPDFLoader]]"
  - "[[10 - Creating Vector Embeddings and Storing in Qdrant]]"
---

# Introduction to LangChain

> [!NOTE]
> **TL;DR**
> **LangChain** is a Python library that provides **pre-built utilities** for common AI plumbing tasks: loading documents (PDFs, web pages, Slack, Notion), splitting text into chunks, calling embedding models, talking to vector databases, and orchestrating LLM calls. Without LangChain, every RAG pipeline reimplements the same boilerplate. With it: `pip install` the right packages, import a few classes, and the plumbing is done. **Modular by design** — install only what's needed (`langchain-community` for general utilities, `langchain-text-splitters`, `langchain-openai`, `langchain-qdrant`, etc.). The section uses LangChain for PDF loading, chunking, embeddings, and vector-store integration. Same job could be done from scratch — LangChain saves ~80% of the boilerplate.

> [!NOTE]
> **Where this fits**
> Seventh lecture of **Section 8: Building Chat with PDF Project using RAG**. Introduces the library used in notes 8-11 to actually implement the RAG pipeline. From here forward, every step uses a LangChain helper.

---

## 1. What LangChain is — and isn't

| What it is | What it isn't |
|---|---|
| A toolkit of **AI plumbing utilities** | A magic AI framework |
| A **glue layer** between models, vector DBs, files | The intelligence itself |
| An **abstraction** over many providers | A replacement for understanding the underlying APIs |
| Lots of **pre-built loaders, splitters, integrations** | A bulletproof production system out of the box |

LangChain ships a lot of utility tools out of the box — frequently-used AI plumbing tasks that every developer used to rewrite from scratch. LangChain's pitch: *instead of everyone re-implementing this, here's a ready function — use it.*

---

## 2. What LangChain provides for this section

Specifically for RAG:

| Need | LangChain helper | Package |
|---|---|---|
| Load PDFs page-by-page | `PyPDFLoader` | `langchain-community` |
| Load web pages | `WebBaseLoader` | `langchain-community` |
| Load Word docs | `Docx2txtLoader` | `langchain-community` |
| Split text into chunks | `RecursiveCharacterTextSplitter` | `langchain-text-splitters` |
| OpenAI embeddings | `OpenAIEmbeddings` | `langchain-openai` |
| OpenAI chat | `ChatOpenAI` | `langchain-openai` |
| Qdrant integration | `QdrantVectorStore` | `langchain-qdrant` |
| Memory / chat history | `ConversationBufferMemory` | `langchain` |
| Chains / orchestration | `Runnable`, `RunnableSequence` | `langchain-core` |

For this section: only the first six rows matter.

---

## 3. The modular package structure

LangChain has split from one giant package into many small ones:

| Package | Contains |
|---|---|
| `langchain-core` | Base classes, interfaces |
| `langchain` | Main library — chains, agents, memory |
| `langchain-community` | Third-party integrations (loaders, vector stores) |
| `langchain-openai` | OpenAI-specific bindings |
| `langchain-anthropic` | Anthropic-specific bindings |
| `langchain-google-genai` | Gemini bindings |
| `langchain-qdrant` | Qdrant integration |
| `langchain-pinecone` | Pinecone integration |
| `langchain-text-splitters` | Text chunking utilities |
| `langchain-experimental` | Newer / experimental features |

> [!TIP]
> **Why modular?**
> The old monolithic `langchain` package pulled in **everything** as transitive dependencies — even features you didn't use. The modular split means: install only what's needed → smaller installs, fewer dependency conflicts.

---

## 4. Installing for this section

The section's pipeline needs:

```bash
pip install langchain-community pypdf
pip install langchain-text-splitters
pip install langchain-openai
pip install langchain-qdrant
```

Then freeze:

```bash
pip freeze > requirements.txt
```

The first two packages get installed in [[08 - Loading PDFs with PyPDFLoader]] (`langchain-community` is needed for `PyPDFLoader`, `pypdf` is the underlying PDF reader). Subsequent notes add the rest as needed.

> [!NOTE]
> **Tip**
> A safer one-liner that handles all four at once:
> ```bash
> pip install langchain-community pypdf langchain-text-splitters langchain-openai langchain-qdrant
> ```
> Installing progressively is good for teaching clarity; installing upfront avoids interrupting the flow.

---

## 5. The LangChain docs as a reference

The official docs are organized by **task type**, which is useful for browsing:

| Section | URL |
|---|---|
| Document loaders | https://python.langchain.com/docs/integrations/document_loaders/ |
| Text splitters | https://python.langchain.com/docs/concepts/text_splitters/ |
| Embeddings | https://python.langchain.com/docs/integrations/text_embedding/ |
| Vector stores | https://python.langchain.com/docs/integrations/vectorstores/ |
| Chat models | https://python.langchain.com/docs/integrations/chat/ |
| Tutorials | https://python.langchain.com/docs/tutorials/ |

For finding the right loader: navigate to **Document Loaders** → filter by source type (PDF, web, etc.). There are loaders for full web pages, unstructured data, recursive URLs, sitemaps, PDFs, and much more.

---

## 6. The mental model — LangChain as "stdlib for AI plumbing"

A useful analogy: LangChain is to RAG what Python's `requests` library is to HTTP.

| Without `requests` | Hand-write socket code, parse headers, handle encoding |
| With `requests` | `requests.get(url)` — one line |

| Without LangChain | Hand-write PDF parsing, chunking logic, vector DB API calls |
| With LangChain | `PyPDFLoader(path).load()` — one line |

Both libraries are **convenience layers** over things you could do from scratch. Both save 80%+ of the boilerplate.

---

## 7. Trade-offs — why some teams avoid LangChain

LangChain isn't universally loved:

| Criticism | Detail |
|---|---|
| **Over-abstraction** | The library invents new vocabulary (`Runnable`, `Chain`, `Agent`) that adds learning overhead |
| **Volatile API** | Breaking changes between minor versions |
| **Hidden behavior** | Sometimes things don't work and the abstraction makes debugging hard |
| **Bloat** | Even modular, dependencies add up |
| **Too much choice** | Three ways to do the same thing |
| **Slower than raw** | Adding a layer = small performance cost |

Alternatives some teams prefer:
- **LlamaIndex** — more focused on RAG specifically, less general.
- **Raw OpenAI SDK + a few helpers** — minimal, fully controllable.
- **Custom in-house** — for production with specific needs.

For learning RAG, **LangChain is fine**. For production, evaluate based on team taste and requirements.

> [!WARNING]
> **Don't conflate "Section uses LangChain" with "must always use LangChain"**
> This section uses LangChain because it's the most-documented approach and the easiest to learn with. Real production setups often replace LangChain with thinner wrappers once requirements stabilize.

---

## 8. The LangChain "Runnable" abstraction (preview)

For chaining steps together, LangChain offers a **functional pipeline syntax**:

```python
from langchain_core.runnables import RunnablePassthrough

chain = (
    {"context": retriever, "question": RunnablePassthrough()}
    | prompt_template
    | llm
    | output_parser
)

answer = chain.invoke("Tell me about case 32")
```

The `|` operator composes runnables. Each step is a function-like object. The chain becomes a clear declarative pipeline.

This section doesn't use the full chain syntax — sticks to explicit step-by-step code for clarity. But it's worth knowing the pattern exists for later.

---

## 9. The LangChain "Chain" vs "Agent" distinction

Two top-level abstractions worth knowing:

| Concept | What it is | When to use |
|---|---|---|
| **Chain** | Fixed sequence of steps (e.g., RAG pipeline) | Deterministic workflows |
| **Agent** | LLM decides next step dynamically | Open-ended tasks with tool selection |

This section's RAG = a **chain** (load → chunk → embed → store; or query → embed → search → LLM). The agents from [[Section 7]] are LangChain's "Agent" pattern, just implemented from scratch.

---

## 10. Practical advice for using LangChain

Some patterns that save grief:

| Tip | Why |
|---|---|
| Pin your version | `langchain==0.3.1` — avoid surprise breaking changes |
| Read the **source code** of utilities, not just docs | Behaviors aren't always documented |
| Use **`langchain-core` interfaces** in own code | Easier to swap implementations later |
| **Print intermediate results** | LangChain's chains can hide bugs; print the data between steps |
| Don't use `Agent` for simple workflows | Use `Chain` (or raw code) when steps are deterministic |
| Use the **standalone packages** | Don't `pip install langchain` if `langchain-openai` is enough |

---

## 11. What happens next

The next four notes use LangChain for each indexing step:

| Note | LangChain class |
|---|---|
| 08 — Loading PDFs | `PyPDFLoader` |
| 09 — Chunking | `RecursiveCharacterTextSplitter` |
| 10 — Embeddings + Qdrant | `OpenAIEmbeddings` + `QdrantVectorStore` |
| 11 — Retrieval | `QdrantVectorStore.from_existing_collection` |

By Note 11, the full pipeline is wired together.

---

## 12. Main takeaways

- **LangChain** = utility library for common AI plumbing tasks.
- Saves 80%+ of the boilerplate for RAG, agents, chains, embeddings, vector stores.
- **Modular** — install only the packages needed (`langchain-community`, `langchain-openai`, `langchain-qdrant`, etc.).
- This section uses LangChain for loading PDFs, chunking, embeddings, Qdrant integration.
- **Not universally loved** — over-abstraction and API churn are real criticisms.
- For learning RAG, LangChain is the standard. For production, evaluate other options.
- Two top-level abstractions: **Chain** (deterministic) vs **Agent** (LLM-driven).
- Docs organized by task type — easy to navigate.
- Mental model: LangChain is to RAG what `requests` is to HTTP.

---

## 13. Things I still want to figure out

- For complex RAG (hybrid search, reranking), is LangChain still the best fit?
- How does **LangGraph** (mentioned later in the course) relate to LangChain?
- What's the cost of LangChain's abstractions in **latency** specifically?
- For multi-language apps, are non-Python LangChain ports (JS, etc.) production-ready?
- When does **LlamaIndex** beat LangChain for RAG?
- How to handle **breaking changes** when upgrading LangChain versions?

---

## 14. Things to dig into

- **Official docs**: https://python.langchain.com/docs/
- **LangChain Academy** (free course): https://academy.langchain.com/
- **LlamaIndex** for comparison: https://docs.llamaindex.ai/
- **LangSmith** — paid observability tool for LangChain apps.
- **Hands-on**: read the source of `PyPDFLoader` (it's short) before using it. Builds confidence that LangChain isn't magic.

---

## 15. Next up in this section

Now use LangChain for the first concrete step:

- [ ] [[08 - Loading PDFs with PyPDFLoader]] — read a PDF page-by-page.

---

## Related
- [[06 - Setting up Qdrant with Docker]] — the vector DB this connects to.
- [[04 - The Indexing Phase]] — what LangChain helps build.
- [[08 - Loading PDFs with PyPDFLoader]] — first concrete use.

## Sources
- LangChain docs — https://python.langchain.com/docs/
- LangChain Academy — https://academy.langchain.com/
- LlamaIndex docs (comparison) — https://docs.llamaindex.ai/
