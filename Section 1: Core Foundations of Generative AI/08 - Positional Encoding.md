---
title: Positional Encoding
date: 2026-05-28
source: "Section 1 / Lecture 8"
type: lecture-notes
status: in-progress
section: "Section 1: Core Foundations of Generative AI"
tags:
  - llm
  - positional-encoding
  - transformer
  - vector-embeddings
  - tokens
  - foundations
  - sinusoidal-encoding
  - rope
  - attention
related:
  - "[[01 - What is an LLM]]"
  - "[[06 - Attention Is All You Need - Architecture Walkthrough]]"
  - "[[07 - Vector Embeddings]]"
---

# Positional Encoding

> [!abstract] TL;DR
> **Vector embeddings alone don't know word order.** `"dog ate cat"` and `"cat ate dog"` use exactly the same tokens — same embeddings — but mean opposite things. Without sequence-position information, a transformer would treat both sentences identically. **Positional encoding** fixes this by adding a per-position signal to each token's embedding: each token's final vector = (its semantic embedding) + (a vector that encodes "I am position N in the sequence"). After this step, "dog at position 0, ate at position 1, cat at position 2" is materially different from "cat at position 0, ate at position 1, dog at position 2" — even though the tokens are the same. Attention layers downstream can now use both **what** the token means *and* **where** it sits.

> [!info] Where this fits
> Eighth note of **Section 1: Core Foundations of Generative AI**. From the architecture diagram in [[06 - Attention Is All You Need - Architecture Walkthrough]], this is the **positional encoding** box that sits right after [[07 - Vector Embeddings]]. Together, embeddings + positional encoding produce the **final input representation** that attention layers operate on.

---

## 1. The problem positional encoding solves

Vector embeddings are powerful (each token → a meaningful vector), but they have **one big gap**:

> **An embedding is the same wherever the token appears in the sentence.**

The embedding for `dog` is identical whether `dog` is the first, fifth, or last word of a sentence. So how can the model tell apart sentences whose meaning depends on **word order**?

### A clear example

| Sentence | Meaning |
|---|---|
| `dog ate cat` | The dog eats the cat. |
| `cat ate dog` | The cat eats the dog. |

Same three tokens (`dog`, `ate`, `cat`). Same embeddings. **But entirely opposite meanings.**

Without positional information, the attention mechanism can't tell them apart — it would treat both sentences as a "bag of words" containing `{dog, ate, cat}`.

> [!warning] Why this is a real problem
> Transformers process all tokens **in parallel** (unlike older RNNs which processed one at a time). Parallel = fast, but the model loses any natural sense of "first / second / third" position. **Positional encoding is what re-injects that information.**

---

## 2. The fix — add a position signal to each embedding

The trick: for each position in the sequence (0, 1, 2, …), generate a **fixed vector** that uniquely identifies that position. Then **add** that position vector to the token's semantic embedding.

```
                  Final vector that the
                  transformer actually
                  processes for token N:

        ┌──────────────────────────────┐
        │  embedding(token at pos N)   │
        │              +               │
        │  positional_encoding(pos N)  │
        └──────────────────────────────┘
```

Two different embeddings end up at the same position → they're still distinguishable by their token meaning. Two identical tokens at different positions → they're now distinguishable by their position contribution. Order is preserved.

---

## 3. Walkthrough — "dog ate cat"

Step-by-step through the input pipeline:

### Step 1 — Tokenization

The string `dog ate cat` becomes token IDs:

| Token | ID (illustrative) |
|---|---|
| `dog` | 56 |
| `ate` | 74 |
| `cat` | 89 |

### Step 2 — Vector embeddings (from [[07 - Vector Embeddings]])

Each token ID gets converted to a vector via the embedding lookup:

| Token | ID | Embedding (a list of floats — illustrative) |
|---|---|---|
| `dog` | 56 | `[0.21, -0.45, 0.78, …]` |
| `ate` | 74 | `[0.11, 0.55, -0.32, …]` |
| `cat` | 89 | `[0.30, -0.40, 0.65, …]` |

So far, no order info present in the vectors.

### Step 3 — Positional encoding

For each position (0, 1, 2), generate a position-specific vector and **add** it:

