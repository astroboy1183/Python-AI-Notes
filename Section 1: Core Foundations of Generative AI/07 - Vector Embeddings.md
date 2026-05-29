---
title: Vector Embeddings
date: 2026-05-28
source: "Section 1 / Lecture 7"
type: lecture-notes
status: in-progress
section: "Section 1: Core Foundations of Generative AI"
tags:
  - llm
  - vector-embeddings
  - embeddings
  - semantic-meaning
  - vector-space
  - tokens
  - tensorflow-projector
  - foundations
  - cosine-similarity
  - rag
related:
  - "[[01 - What is an LLM]]"
  - "[[04 - What is a Token]]"
  - "[[06 - Attention Is All You Need - Architecture Walkthrough]]"
---

# Vector Embeddings

> [!NOTE]
> **TL;DR**
> A **vector embedding** is a list of numbers that represents the **semantic meaning** of a token (or word, sentence, document). After tokenization turns `"dog"` into a number like `1729`, the embedding layer turns `1729` into a **high-dimensional vector** (e.g., 768 or 1536 numbers). The crucial property: **semantically similar things end up close together in that high-dimensional space.** `dog` and `cat` sit near each other (both animals). `Paris` and `India` sit near each other (both countries). And — most surprisingly — **directions** in the space encode **relationships**: the vector from `Paris` to `Eiffel Tower` is parallel to the vector from `India` to `India Gate`. This geometric structure is what lets the transformer "understand" meaning rather than just shuffle symbols.

> [!NOTE]
> **Where this fits**
> Seventh note of **Section 1: Core Foundations of Generative AI**. From the architecture walkthrough in [[06 - Attention Is All You Need - Architecture Walkthrough]], this is the **input embeddings** box at the very start of the transformer. Tokens (numbers) become **vectors** (lists of numbers) here — vectors that carry meaning. Vector embeddings are also the foundation of **RAG** (retrieval-augmented generation), which the course covers later — so this is one of the most reusable concepts in the curriculum.

---

## 1. The problem embeddings solve

Reading these characters triggers mental images automatically:

| Text | Mental image |
|---|---|
| `dog` | a dog |
| `cat` | a cat |
| `mobile` | a phone |
| `Paris` | the city / Eiffel Tower |
| `India` | India Gate, Taj Mahal |
| `Eiffel Tower` | the structure |

But to a computer, these are just **strings of characters** — jumbled alphabets. How does a machine know that `dog` and `cat` are related concepts? How does it know `Paris` and `Eiffel Tower` are linked?

At the end of the day these are all just English characters, just jumbled alphabets — but somehow they carry real meaning that's easy to imagine. How does a program convey the meaning of a word to a machine?

That's the central problem. The answer is **vector embeddings**.

---

## 2. The core idea

> **An embedding maps each token (and word, sentence, doc) to a list of numbers, such that semantically related things get nearby numbers.**

In other words, embeddings convert meaning into **geometry**. Things that *feel* similar end up *spatially* close.

```
                          high-dimensional space
                                  │
                                  │   • Paris
                                  │     • Eiffel Tower
                                  │
                                  │
                                  │   • India
                                  │     • India Gate
                                  │
                                  │
                                  │     • dog
                                  │       • cat
                                  │
```

