---
title: What is RAG and the Naive Approach
date: 2026-05-28
source: "Section 8 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 8: Building Chat with PDF Project using RAG (Retrieval-Augmented Generation)"
tags:
  - rag
  - retrieval-augmented-generation
  - naive-rag
  - context-window
  - system-prompt
  - foundations
related:
  - "[[02 - The Problem RAG Solves]]"
  - "[[04 - The Indexing Phase]]"
  - "[[02 - What is Prompting]]"
---

# What is RAG and the Naive Approach

> [!NOTE]
> **TL;DR**
> **RAG = Retrieval-Augmented Generation** — an AI architecture that *augments* an LLM with **external knowledge sources** the model wasn't trained on. The "augmentation" part is **retrieval**: pull only the most relevant pieces from a large corpus, then *generate* a reply using those pieces as context. The naive version (covered here): **dump everything into the system prompt**. It works for a single small PDF, but breaks immediately at scale because of context-window limits and token cost. The naive approach is still a useful baseline to understand — it makes clear *exactly which* engineering improvements the proper two-phase architecture introduces.

> [!NOTE]
> **Where this fits**
> Third lecture of **Section 8: Building Chat with PDF Project using RAG**. The naive approach is a stepping stone — the next notes replace each of its shortcomings with proper indexing ([[04 - The Indexing Phase]]) and retrieval ([[05 - The Retrieval Phase]]) phases.

---

## 1. The definition

> **RAG = Retrieval-Augmented Generation**

| Word | Meaning |
|---|---|
| **Retrieval** | Find relevant chunks from an external knowledge source |
| **Augmented** | *Augment* the LLM's pre-training with that retrieved info |
| **Generation** | The LLM generates an answer using both its training + the retrieved info |

Formal description:

> *RAG is an AI framework that combines the strengths of large language models with external knowledge sources.*

The key phrase is **"external knowledge sources"** — the data the LLM didn't see during training, that gets brought in at inference time.

---

## 2. Where RAG sits in the spectrum

The space of "how to give an LLM external knowledge":

| Approach | What it does | When to use |
|---|---|---|
| **Pre-training** | Train the model from scratch on your corpus | Almost never (too expensive) |
| **Fine-tuning** | Continue training on your corpus | When you have lots of data and need style/format adoption |
| **Long-context cram** | Put all data in the system prompt every call | Tiny corpora (single doc, maybe 10 pages) |
| **RAG** | Index data → retrieve relevant chunks per query | Standard answer for ~all enterprise cases |
| **Tool use + RAG** | Agent decides when to retrieve, what to retrieve | Multi-source / multi-step queries |

RAG is the **default modern approach** for ~99% of "give the LLM access to my data" problems.

---

## 3. The naive approach — stuff everything into the system prompt

The most direct interpretation of "give the LLM your data":

```python
# Read every file's content into one giant string
all_data = ""
for file in all_pdf_files:
    all_data += extract_text(file)

system_prompt = f"""
You are a smart AI assistant that can help users talk to their data.

Available data:
{all_data}

Answer the user's questions using only the above data.
"""

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": user_query},
    ],
)
```

That's it. A few lines. Works as a **proof of concept** — for tiny datasets. The naive approach is the simplest system you can build. Will it work? Yes — but it's worth understanding exactly what breaks it.

---

## 4. Why the naive approach is still RAG

Strictly speaking, the naive system **is** a RAG system. It's a particularly inefficient one:

| RAG component | Naive approach equivalent |
|---|---|
| Retrieve relevant chunks | Retrieve **all** chunks |
| Augment the LLM | Stuff everything into system prompt |
| Generate a reply | Same as proper RAG |

The "retrieval" step is just **degenerate** — it retrieves the entire corpus every time. Everything else is the same.

> [!TIP]
> **Mental framing**
> Proper RAG is the naive approach **with a smarter retrieval step**. That's it. The rest of the engineering (vector DBs, embeddings, chunking) is all in service of "retrieve only what's relevant."

---

## 5. Where the naive approach fits

| Use case | Naive RAG OK? |
|---|---|
| Chat with one ~5-page document | ✅ Yes |
| Chat with one ~50-page document | ✅ Probably yes (modern context windows handle it) |
| Chat with one ~200-page book | ⚠️ Borderline — depends on the model |
| Chat with 10 documents | ❌ Use proper RAG |
| Chat with 1,000+ documents | ❌ Definitely use proper RAG |

For prototyping, single-document Q&A, or quick demos: naive approach is **completely fine**. It's only at scale that the proper architecture pays off.

---

## 6. Why the naive approach breaks at scale

Three reasons, deepening what [[02 - The Problem RAG Solves]] introduced:

### Problem 1 — Context window
Even Gemini's 1M-token window is dwarfed by enterprise corpora. With 50,000 files averaging 10 pages each, the corpus is ~500M tokens. Doesn't fit. Period.

### Problem 2 — Cost
Every query sends the **entire corpus** as input tokens:

```
500M input tokens × $2.50/M tokens = $1,250 per query
```

Multiply by daily traffic — it's economically broken before it's technically broken.

### Problem 3 — Signal-to-noise / "lost in the middle"
LLMs perform worse with very long contexts:
- **Lost-in-the-middle** effect (Liu et al., 2023): info at the start or end of a long context is recalled well; info in the middle gets lost.
- Irrelevant material **distracts** the model — it may incorporate noise into the answer.
- Total quality degrades as context length increases past a few thousand tokens.

> [!WARNING]
> **Even when the data fits, the answer often gets worse**
> Adding more context isn't automatically better. Past a few thousand tokens of context, accuracy on specific queries usually **decreases** — the model is overwhelmed.