| Position | Token | Embedding (E) | Positional encoding (P) | Final vector (E + P) |
|---|---|---|---|---|
| 0 | `dog` | `[0.21, -0.45, 0.78, …]` | `[0.00, 1.00, 0.00, …]` | `[0.21, 0.55, 0.78, …]` |
| 1 | `ate` | `[0.11, 0.55, -0.32, …]` | `[0.84, 0.54, 0.00, …]` | `[0.95, 1.09, -0.32, …]` |
| 2 | `cat` | `[0.30, -0.40, 0.65, …]` | `[0.91, -0.42, 0.00, …]` | `[1.21, -0.82, 0.65, …]` |

These are now what the attention layers see.

### Contrast — same trick on `cat ate dog`

| Position | Token | Embedding | Positional encoding | Final vector |
|---|---|---|---|---|
| 0 | `cat` | `[0.30, -0.40, 0.65, …]` | `[0.00, 1.00, 0.00, …]` | `[0.30, 0.60, 0.65, …]` |
| 1 | `ate` | `[0.11, 0.55, -0.32, …]` | `[0.84, 0.54, 0.00, …]` | `[0.95, 1.09, -0.32, …]` |
| 2 | `dog` | `[0.21, -0.45, 0.78, …]` | `[0.91, -0.42, 0.00, …]` | `[1.12, -0.87, 0.78, …]` |

> [!tip] The key observation
> `dog`'s vector now looks **different** depending on whether it's at position 0 or position 2 — because different position vectors were added to it. The downstream attention layers will treat the two sentences differently.

---

## 4. How is the position vector computed?

Conceptually it's "add some info about position 0, 1, 2". The actual math from the original paper uses **sinusoidal functions**.

