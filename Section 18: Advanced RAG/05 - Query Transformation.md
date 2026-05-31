---
title: Query Transformation
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 18: Advanced RAG"
tags:
  - rag
  - query-transformation
  - hyde
  - retrieval
related:
  - "[[04 - Reranking]]"
  - "[[06 - Advanced Retrieval Patterns]]"
---

# Query Transformation

> [!NOTE]
> **TL;DR**
> Naive RAG embeds the user's **raw query**, but raw queries are often bad for retrieval — vague, conversational, multi-part, or full of pronouns ("what about *its* pricing?"). **Query transformation** is the pre-retrieval stage that rewrites the query into something the retriever handles better. Key techniques: **query rewriting** (clean it up, resolve context from chat history), **multi-query** (generate several phrasings, retrieve for each, merge), **decomposition** (split a complex question into sub-questions, retrieve each), **step-back prompting** (ask a broader question first to get foundational context), and **HyDE** (Hypothetical Document Embeddings — have the LLM *write a fake answer* and embed *that*, since a hypothetical answer is closer in embedding space to real answers than the question is). All trade extra LLM calls (latency/cost) for much better recall on hard queries.

> [!NOTE]
> **Where this fits**
> Fifth note of **Section 18** — the pre-retrieval stage. It complements post-retrieval [[04 - Reranking]]: fix the query going in, refine the results coming out.

---

## 1. The problem: raw queries retrieve badly

```
user: "and what about its return window?"
```

Embed that literally and retrieval flails — "its" is unresolved, there are no content words, and it's conversational. The query needs **transformation** before it touches the retriever.

Common bad-query shapes:
- **Vague / underspecified** ("tell me about pricing")
- **Conversational** (pronouns, references to earlier turns)
- **Multi-part** ("compare A and B and tell me which is cheaper")
- **Mismatched vocabulary** (user words ≠ document words)

---

## 2. Query rewriting

Use an LLM to rewrite the raw query into a clean, standalone, retrieval-friendly form — crucially **resolving conversational context**.

```
history: "Tell me about the Pro plan." → "$20/mo..."
follow-up: "and its return window?"
rewritten: "What is the return/refund window for the Pro plan?"
```

This single technique fixes most **multi-turn RAG** failures, where each turn must become a self-contained query.

---

## 3. Multi-query (query expansion)

Generate **several** phrasings of the question, retrieve for each, then **merge/dedupe** the results.

```
"how do I cancel?" ─► LLM ─► [ "how to cancel subscription",
                               "ending my plan",
                               "stop recurring billing" ]
   → retrieve each → union of chunks → (rerank) → answer
```

Casts a wider net across vocabulary mismatches — raises **recall**. Fuse the multiple result lists (RRF-style, as in [[03 - Hybrid Search]]).

---

## 4. Decomposition (sub-questions)

Break a complex/multi-hop question into atomic sub-questions, retrieve for each, then synthesize.

```
"Which plan is cheaper and does it include support?"
   ├─ sub: "price of each plan?"        → retrieve
   └─ sub: "which plans include support?" → retrieve
   → combine contexts → answer the compound question
```

Essential for questions no single chunk can answer (multi-hop). Overlaps with **agentic RAG** ([[06 - Advanced Retrieval Patterns]]).

---

## 5. Step-back prompting

Ask a **broader, more general** question first to retrieve foundational context, then answer the specific one.

```
specific: "Does the 2026 Pro plan support SSO on the free trial?"
step-back: "What features does the Pro plan include?"
   → retrieve general context → then answer the specific question grounded in it
```

Helps when the specific query is too narrow to match well, but the general topic retrieves cleanly.

---

## 6. HyDE — Hypothetical Document Embeddings

A clever trick: the **question** and the **answer** live in different regions of embedding space, so matching a question against answer-like chunks is imperfect. HyDE fixes this:

```
1. Ask the LLM to write a HYPOTHETICAL answer to the question (may be partly wrong).
2. Embed that hypothetical answer (not the question).
3. Search with that embedding.
```

> [!IMPORTANT]
> **Why HyDE works**
> A fake answer "looks like" the real documents (same style, vocabulary, structure), so its embedding lands near the genuinely relevant chunks — closer than the question's embedding would. The hypothetical answer doesn't need to be correct; it only needs to be **shaped like** the target documents. Trade-off: an extra generation call, and it can drift if the LLM hallucinates an off-topic answer.

---

## 7. The trade-off

```
better recall on hard queries  ⇄  extra LLM call(s) = more latency + cost
```

| Technique | Extra calls | Best for |
|---|---|---|
| Rewriting | 1 | conversational / multi-turn |
| Multi-query | 1 (+N retrievals) | vocabulary mismatch |
| Decomposition | 1 (+N) | multi-hop / compound questions |
| Step-back | 1 | overly specific queries |
| HyDE | 1 | question/answer embedding gap |

> [!TIP]
> **Don't transform every query**
> These add latency. Apply selectively — e.g. only rewrite when there's chat history, only decompose when a query is detected as compound. A lightweight router (or the agent itself) can decide. Measure the recall gain against the latency cost (§17/§20).

---

## 8. Main takeaways

- Naive RAG embeds the **raw query**, which is often vague/conversational/multi-part.
- **Query transformation** fixes the query **before** retrieval.
- **Rewriting**: clean + resolve context (fixes multi-turn RAG).
- **Multi-query**: several phrasings → merge → higher recall.
- **Decomposition**: split compound/multi-hop questions into sub-questions.
- **Step-back**: ask broader first for foundational context.
- **HyDE**: embed a *hypothetical answer*, not the question (closer to real docs).
- All trade **extra LLM calls** for recall — apply **selectively**.

---

## 9. Things I still want to figure out

- How to **detect** which transformation a given query needs (routing)?
- Does HyDE help more than multi-query in practice, per domain?
- How to keep total **latency** sane when stacking transformations?

---

## 10. Things to dig into

- **HyDE** paper ("Precise Zero-Shot Dense Retrieval without Relevance Labels").
- LangChain `MultiQueryRetriever`, query-rewriting chains.
- **Step-back prompting** paper.
- Next: [[06 - Advanced Retrieval Patterns]].

---

## 11. Next up in this section

- [ ] [[06 - Advanced Retrieval Patterns]] — structural patterns (parent-document, contextual) and agentic RAG.

---

## Related
- [[04 - Reranking]] — the post-retrieval counterpart.
- [[06 - Advanced Retrieval Patterns]] — decomposition leads into agentic RAG.

## Sources
- [HyDE paper](https://arxiv.org/abs/2212.10496)
- [LangChain query transformation](https://python.langchain.com/docs/how_to/#query-analysis)