---

## 7. The fix preview — two phases

The proper RAG architecture solves all three problems by splitting into:

| Phase | When it runs | What it does |
|---|---|---|
| **Indexing** | Once, offline, in bulk | Pre-process the corpus into a searchable form (vector DB) |
| **Retrieval** | Every user query | Look up only the relevant chunks |

```
┌────────────────────────────────────────────────────────────┐
│  PHASE 1 — INDEXING (offline, batch)                       │
│                                                            │
│  PDFs → chunks → embeddings → vector database              │
└────────────────────────────────────────────────────────────┘

                            ↓  (data ready for queries)

┌────────────────────────────────────────────────────────────┐
│  PHASE 2 — RETRIEVAL (online, per query)                   │
│                                                            │
│  User query → embedding → similarity search → top-K chunks │
│                                                       │     │
│                                                       ▼     │
│  System prompt with only those chunks → LLM → answer       │
└────────────────────────────────────────────────────────────┘
```

The split is what makes RAG scalable:
- **Cost**: only relevant chunks sent per query (maybe 2 KB instead of 500 MB).
- **Context**: tiny prompt fits easily in any model.
- **Quality**: high signal, low noise.

---

## 8. What gets stored, what gets retrieved

The indexing phase pre-computes:

| Per chunk | Stored value |
|---|---|
| Original text | The raw text of this chunk |
| Vector embedding | A 1,536-dimensional (or similar) vector |
| Metadata | Source document, page number, chunk index, etc. |

The retrieval phase reads:

| Per query | Fetched value |
|---|---|
| User's query | (provided) |
| Query embedding | Computed at query time |
| Top-K similar chunks | Returned by the vector DB |
| Those chunks' original text | Included in the LLM prompt |
| Those chunks' metadata | Used for citations |

The next two notes unpack each phase.

---

## 9. Common confusions

> [!WARNING]
> **Things that confuse people about RAG**

| Misconception | Reality |
|---|---|
| RAG = some specific library | RAG is an **architecture**, not a tool. Built with LangChain, LlamaIndex, or just plain code. |
| RAG = fine-tuning | They're different. RAG injects context at query time; fine-tuning bakes knowledge into model weights. |
| Vector DBs are special | Conceptually they're just key-value stores with similarity search. |
| Bigger chunks = better | Often worse — irrelevant chunks crowd out relevant ones. |
| Embeddings always retrieve correctly | They're approximate. Retrieval can miss things. Hybrid search (vector + keyword) helps. |
| RAG eliminates hallucinations | Reduces but doesn't eliminate. LLMs can still ignore the context. |

---

## 10. The naive approach as a baseline

Before going further, the naive approach is worth running once as a baseline. The exercise:
1. Take a single ~100-page PDF.
2. Extract its text.
3. Dump into a system prompt.
4. Ask a few questions.

What's observable:
- ✅ Works for the first few queries.
- ⚠️ Each query costs noticeably more than vanilla ChatGPT.
- ⚠️ Latency creeps up.
- ⚠️ As the PDF gets bigger, quality starts degrading.

That hands-on observation is what motivates the engineering effort in the proper RAG approach. The rest of the section builds it.

---

## 11. Main takeaways

- **RAG = Retrieval-Augmented Generation** — LLM + external knowledge, fetched per query.
- The **naive RAG** stuffs the entire corpus into the system prompt.
- Naive RAG works for **tiny** corpora (one short doc) but **fails at scale**: context window, cost, lost-in-the-middle.
- Strictly speaking, naive RAG **is** RAG — it just has a degenerate retrieval step ("retrieve everything").
- Proper RAG splits into **two phases**: indexing (offline) + retrieval (per query).
- The indexing phase builds a **vector database** of pre-embedded chunks.
- The retrieval phase **finds only relevant** chunks via vector similarity.
- The architecture stays correct even as context windows grow — it's not a stopgap.

---

## 12. Things I still want to figure out

- For **medium** corpora (~10 docs), is the naive approach actually fine?
- How does **prompt caching** (OpenAI's newer feature) change the math?
- For long-context models, what's the **break-even** point where vector RAG becomes necessary?
- How is the **lost-in-the-middle** effect quantified in benchmarks?
- For hybrid (RAG + cram) approaches, is there a sweet spot?

---

## 13. Things to dig into

- **The RAG paper**: Lewis et al., 2020 — https://arxiv.org/abs/2005.11401
- **Long-context vs RAG comparison**: Anthropic / Google have published benchmarks.
- **Prompt caching docs**: https://platform.openai.com/docs/guides/prompt-caching
- **Hands-on**: implement naive RAG with one PDF. Use `pypdf` to extract text → dump into system prompt → ask questions. Notice when it breaks.

---

## 14. Next up in this section

- [ ] [[04 - The Indexing Phase]] — the offline-batch side of proper RAG.
- [ ] [[05 - The Retrieval Phase]] — the online per-query side.

---

## Related
- [[02 - The Problem RAG Solves]] — the constraints this note's solutions address.
- [[02 - What is Prompting]] — naive RAG abuses the system prompt.
- [[01 - Section Intro - RAG]] — section overview.

## Sources
- Lewis et al., *Retrieval-Augmented Generation for Knowledge-Intensive NLP Tasks* (2020) — https://arxiv.org/abs/2005.11401
- Liu et al., *Lost in the Middle: How Language Models Use Long Contexts* (2023) — https://arxiv.org/abs/2307.03172
- OpenAI Prompt Caching docs — https://platform.openai.com/docs/guides/prompt-caching