(In reality, 2D doesn't have nearly enough room — real embeddings live in **hundreds or thousands of dimensions**.)

---

## 3. Visualizing in 2D

A 2D graph builds the intuition. Real embeddings are 3D or much higher, but 2D is enough for the mental model.

Plotting some words on a 2D plane:

```
        Y axis
          │
          │
          │              • India
          │
          │          • Paris
          │
          │
          │                   • Eiffel Tower    • India Gate
          │
          │     • dog
          │       • cat
          │
          └──────────────────────────────────────────── X axis
```

What's interesting:

| Cluster | Why they're near each other |
|---|---|
| `dog`, `cat` | Both animals |
| `Paris`, `India` | Both countries (geographic / political entities) |
| `Eiffel Tower`, `India Gate` | Both tourist monuments |

The position itself encodes meaning. The model doesn't need to be told "dogs and cats are similar" — it learns the placement during pre-training.

---

## 4. The really mind-blowing part — directions encode relationships

The most important insight: **vectors between concepts are also meaningful**.

```
        Y axis
          │
          │
          │              • India ─────────────────
          │             ╱  ▲                      ╲
          │            ╱   │                       ╲
          │          ╱     │ (same direction        │
          │        ╱       │  to capital city)      │
          │      ╱         │                         │
          │    Paris ──────│──────────── Eiffel ────│
          │                │                  Tower │
          │                                          │
          │                ────────────── India ─────
          │                                  Gate
          │
          └─────────────────────────────────── X axis
```

Specifically:

| Operation | Result |
|---|---|
| `India` − `Paris` | Some direction in space ("the country-to-country" axis). |
| `Eiffel Tower` − `Paris` | Some direction ("city → its famous monument"). |
| `Paris` + (Eiffel Tower − Paris)  ≈  `Eiffel Tower` | Tautology, but illustrates that arithmetic works on meaning. |
| `India` + (Eiffel Tower − Paris)  ≈  `India Gate` | **Surprising**: moving from `India` in the same "city-to-monument" direction lands at `India Gate`. |

Same trick works for "president of": vector from `Paris` to `President of France` is parallel to vector from `India` to `President of India`.

> [!TIP]
> **The classic embedding analogy**
> The famous Word2Vec result that made embeddings famous:
> ```
> vector("king") − vector("man") + vector("woman") ≈ vector("queen")
> ```
> Embeddings learn relationships like **gender**, **plurality**, **tense**, **capital-of**, **part-of** — and these end up as **consistent directions** in the vector space.

---

## 5. The technical definition

> Vector embeddings are numerical representations of data points — including text, images, and other types — that capture their meaning and relationships.

Breaking that down:

| Word | What it means |
|---|---|
| **Numerical** | Just lists of floats (e.g., `[0.21, -0.45, 0.78, ...]`). |
| **Representation** | A surrogate for the original data the model can compute on. |
| **Of data points** | Originally for words/tokens, but also extends to whole sentences, paragraphs, images, audio, video. |
| **Capture meaning** | Similar things → similar vectors. |
| **And relationships** | Directions in space encode systematic relationships. |

Embeddings are **not** human-designed. They're **learned** during the model's pre-training, by adjusting the vectors so that the model gets better at predicting the next token.

---

## 6. How embeddings are produced

Two perspectives:

### Inside an LLM (in-context embeddings)
- The transformer's first layer is an **embedding lookup table**: token ID → vector.
- Vocab size × embedding dimension matrix (e.g., 200,000 × 1,536 for GPT-4o).
- During training, every entry in that table gets nudged to be more useful for prediction.
- Later layers (attention + feed-forward) **transform** these embeddings further based on context.

### As a standalone product (embedding APIs)
For tasks like RAG, semantic search, clustering:
- OpenAI's `text-embedding-3-large` → outputs ~3,072-dimensional vectors per chunk of text.
- Cohere, Voyage, Google all have similar embedding endpoints.
- These are **specifically trained** to produce useful similarity scores, not just for next-token prediction.

> [!NOTE]
> **Embedding model dimensions**
> Common embedding sizes:
>
> | Model | Embedding dim |
> |---|---|
> | `text-embedding-3-small` (OpenAI) | 1,536 |
> | `text-embedding-3-large` (OpenAI) | 3,072 |
> | `voyage-large-2` (Voyage AI) | 1,536 |
> | `bge-large-en-v1.5` (open source) | 1,024 |
> | Original Word2Vec | 300 |
>
> Higher dimensions can capture finer distinctions but cost more storage + compute for similarity search.

---

## 7. Reality check — it's not 2D, it's hundreds-to-thousands-D

The 2D picture is a teaching aid. Real embedding spaces are:

| Source | Dimensions |
|---|---|
| Original Word2Vec (2013) | 100–300 |
| GPT-2 | 768 |
| GPT-3 | 12,288 |
| OpenAI `text-embedding-3-large` | 3,072 |
| Modern LLM internal embeddings | 1,024 – 16,384+ |

Why so many? More dimensions = more capacity to encode fine distinctions (gender, plurality, formality, language, topic, sentiment, ...).

> [!NOTE]
> In a 2D plot, you can only show one tiny slice of the structure. The TensorFlow Embedding Projector (next section) lets us *visualize* high-dimensional embeddings by projecting them down to 3D — but the real action is in the original high dimensions.

---

## 8. The TensorFlow Embedding Projector

A great hands-on visualizer:

- URL: https://projector.tensorflow.org
- Live, interactive visualization of real word embeddings.
- Each point = a word; spatial position = (projection of) its embedding.
- Hover to see what word each point represents.
- Search for a word and find its nearest neighbors.

> [!TIP]
> Spending 5 minutes clicking around the embedding projector builds more intuition about embeddings than reading any blog post. The clustering of synonyms, antonyms, related concepts is genuinely revelatory.

---

## 9. Why embeddings matter beyond the transformer

Embeddings show up in many places later in the course:

| Use case | How embeddings power it |
|---|---|
| **Semantic search** | Embed query + documents; find docs whose embeddings are most similar. |
| **RAG (Section 8-9)** | Embed user query + knowledge-base chunks; retrieve top-K relevant chunks. |
| **Episodic memory (Section 13)** | Embed past episodes; recall ones similar to the current query. |
| **Recommendation systems** | Embed users + items; recommend items with similar embeddings. |
| **Clustering / topic discovery** | Group documents whose embeddings cluster together. |
| **Anomaly detection** | Embed inputs; flag outliers far from the typical cluster. |

> [!NOTE]
> **Cross-link**
> Vector embeddings are what makes **episodic memory** work in agents — see [[04 - Episodic Memory in LLMs]] for how the same idea gets applied to "find similar past interactions."

---

## 10. Similarity math

How is "closeness" actually measured in embedding space? Two common metrics:

### Cosine similarity (most common for text)
- Measures the **angle** between two vectors.
- Range: -1 (opposite) to +1 (identical direction).
- Magnitude is ignored — only direction matters.

```python
import numpy as np

def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))
```

### Euclidean (L2) distance
- Straight-line distance in space.
- Smaller = more similar.
- Magnitude-aware.

For text embeddings, **cosine similarity is the default**. Vector databases like Qdrant, Pinecone, Weaviate let you choose, but cosine is the typical pick.

---

## 11. Mental model after this note

The transformer pipeline now expands:

```
"hey there"
   │
   ▼
Tokenize → [25216, 1354]
   │
   ▼
EMBED each token → [vec₁, vec₂]    ← THIS NOTE
   (each vec_i is, e.g., 1536 floats
    carrying semantic meaning)
   │
   ▼
+ Positional encoding              ← NEXT NOTE
   │
   ▼
Attention (vectors interact)       ← NOTE AFTER NEXT
   │
   ▼
... → predicted next token
```

The model has gone from "thinking in token IDs" to "thinking in meaningful vectors". Everything downstream operates on those vectors.

---

## 12. Main takeaways

- A **vector embedding** = a list of floats representing the **semantic meaning** of a token.
- Embeddings turn meaning into **geometry**: similar concepts → nearby vectors.
- The first layer of any transformer is an **embedding lookup**: token ID → vector.
- Real embeddings live in **hundreds to thousands of dimensions** (2D plots are just for intuition).
- **Directions** in embedding space encode **relationships** — `king − man + woman ≈ queen` is the classic example.
- Embeddings are **learned during training**, not hand-designed.
- Same idea powers RAG, semantic search, episodic memory, recommendations, clustering.
- **Cosine similarity** is the standard way to measure "closeness" in embedding space.
- TensorFlow's **Embedding Projector** is great for getting intuition by playing.

---

## 13. Things I still want to figure out

- How are embeddings actually *trained* — what loss function shapes the geometry?
- Are token embeddings the same as sentence/document embeddings? (No — sentence embeddings often come from different training objectives.)
- What's the relationship between **input embeddings** (one of two boxes in the transformer diagram) and **output embeddings**? Are they tied?
- How do **multilingual** embeddings work — do French and English `cat` map to the same vector?
- What's "dimension collapse" and why is it a problem?
- For RAG, what's the right embedding model to pick — small/large, multilingual or not?
- How does **fine-tuning an embedding model** for a specific domain work?

---

## 14. Things to dig into

- **Play with**: https://projector.tensorflow.org — the embedding projector.
- **Classic paper**: Mikolov et al., *Efficient Estimation of Word Representations in Vector Space* (2013) — the Word2Vec paper.
- **Modern paper**: BAAI's BGE, OpenAI's `text-embedding-3` technical report.
- **Intuition**: 3Blue1Brown's video *"But what is a GPT?"* has a great visual explanation of embeddings as semantic geometry.
- **Practical exercise**: use `openai.embeddings.create(...)` to embed five sentences and compute cosine similarities between them. Confirm that semantically similar pairs score higher.

---

## 15. Next up in this section

The next note answers: now that each token is a vector, how does the model know **which position** in the sentence each token came from?

- [ ] [[08 - Positional Encoding]] — preserving sentence order in vector form.

After that:

- [ ] [[09 - Multi-Head Attention]] — how tokens "talk to" each other.

---

## Related
- [[04 - What is a Token]] — what feeds into the embedding layer.
- [[06 - Attention Is All You Need - Architecture Walkthrough]] — the "input embeddings" box this note deep-dives.
- [[04 - Episodic Memory in LLMs]] — uses embeddings for similarity-based retrieval.

## Sources
- Mikolov et al., *Efficient Estimation of Word Representations in Vector Space* (2013) — the Word2Vec paper.
- TensorFlow Embedding Projector — https://projector.tensorflow.org
- 3Blue1Brown, *But what is a GPT?*
- BAAI's BGE and OpenAI's `text-embedding-3` technical reports.
