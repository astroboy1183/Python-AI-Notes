---
title: The Problem RAG Solves
date: 2026-05-28
source: "Section 8 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - rag
  - problem-statement
  - private-data
  - context-window
  - enterprise-ai
  - foundations
related:
  - "[[01 - Section Intro - RAG]]"
  - "[[01 - What is an LLM]]"
  - "[[04 - What is a Token]]"
---

# The Problem RAG Solves

> [!NOTE]
> **TL;DR**
> Two intertwined problems agentic AI hits at every enterprise: **(1) LLMs don't know your private data** — they were trained on the public internet, not on your 1,000 internal PDFs / contracts / wiki pages, and **(2) you can't just stuff all your private data into the context window** — even GPT-4o's 128k tokens (≈ 96k English words) is dwarfed by a corpus of 50,000 documents, and even if it weren't, the cost-per-call would be punishing. RAG is the architectural answer: **store the data smartly, retrieve only the relevant fragments at query time, inject into a small context**. This note walks through the problem using a legal-firm example — the next notes introduce the solution.

> [!NOTE]
> **Where this fits**
> Second lecture of **Section 8: Building Chat with PDF Project using RAG**. Sets up the constraints; the rest of the section is the solution.

---

## 1. The scenario — a legal firm

A concrete business case: a **legal firm** that has accumulated thousands of case documents over years:

- Case files (PDFs).
- Contracts.
- Court rulings.
- Client correspondence.

Total: maybe **1,000+ files**, each maybe 10-100 pages.

The business reality:
- Employees can't read everything.
- Looking something up means manually opening files and searching.
- Time-consuming, error-prone, frustrating.

The ask: *"Can you build us an AI that lets employees just **ask** questions about our case files and get answers?"*

The example query: *"Can you tell me about case number 32?"*

---

## 2. Problem 1 — The LLM doesn't know your data

Type that exact question into ChatGPT or Gemini today:

> *"I'm sorry, I don't have information about case number 32 — could you provide more context?"*

The LLM has zero knowledge of:
- The legal firm's internal cases.
- Their client list.
- Their internal numbering convention.
- Anything not in the public internet's training data.

```
┌──────────────────────────────────────────┐
│            LLM (GPT, Gemini, …)          │
│                                          │
│   Knows about: public internet, books,   │
│   Wikipedia, code repos, social media,   │
│   news, papers, … (up to training cutoff)│
│                                          │
│   Doesn't know about: your private data  │
└──────────────────────────────────────────┘
```

This is the **first** fundamental limit — LLMs are pre-trained, frozen, and oblivious to private corpora. They're trained on publicly available internet data, with no context about private data sitting in your files.

---

## 3. Problem 2 — Context windows can't hold everything

The obvious fix: *"Just paste all the documents into the prompt as context!"*

```python
messages = [
    {"role": "system", "content": f"""
        You are a helpful assistant.
        Here is all our private data:
        {file_1_content}
        {file_2_content}
        ...
        {file_1000_content}
    """},
    {"role": "user", "content": "Tell me about case number 32"}
]
```

This works for **tiny** corpora. For real enterprise data, it falls apart for three reasons:

### A. The context window
Even the largest commercial LLMs cap at certain token limits:

| Model | Context window |
|---|---|
| GPT-4o | 128k tokens |
| Claude 3.5 Sonnet | 200k tokens |
| Gemini 1.5 Pro | 1M tokens |
| Average open-source model | 8k - 32k tokens |

A token ≈ 0.75 English words (see [[04 - What is a Token]]). So:

| Corpus size | Approximate tokens |
|---|---|
| 1,000-word essay | ~1,300 |
| 10-page document | ~10,000 |
| 100-page book (this section's PDF) | ~50,000-100,000 |
| 1,000 documents × 10 pages each | ~10,000,000 (10M) |
| 50,000 documents × 10 pages each | ~500,000,000 (500M) |

Even Gemini's 1M-token window fits at most **~10,000 short pages** — and a legal firm with 50,000+ files blows past that easily. Even a 1M-token context can't ingest 50,000 files.

> [!NOTE]
> A "1M context window" is sometimes loosely attributed to GPT-4o — that's actually Gemini 1.5 Pro's spec; GPT-4o is 128k. The point stands either way: even 1M tokens isn't enough for enterprise-scale corpora.

### B. The cost

Token pricing: every input token costs money on every request:

| Model | Input price per 1M tokens |
|---|---|
| GPT-4o | ~$2.50 |
| GPT-4o-mini | ~$0.15 |
| Claude 3.5 Sonnet | ~$3.00 |

If a system prompt always contains 500k tokens of context:
- GPT-4o: **$1.25 per query**.
- A modest 10,000 queries/day → **$12,500/day** in API costs.

Multiply by every employee, every conversation turn, every minor query — it's untenable.

### C. The signal-to-noise ratio

Even if the data fit, **most of it is irrelevant** to any given query. Asking *"Tell me about case number 32"* doesn't need cases 1-31 and 33-1000 in the prompt. They're just noise. Worse: noise actively **degrades** LLM accuracy — the model gets distracted, hallucinates, picks up irrelevant tangents.

> [!WARNING]
> **The relevant 1% problem**
> For any given user query, maybe **1%** of the corpus is relevant. The other 99% is dead weight in the prompt. RAG's whole point is to find that 1% and only send it.

---

## 4. What needs to happen

Putting the two problems together:

| Need | Why |
|---|---|
| **Add private data to LLM responses** | LLM doesn't know it (Problem 1) |
| **Without sending it all every time** | Can't fit in context, too expensive (Problem 2) |
| **Pick only relevant pieces per query** | Reduces cost, reduces noise |
| **Cite where info came from** | Users need to verify, especially for legal/medical use cases |

The architecture that satisfies all four = **RAG**.

---

## 5. The two-phase intuition (preview)

The next note introduces RAG formally. The high-level architecture:

```
┌────────────────────────────────────────────────────────────┐
│  PHASE 1 — INDEXING (done once, offline)                   │
│                                                            │
│  All 1,000+ files                                          │
│       │                                                    │
│       ▼                                                    │
│  Split into chunks                                         │
│       │                                                    │
│       ▼                                                    │
│  Convert each chunk to a vector                            │
│       │                                                    │
│       ▼                                                    │
│  Store in a vector database                                │
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│  PHASE 2 — RETRIEVAL (online, per user query)              │
│                                                            │
│  User: "Tell me about case 32"                             │
│       │                                                    │
│       ▼                                                    │
│  Convert query to a vector                                 │
│       │                                                    │
│       ▼                                                    │
│  Find top-K most similar chunks in vector DB               │
│       │                                                    │
│       ▼                                                    │
│  Send chunks + query to LLM                                │
│       │                                                    │
│       ▼                                                    │
│  Get answer (with citations)                               │
└────────────────────────────────────────────────────────────┘
```

The next note ([[03 - What is RAG and the Naive Approach]]) formalizes the definition. The notes after walk through each box of this diagram.

---

## 6. Why this isn't the LLM's job

Some might argue: *"Surely we'll just keep increasing context windows until the problem goes away?"*

Even if context windows became infinite (they won't, but suppose):

| Issue | Stays a problem |
|---|---|
| **Cost** | Per-token pricing — sending 500M tokens per query is uneconomical |
| **Latency** | Processing 500M tokens takes seconds even at frontier speed |
| **Privacy** | Sending the entire corpus to a third-party LLM every query has compliance implications |
| **Stale data** | What about the document added 5 minutes ago? Re-prompt with the whole corpus? |
| **Noise → accuracy** | The "lost in the middle" effect — LLMs perform worse with very long contexts |

So RAG isn't a stopgap; it's an **architectural choice** that remains correct even as LLMs improve.

---

## 7. Industries where this matters most

The legal-firm example generalizes:

| Industry | Their RAG-relevant data |
|---|---|
| **Legal** | Case files, contracts, statutes, rulings |
| **Healthcare** | Patient records, clinical guidelines, drug interactions |
| **Finance** | Annual reports, internal research, regulations |
| **Customer support** | FAQs, ticket history, product docs |
| **HR** | Employee handbook, benefits, policies |
| **Engineering** | Internal wikis, codebases, design docs |
| **Sales** | Prospect notes, contract templates, pricing |
| **Academia** | Paper libraries, lab notes, thesis archives |

Each is a multi-billion-dollar AI product market. All RAG underneath.

---

## 8. Main takeaways

- **Problem 1**: LLMs don't know private data — they're trained on the public internet only.
- **Problem 2**: You can't just dump all your private data into the context window because of **size limits**, **cost**, and **signal-to-noise**.
- Driving example: a legal firm with 1,000+ PDFs wanting employees to chat with their case files.
- Even Gemini 1.5 Pro's 1M-token window can't hold a real enterprise corpus.
- For any query, only **~1%** of the corpus is relevant — RAG's job is to find that 1%.
- The fix: **two-phase architecture** — index data once into a vector DB, retrieve relevant chunks per query.
- This isn't a stopgap until context windows grow — it's the correct architecture regardless.
- Every major enterprise-AI vertical (legal, healthcare, finance, support, etc.) reduces to this.

---

## 9. Things I still want to figure out

- How does "**lost in the middle**" degrade LLM accuracy at long contexts in practice?
- For privacy-sensitive industries, where does the **vector DB** itself live (cloud? on-prem?)?
- What's the **cost split** typically: embeddings vs storage vs LLM inference?
- How is **document update** handled — re-index everything, or incremental?
- What about **multi-modal** data (PDFs with images, tables)?
- How is **access control** enforced (Alice can search her docs, not Bob's)?

---

## 10. Things to dig into

- **"Lost in the middle" paper**: Liu et al., 2023 — https://arxiv.org/abs/2307.03172 — shows long-context LLMs degrade on info in the middle of the prompt.
- **Real RAG case studies**: search for "Harvey AI" (legal RAG), "Glean" (enterprise search).
- **The original RAG paper**: Lewis et al., 2020 — https://arxiv.org/abs/2005.11401

---

## 11. Next up in this section

- [ ] [[03 - What is RAG and the Naive Approach]] — formal definition + the naive approach (and why it fails).

---

## Related
- [[01 - Section Intro - RAG]] — section overview.
- [[01 - What is an LLM]] — why LLMs are frozen.
- [[04 - What is a Token]] — context windows are measured in tokens.
- [[01 - Short-Term Memory in LLMs]] — different problem, same context-window constraint.

## Sources
- Liu et al., *Lost in the Middle: How Language Models Use Long Contexts* (2023) — https://arxiv.org/abs/2307.03172
- Lewis et al., *Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks* (2020) — https://arxiv.org/abs/2005.11401