> [!example] Sinusoidal positional encoding (the original paper's formula)
> For position `pos` and dimension index `i` of the embedding (size `d_model`):
>
> ```
> PE(pos, 2i)     = sin( pos / 10000^(2i / d_model) )
> PE(pos, 2i+1)   = cos( pos / 10000^(2i / d_model) )
> ```
>
> Translation:
> - Each dimension oscillates at a **different frequency**.
> - Together, the dimensions form a **unique pattern** for each position.
> - **Smooth** — nearby positions get similar position vectors.
> - **Bounded** — sin/cos values stay in [-1, 1], so positions don't dwarf the semantic content.
> - **Extrapolatable** — the formula works for any position, even ones longer than what the model trained on.
>
> Why sin/cos specifically? They make it possible to compute **relative positions** with simple linear combinations: `PE(pos+k)` is a linear function of `PE(pos)`. This is what lets attention reason about "N steps apart" relationships.

### Modern variants

| Method | Used by | Idea |
|---|---|---|
| **Sinusoidal (original)** | Original Transformer paper | Fixed sin/cos formulas. |
| **Learned positional embeddings** | GPT-2, BERT | Each position has its own learned vector (like token embeddings). Caps the max sequence length. |
| **RoPE (Rotary Position Embedding)** | Llama, Mistral, modern GPT-style | Rotates the query/key vectors by an angle proportional to position. Better at long-context generalization. |
| **ALiBi** | Some open models | Adds a position-dependent bias directly to attention scores, no positional vectors needed. |

Modern frontier models almost all use **RoPE** or a variant. The original sinusoidal scheme is still taught as the conceptual baseline.

---

## 5. Why position encoding is "added," not "concatenated"

A subtle but important design choice: positional encoding is **added** to the embedding (element-wise), not concatenated to it.

- **Adding** keeps the vector dimension unchanged. Attention layers don't have to be bigger.
- The semantic and positional information end up living in the **same vector**, sharing the same dimensions.
- In high-dimensional space (hundreds of dimensions), there's enough "room" for the model to learn to disentangle position from meaning.

> [!note]
> It feels surprising that adding two unrelated signals doesn't destroy either of them — but in practice the model learns to separate them. Modern transformer architectures all do it this way.

---

## 6. Why this matters for the bigger picture

Positional encoding is the bridge between:
- **Tokenization** ([[04 - What is a Token]]) — turning text into discrete IDs.
- **Embeddings** ([[07 - Vector Embeddings]]) — turning IDs into meaningful vectors.
- **Attention** ([[09 - Multi-Head Attention]]) — letting tokens "look at" each other and build context.

Without positional encoding, attention would be an **unordered** operation. Sentences would become bags of words. Word order — which is critical for meaning in most languages — would be lost entirely.

This matters a lot: as the `dog ate cat` vs `cat ate dog` example shows, the entire meaning of a sentence can flip if positional encoding isn't there to keep the order.

---

## 7. Mental model after this note

The transformer input pipeline now looks like:

```
"dog ate cat"
   │
   ▼
[Tokenize]
   │
   ▼
Token IDs:   [56, 74, 89]
   │
   ▼
[Embed]
   │
   ▼
Embeddings:  [vec(dog), vec(ate), vec(cat)]
   │
   ▼
[Positional encoding — ADD position vector]
   │
   ▼
Final input vectors: [
   vec(dog)  + pos(0),
   vec(ate)  + pos(1),
   vec(cat)  + pos(2)
]
   │
   ▼
[Multi-head attention]  ← next note
   │
   ▼
...next-token prediction
```

Every subsequent layer operates on these position-aware vectors.

---

## 8. Main takeaways

- Vector embeddings alone capture **meaning** but **not order**.
- `"dog ate cat"` vs `"cat ate dog"` — same tokens, same embeddings, opposite meanings.
- **Positional encoding** = a vector unique to each position, **added** to the token's embedding.
- Each token's final input vector = `embedding + positional_encoding`.
- Same token at different positions → different final vectors → attention can distinguish.
- Original paper used **sinusoidal** positional encoding (`sin/cos` at varying frequencies).
- Modern models use **RoPE** or **learned positional embeddings**.
- Adding (not concatenating) keeps the vector dimension fixed and lets the model disentangle position from meaning at scale.
- Positional encoding is what makes transformers work on sequences despite processing tokens in **parallel**.

---

## 9. Things I still want to figure out

- Why does adding two different vectors not destroy the information of either? (Answer: high dimensions + learned projections.)
- How does RoPE specifically rotate the query/key vectors? What's the geometric intuition?
- Why is ALiBi (no positional vectors at all, just attention biases) competitive?
- What happens when a sentence is **longer** than the positions the model was trained on?
- Is there a positional encoding for the **first** token at position 0? (Yes — the formula has a valid value there.)
- Do modern multilingual models need different positional encodings per language? (Generally no.)
- How does positional encoding interact with **streaming / infinite-context** setups?

---

## 10. Things to dig into

- **Original formula derivation**: the *Attention Is All You Need* paper, §3.5.
- **RoPE paper**: Su et al., *RoFormer: Enhanced Transformer with Rotary Position Embedding* (2021) — https://arxiv.org/abs/2104.09864
- **ALiBi paper**: Press et al., *Train Short, Test Long: Attention with Linear Biases* (2021) — https://arxiv.org/abs/2108.12409
- **Long-context techniques**: search *"YaRN positional encoding"*, *"NTK-aware scaling"* — how modern long-context LLMs extend positional encodings beyond training length.
- **Visualization**: try plotting sin/cos positional encodings for positions 0–50 across the first few dimensions — the resulting striped pattern is striking.

---

## 11. Next up in this section

Now that each token is both **semantically** and **positionally** encoded, attention layers can do their magic:

- [ ] [[09 - Multi-Head Attention]] — how tokens "talk to" each other to build context-aware representations.

---

## Related
- [[06 - Attention Is All You Need - Architecture Walkthrough]] — the architecture diagram this note deep-dives one box of.
- [[07 - Vector Embeddings]] — the input this note's "position vector" gets added to.
- [[04 - What is a Token]] — where the pipeline starts.

## Sources
- Vaswani et al., *Attention Is All You Need* (2017), §3.5 — https://arxiv.org/abs/1706.03762
- Su et al., *RoFormer: Enhanced Transformer with Rotary Position Embedding* (2021) — https://arxiv.org/abs/2104.09864
- Press et al., *Train Short, Test Long: Attention with Linear Biases* (2021) — https://arxiv.org/abs/2108.12409
