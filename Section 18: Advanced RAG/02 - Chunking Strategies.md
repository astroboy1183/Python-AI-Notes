---
title: Chunking Strategies
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 18: Advanced RAG"
tags:
  - rag
  - chunking
  - retrieval
  - indexing
related:
  - "[[09 - Smart Chunking with RecursiveCharacterTextSplitter]]"
  - "[[01 - Beyond Naive RAG]]"
  - "[[03 - Hybrid Search]]"
---

# Chunking Strategies

> [!NOTE]
> **TL;DR**
> Chunking is the most underrated RAG lever — retrieval can only ever return a chunk, so **how I split documents caps the quality of everything downstream**. The tension: chunks too **small** lose context (a retrieved sentence with no surrounding meaning); too **large** dilute the embedding and drag in irrelevant text. Strategies, roughly from naive to smart: **fixed-size** (simple, breaks mid-thought), **recursive character** (respects paragraphs/sentences — §8's default), **document-structure-aware** (split on Markdown headers, code blocks, tables), and **semantic chunking** (split where meaning shifts). Two key knobs: **chunk size** and **overlap** (carry a little text between chunks so context isn't severed at the boundary). The right strategy depends on the document type — there's no universal best; tune it against RAGAS context metrics.

> [!NOTE]
> **Where this fits**
> Second note of **Section 18**, deepening the recursive splitter from [[09 - Smart Chunking with RecursiveCharacterTextSplitter]]. It's the indexing-phase fix from [[01 - Beyond Naive RAG]].

---

## 1. Why chunking is the foundation

The retriever returns **chunks**, and the LLM answers only from what it's given. So:

```
bad chunk boundaries → bad retrieved context → bad answer
                       (no later stage can fully recover)
```

A perfectly tuned reranker can't fix a chunk that was split mid-sentence and lost its meaning. **Chunking is upstream of everything.**

---

## 2. The core tension

```
too SMALL ──────────────────────────► too LARGE
lose surrounding context              embedding diluted,
(orphan sentences)                    irrelevant text included,
                                      fewer distinct chunks
        ▲ sweet spot: a coherent, self-contained idea ▲
```

The goal: each chunk should be a **self-contained unit of meaning** — big enough to stand alone, small enough to stay focused.

---

## 3. Strategies, naive → smart

| Strategy | How | Good for | Weakness |
|---|---|---|---|
| **Fixed-size** | Split every N chars/tokens | Quick baseline | Breaks mid-sentence/word |
| **Recursive character** | Split on paragraph→sentence→word boundaries (§8) | General text | Ignores doc structure |
| **Document-aware** | Split on Markdown headers, code blocks, tables, sections | Structured docs, code, wikis | Needs format-specific logic |
| **Semantic** | Split where embedding similarity between sentences drops (topic shift) | Dense prose | More compute at index time |

> [!TIP]
> **Match the strategy to the document**
> Code → split on functions/classes, never mid-function. Markdown → split on headers and keep the header as metadata. Tables → keep whole rows/tables intact. Chat logs → split on turns. There is no universal chunker; the document's natural structure is the best guide.

---

## 4. The two knobs: size and overlap

### Chunk size
Measured in tokens (or characters). Typical starting range for prose is a few hundred tokens — but it depends on the embedding model's sweet spot and the document. Tune empirically.

### Overlap
Carry a slice of text from the end of one chunk into the start of the next, so context isn't severed at the boundary.

```
chunk A: [.................... sentence X]
chunk B:        [sentence X .................... ]   ← overlap = sentence X
```

> [!IMPORTANT]
> **Overlap prevents boundary amnesia**
> Without overlap, a fact that straddles two chunks ("...the discount applies | only to orders over $50") can be lost from both. A modest overlap (e.g. ~10–20% of chunk size) keeps such facts whole in at least one chunk. Too much overlap, though, wastes storage and creates near-duplicate retrievals.

---

## 5. Keep metadata with the chunk

Each chunk should carry metadata for filtering and context:

```python
{
  "text": "...",
  "metadata": {
    "source": "refund_policy.pdf",
    "section": "Returns",        # e.g. the Markdown header it lived under
    "page": 4,
    "doc_id": "policy_2026",
  }
}
```

Metadata enables **filtered retrieval** ("only search the Returns section") and gives the LLM provenance to cite. It also powers structural patterns in [[06 - Advanced Retrieval Patterns]].

---

## 6. Advanced: decouple the embedded text from the returned text

A powerful idea (expanded in [[06 - Advanced Retrieval Patterns]]):
- **Embed** a small, focused unit (a sentence or a summary) for precise matching,
- but **return** a larger unit (the full paragraph/parent doc) for rich context.

This sidesteps the size tension: small for matching, large for answering.

---

## 7. How to choose / tune

1. Start with **recursive character** splitting (a sensible default).
2. If documents are structured (Markdown/code/HTML), switch to **document-aware**.
3. Measure **Context Recall/Precision** with RAGAS (§17).
4. Adjust **size** and **overlap**; re-measure. Bigger isn't always better.
5. Consider **semantic** chunking if boundaries still cut through ideas.

---

## 8. Main takeaways

- Chunking is **upstream of all RAG quality** — the retriever can only return chunks.
- Tension: too **small** = lost context; too **large** = diluted embedding + noise.
- Each chunk should be a **self-contained idea**.
- Strategies: **fixed-size → recursive → document-aware → semantic**.
- **Match the strategy to the document type** (code, Markdown, tables, chat).
- Two knobs: **chunk size** and **overlap** (overlap prevents boundary amnesia).
- Keep **metadata** (source, section, page) for filtering and citation.
- Advanced: **embed small, return large** (parent-document idea).
- **Tune against RAGAS**, don't guess.

---

## 9. Things I still want to figure out

- Best chunk size per **embedding model** (do they have sweet spots)?
- Does **semantic chunking**'s extra cost pay off vs recursive?
- How to chunk **mixed** documents (text + tables + code) cleanly?

---

## 10. Things to dig into

- LangChain text splitters (recursive, Markdown, code, semantic).
- LlamaIndex node parsers + metadata extractors.
- "Embed small, retrieve large" / parent-document retrieval ([[06 - Advanced Retrieval Patterns]]).

---

## 11. Next up in this section

- [ ] [[03 - Hybrid Search]] — combine vector search with keyword search so exact terms aren't missed.

---

## Related
- [[09 - Smart Chunking with RecursiveCharacterTextSplitter]] — the §8 baseline.
- [[01 - Beyond Naive RAG]] — where chunking sits in the pipeline.
- [[06 - Advanced Retrieval Patterns]] — embed-small/return-large.

## Sources
- [LangChain text splitters](https://python.langchain.com/docs/concepts/text_splitters/)
- [LlamaIndex node parsing](https://docs.llamaindex.ai/)
