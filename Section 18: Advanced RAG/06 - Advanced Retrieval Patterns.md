---
title: Advanced Retrieval Patterns
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 18: Advanced RAG"
tags:
  - rag
  - retrieval
  - agentic-rag
  - parent-document
  - foundations
related:
  - "[[05 - Query Transformation]]"
  - "[[02 - Chunking Strategies]]"
  - "[[02 - What are AI Agents]]"
---

# Advanced Retrieval Patterns

> [!NOTE]
> **TL;DR**
> A grab-bag of structural patterns that go beyond "embed chunk, retrieve chunk." **Parent-document retrieval** (a.k.a. small-to-big): embed small chunks for precise *matching* but return the larger parent for rich *context* — resolving the chunk-size tension from note 02. **Contextual retrieval**: prepend an LLM-generated summary of the document to each chunk before embedding, so isolated chunks keep their context. **Metadata filtering**: combine semantic search with hard filters (date, source, user) so retrieval is scoped correctly. **Multi-vector / summary indexing**: index summaries or hypothetical questions that point to full docs. And the big one — **agentic RAG**: instead of one fixed retrieve-then-answer pass, an **agent decides** whether to retrieve, what to query, whether to retrieve *again*, and which source to use — turning RAG from a pipeline into a loop. These patterns handle the cases simple top-k can't.

> [!NOTE]
> **Where this fits**
> Final note of **Section 18**. It collects structural retrieval patterns and connects RAG to the agents from §7 (agentic RAG). The decomposition idea from [[05 - Query Transformation]] leads straight here.

---

## 1. Parent-document retrieval (small-to-big)

The chunk-size tension from [[02 - Chunking Strategies]]: small chunks match precisely but lack context; large chunks have context but match poorly. **Decouple matching from returning:**

```
INDEX:   parent doc → split into small child chunks → embed CHILDREN
SEARCH:  match on a small child (precise) → RETURN its parent (rich context)
```

So I embed sentences/small chunks for sharp similarity, but hand the LLM the whole paragraph or section. Best of both.

---

## 2. Contextual retrieval

A chunk ripped from a document loses its context ("It costs $20" — *what* costs $20?). Fix: before embedding, **prepend a short LLM-generated context** describing where the chunk sits.

```
raw chunk:        "It costs $20 per month."
contextualized:   "[From the Pro plan section of pricing.pdf]
                   The Pro plan: It costs $20 per month."
```

Now the embedding (and the retrieved text) carries the context, dramatically improving retrieval of otherwise-ambiguous chunks. Costs an LLM call per chunk at index time.

---

## 3. Metadata filtering

Pure semantic search ignores hard constraints. Attach metadata at chunk time ([[02 - Chunking Strategies]]) and filter on it:

```python
results = store.search(
    query="vacation policy",
    filter={"department": "HR", "year": {"$gte": 2025}},  # hard filter
    k=5,
)
```

> [!TIP]
> **Filter narrows; semantics rank**
> Use metadata to **restrict** the search space (only this user's docs, only recent versions, only this language), then let vector/hybrid search rank within it. This prevents the classic leak of retrieving another tenant's or an outdated document.

---

## 4. Multi-vector / summary indexing

Index **multiple representations** that point to the same source document:

- **Summary index**: embed an LLM summary of each doc; match on the summary, return the full doc.
- **Hypothetical-question index**: generate the questions a doc could answer, embed those; user questions match generated questions well.

Both make matching easier without bloating what's returned.

---

## 5. Agentic RAG — the big shift

Naive RAG is a **fixed pipeline**: always retrieve once, then answer. **Agentic RAG** puts an **agent** (from §7) in charge of retrieval as a **tool**:

```
question ─► AGENT ─┬─ decide: do I even need to retrieve?
                   ├─ if yes: choose query + source, call retrieve tool
                   ├─ inspect results: enough? if not, retrieve AGAIN (new query)
                   ├─ maybe decompose into sub-questions (note 05)
                   └─ synthesize answer when satisfied
```

| Naive RAG | Agentic RAG |
|---|---|
| Always retrieves once | Retrieves **0..n** times, as needed |
| Fixed query (the user's) | Agent **reformulates** queries |
| One source | **Routes** among multiple sources/tools |
| No self-check | Can judge results and **re-try** |

> [!IMPORTANT]
> **Agentic RAG = retrieval as a tool in an agent loop**
> This unifies everything: the agent loop (§7), query transformation (note 05), reranking (note 04), and tool routing. It handles multi-hop questions, decides when retrieval is unnecessary (saving cost), and recovers from bad first retrievals — at the price of more LLM calls and latency. LangGraph (§11) is a natural way to build the control flow.

---

## 6. Choosing patterns

```
chunks lose context on retrieval     → parent-document / contextual retrieval
need hard scoping (tenant, date)      → metadata filtering
matching is the weak point            → multi-vector / summary / hypothetical-Q indexing
complex, multi-hop, or variable need  → agentic RAG
```

Stack only what the **RAGAS metrics** (§17) say you need — each pattern adds cost/latency/complexity.

---

## 7. Main takeaways

- **Parent-document (small-to-big)**: embed small for matching, return large for context.
- **Contextual retrieval**: prepend LLM-generated context to chunks before embedding.
- **Metadata filtering**: hard filters scope the search; semantics rank within it.
- **Multi-vector / summary / hypothetical-question** indexing eases matching.
- **Agentic RAG**: an agent decides *whether/what/how often* to retrieve — retrieval as a **tool** in a loop.
- Agentic RAG unifies the agent loop, query transformation, reranking, and routing.
- Handles **multi-hop** and "no retrieval needed" cases naive RAG can't.
- Add patterns **only where RAGAS shows a gap** — they cost latency/complexity.

---

## 8. Things I still want to figure out

- When does **agentic RAG**'s extra cost beat a well-tuned static pipeline?
- Parent-document vs contextual retrieval — which wins, when?
- How to cap **retrieval loops** so an agent doesn't spiral?

---

## 9. Things to dig into

- LangChain **ParentDocumentRetriever**, **MultiVectorRetriever**.
- **Contextual Retrieval** (Anthropic write-up).
- **Agentic RAG** with LangGraph (§11).
- Self-RAG / Corrective RAG (CRAG) papers.

---

## 10. Section wrap-up

Section 18 turns naive RAG into a real **retrieval pipeline**: fix the index (**chunking**), widen retrieval (**hybrid search**), sharpen it (**reranking**), improve the query (**transformation**), and add **structural/agentic patterns** for the hard cases — all measured by RAGAS (§17). Net effect: dramatically higher recall *and* precision, which is what makes RAG trustworthy in production.

---

## Related
- [[05 - Query Transformation]] — decomposition leads into agentic RAG.
- [[02 - Chunking Strategies]] — parent-document resolves its size tension.
- [[02 - What are AI Agents]] — the agent loop behind agentic RAG.

## Sources
- [Anthropic: Contextual Retrieval](https://www.anthropic.com/news/contextual-retrieval)
- [LangChain retrievers](https://python.langchain.com/docs/how_to/#retrievers)
