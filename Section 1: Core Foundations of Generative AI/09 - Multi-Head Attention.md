---
title: Multi-Head Attention
date: 2026-05-28
source: "Section 1 / Lecture 9"
type: lecture-notes
status: in-progress
section: "Section 1: Core Foundations of Generative AI"
tags:
  - llm
  - attention
  - self-attention
  - multi-head-attention
  - transformer
  - feed-forward
  - linear
  - softmax
  - foundations
  - query-key-value
  - context
related:
  - "[[01 - What is an LLM]]"
  - "[[06 - Attention Is All You Need - Architecture Walkthrough]]"
  - "[[07 - Vector Embeddings]]"
  - "[[08 - Positional Encoding]]"
---

# Multi-Head Attention

> [!NOTE]
> **TL;DR**
> **Self-attention** lets the token vectors "talk to each other" — every token can look at every other token in the sequence and update its own meaning based on context. That's why `bank` next to `river` ends up with a different vector than `bank` next to `ICICI`. **Multi-head attention** runs several self-attention computations in parallel ("heads"), each focused on a different aspect — like one head tracking grammar, another tracking entity references, another tracking topic. Combining them produces richer context-aware representations. After attention, the data flows through **feed-forward** (a regular neural net), then the **linear** layer produces a vocab-sized score vector, and finally **softmax** turns those scores into a **probability distribution** over the next token. The token with the highest probability is the prediction.

> [!NOTE]
> **Where this fits**
> Ninth and final architecture note of **Section 1: Core Foundations of Generative AI**. This wraps up the transformer walkthrough started in [[06 - Attention Is All You Need - Architecture Walkthrough]]. After this note, the course pivots away from internals to **application development** (APIs, prompts, agents).

> [!WARNING]
> **Still bonus content**
> Like [[06 - Attention Is All You Need - Architecture Walkthrough]], this note is **optional / bonus** for the developer track. Useful for intuition, not required for building agents downstream.

---

## 1. The setup — where attention lives

By now in the pipeline:
- Tokens have been converted to vectors via [[07 - Vector Embeddings|embeddings]].
- Position information has been added via [[08 - Positional Encoding|positional encoding]].

The resulting vectors are **isolated** — each carries semantic + positional info but **no awareness of the surrounding words**. The model needs a mechanism to let tokens **share context** with each other.

That's what attention does.

---

## 2. Self-attention — letting tokens talk to each other

> **Self-attention is the mechanism that lets each token vector look at every other token in the sequence and update itself based on what it sees.**

### A concrete example — the word `bank`

| Phrase | Same word, different meaning |
|---|---|
| `river bank` | Bank = the edge of a river. |
| `ICICI bank` | Bank = a financial institution. |

Both have `bank` in the second position. The embedding for `bank` (from the embedding lookup) is **identical** in both phrases. So is its positional encoding (position 1 in both). Without attention, the model would treat `bank` the same way in both cases.

**Self-attention fixes this.** When `bank` looks at `river`, it shifts its vector toward the "natural geography" region of embedding space. When it looks at `ICICI`, it shifts toward the "finance" region.

```
                          BEFORE attention
                                                AFTER attention

   "river bank"
     │                                            │
     ▼                                            ▼
   river  ────►  river                          river  ────►  river (somewhat shifted)
     │                                            │
     │                                            │
   bank   ────►  bank (generic)                 bank   ────►  bank₁ (river-flavored)


   "ICICI bank"
     │                                            │
     ▼                                            ▼
   ICICI  ────►  ICICI                          ICICI  ────►  ICICI (somewhat shifted)
     │                                            │
     │                                            │
   bank   ────►  bank (generic)                 bank   ────►  bank₂ (finance-flavored)
```

Same input embedding for `bank`. Two different output vectors after attention. **That's the whole game.**

One `bank` is a river bank (geographic), the other is a real bank with a building where money gets deposited (financial). They start with the same embedding at the same position, but their meanings end up completely different — because the self-attention mechanism lets the vectors talk to each other. When `river`'s embedding talks to `bank`, it shifts the meaning of `bank` accordingly.

### How "talking" works (informally)

Each token's vector splits into three roles:

| Role | Job |
|---|---|
| **Query (Q)** | "What am I looking for?" |
| **Key (K)** | "What am I offering?" |
| **Value (V)** | "What information do I carry?" |

For each token, the model:
1. Compares its **Query** with every other token's **Key** → similarity scores.
2. Softmax-normalizes those scores → attention weights (probabilities summing to 1).
3. Uses those weights to do a **weighted sum** of every other token's **Value**.
4. Adds that summed value back to the token's own vector.

The result: every token's vector gets enriched by all the other tokens, weighted by relevance.

> [!NOTE]
> **The actual math**
> For each token `i` with query vector `Q_i`, and the matrices of all queries `Q`, all keys `K`, and all values `V`:
>
> ```
> Attention(Q, K, V) = softmax( (Q · Kᵀ) / √d_k ) · V
> ```
>
> - `Q · Kᵀ` produces a square matrix of similarity scores (every query vs every key).
> - `/√d_k` is a stability trick (prevents huge values → vanishing softmax gradients).
> - `softmax` turns scores into attention weights per row.
> - Multiplying by `V` gives the weighted sum of values.
>
> The whole thing is differentiable, parallelizable, and (importantly) trainable end-to-end.

---

## 3. Multi-head attention — multiple "viewpoints" in parallel

A single self-attention computation captures **one perspective** on the relationships between tokens. But there are many useful perspectives:

- Which tokens are **grammatical subjects/objects**?
- Which tokens **co-reference** each other (he/she/it pointing to someone)?
- Which tokens are **topically related**?
- Which tokens are **syntactically nearby**?

Asking a single attention computation to capture all of this is asking too much. So transformers run **multiple attention heads in parallel** — each with its own learned Q/K/V matrices — and concatenate their outputs.

### The "train" analogy

Watching a train pass by, multiple things register simultaneously:

| Brain "head" | What it focused on |
|---|---|
| Head 1 | "There was a dog who was sleeping." |
| Head 2 | "Oh, it was a Labrador." |
| Head 3 | "He was sleeping very near to the door of the moving train." |
| Head 4 | "How fast was the train moving?" |

In multi-head attention, the same kind of multi-aspect focus happens in parallel — attention is kept on multiple aspects of the same input at once, giving the model a richer, multi-angled understanding of the context.

The same idea applies to language: multi-head attention lets the model track grammar, references, topic, and syntax **simultaneously**, with each head specializing.

### Visual

```
                              ┌─────────────────────┐
              ┌──────────►   │  Head 1: grammar    │  ─┐
              │               └─────────────────────┘   │
              │                                          │
              │               ┌─────────────────────┐   │
              ├──────────►   │  Head 2: co-ref     │  ─┤
              │               └─────────────────────┘   │
   Input ─────┤                                          ├─► Concatenate ─► Output
              │               ┌─────────────────────┐   │
              ├──────────►   │  Head 3: topic      │  ─┤
              │               └─────────────────────┘   │
              │                                          │
              │               ┌─────────────────────┐   │
              └──────────►   │  Head 4: syntax     │  ─┘
                              └─────────────────────┘
```

> [!NOTE]
> **How many heads?**
> Common head counts:
> - Original transformer paper: **8 heads**.
> - GPT-2 (small): 12 heads.
> - GPT-3: 96 heads.
> - Llama 3 (70B): 64 heads (with **Grouped Query Attention**, the actual key/value heads are fewer for efficiency).
> - Each head typically processes vectors of size `d_model / num_heads` (e.g., 768/12 = 64-dimensional per head).
>
> More heads = more perspectives, but also more compute. There's a diminishing-returns curve.

---

## 4. After attention — what happens next

The transformer doesn't stop at attention. Each transformer **block** has more layers after attention:

### Feed-forward layer
- Just a regular fully-connected neural network applied to each token independently.
- Two layers with a non-linearity (typically GELU or SwiGLU) in between.
- Pattern: vector → bigger vector → smaller vector → back to original size.
- **What does it do?** Adds extra capacity for the model to transform each token's representation. Roughly: attention is *who talks to whom*; feed-forward is *each token thinks for itself*.

The feed-forward layer is just a neural network — predict something on each token's vector, then forward it to the next stage.

### Stacked many times
A real transformer **stacks** multiple attention + feed-forward blocks. Each block refines the representations further.

| Model | Number of transformer blocks |
|---|---|
| Original paper | 6 |
| GPT-2 small | 12 |
| GPT-3 | 96 |
| Llama 3 (8B) | 32 |
| Llama 3 (405B) | 126 |

After all blocks, the final per-token vector is ready for the prediction head.

---

## 5. Linear + Softmax — turning vectors into predictions

The last two boxes of the architecture diagram from [[06 - Attention Is All You Need - Architecture Walkthrough]]:

### Linear layer
- A single matrix multiplication that maps the final per-token vector → a vector of length `vocab_size` (e.g., 200,000 for GPT-4o).
- Each entry is a **raw score (logit)** for one possible next token.
- For decoder-only models, this matrix is often shared with (or tied to) the input embedding matrix.

### Softmax
- Converts the raw scores into a **probability distribution**: every possible next token gets a probability ≥ 0, and they all sum to 1.
- Standard formula: `softmax(x_i) = exp(x_i) / Σ exp(x_j)`.

```
        Linear output (raw scores)               After softmax (probabilities)
        ──────────────────────────               ──────────────────────────────
        token "hello":   12.4                     token "hello":   0.86
        token "hi":       8.1                     token "hi":      0.10
        token "yo":       4.2                     token "yo":      0.02
        token "abc":     -1.3                     token "abc":     0.001
        ...                                        ...                   (sums to 1)
```

The linear layer is effectively the probability matrix: given a user prompt like `"hi"`, it produces scores for every possible next token — `hello`, `hi`, `yo`, `abc`, anything in the vocabulary. After softmax, the probability of `hello` following `hi` will be very high, while gibberish stays near zero.

### How the next token gets picked
The simplest strategy ("greedy") just picks the token with the highest probability. But in practice, LLMs **sample** from this distribution to add some variety:

| Strategy | What it does |
|---|---|
| **Greedy** | Always pick the most probable token. Deterministic. |
| **Sampling (temperature)** | Sample from the distribution; temperature scales how "peaked" or "flat" it is. Higher temp = more random. |
| **Top-k** | Only sample from the top-k most probable tokens. |
| **Top-p (nucleus)** | Only sample from the smallest set of tokens whose cumulative probability ≥ p. |

The `temperature` and `top_p` parameters that show up in OpenAI's API control this step.

> [!TIP]
> **How softmax can be tuned**
> The softmax can be tuned — sharpened down or flattened up. That tuning is what temperature does. **Temperature < 1** sharpens the distribution (more deterministic). **Temperature > 1** flattens it (more random / creative).

---

## 6. End-to-end summary — one full pass through the transformer

For a sequence `[t₁, t₂, t₃]`:

```
1. Token IDs: [t₁, t₂, t₃]
       │
2. Input embeddings: [e₁, e₂, e₃]                 (vectors)
       │
3. + Positional encoding: [e₁+p₁, e₂+p₂, e₃+p₃]   (position-aware vectors)
       │
4. Multi-head self-attention: [a₁, a₂, a₃]        (context-aware vectors —
       │                                            bank knows about river)
       │
5. Feed-forward: [f₁, f₂, f₃]                     (each token "thinks")
       │
       │  (steps 4–5 repeat many times — stacked blocks)
       │
6. Final vector for the last position: f₃
       │
7. Linear → vocab-sized score vector
       │
8. Softmax → probability distribution over next token
       │
9. Sample / pick → next token ID
       │
10. Append to sequence, repeat from step 1.
```

That whole loop, run dozens of times per reply, is what produces a coherent LLM response.

---

## 7. The "ML vs Developer" line — closing reminder

None of these internal mechanics is required for the **application development** track this course is on. There's no need to deep-dive into the transformer architecture — this is purely for the ML side. For a developer, there's almost no direct use for the math. Knowing it is a nice bonus, but in practice it never gets touched directly while building applications.

So having this intuition is **bonus**. It will help when:
- Debugging weird LLM output (suddenly things like "why is the model repeating itself?" → maybe `temperature=0` makes sense).
- Designing prompts (knowing about attention helps understand why **order matters** in few-shot examples).
- Discussing trade-offs (context length, latency, cost) intelligently.

But none of this internal architecture knowledge is a prerequisite for the rest of the course.

---

## 8. Main takeaways

- **Self-attention** lets each token's vector look at every other token and update itself based on context.
- That's why `bank` in `river bank` ends up with a different vector than `bank` in `ICICI bank`.
- Each token splits into **Query / Key / Value** roles. Q · Kᵀ → similarities → softmax → weighted sum of V's.
- **Multi-head attention** runs multiple attentions in parallel — each "head" captures a different aspect (grammar, references, topic, syntax).
- After attention, a **feed-forward** layer (regular NN) gives each token more processing capacity.
- Attention + feed-forward = one **transformer block**. Real models stack many of these (12–126+).
- The final per-token vector goes through **Linear → Softmax** to produce a probability distribution over the next token.
- The next token is sampled (or greedily picked) from that distribution.
- **Temperature, top-k, top-p** all tune that sampling step — knobs that show up in LLM APIs.
- This architecture detail is **optional bonus** for application developers, but useful intuition.

---

## 9. Things I still want to figure out

- What does each head **actually specialize in** after training? (Interpretability research papers explore this.)
- How does **Grouped Query Attention (GQA)** in modern models differ from standard multi-head?
- Why is `√d_k` the right scaling factor for the attention scores?
- What happens at really long context lengths — does attention "spread too thin"?
- How does the model handle the very first token's attention when there are no previous tokens to attend to?
- Is **masked** attention (decoder) just self-attention with future tokens hidden? (Yes.)
- Why don't transformers need RNN-style hidden state to track context across long passages?

---

## 10. Things to dig into

- **Visual walkthrough**: Jay Alammar, *The Illustrated Transformer* — the definitive intuition builder for attention.
- **From-scratch implementation**: Andrej Karpathy, *Let's build GPT* — writes multi-head attention in ~30 lines of PyTorch.
- **Interpretability research**: Anthropic's *"In-context Learning and Induction Heads"* — investigates what specific heads do.
- **Modern attention improvements**: search *"Flash Attention"*, *"Grouped Query Attention"*, *"Multi-Query Attention"*.
- **Sampling strategies**: explore how temperature, top-k, top-p interact in practice via OpenAI playground.

---

## 11. End of Section 1 — what's next

This is the **last architecture note** in Section 1. Section 1 has now covered:

| Note | Topic |
|---|---|
| 01 | What is an LLM |
| 02 | Decoding GPT (Generative, Pre-trained, Transformer) |
| 03 | The Transformer — predicting the next token |
| 04 | What is a Token |
| 05 | Coding our Own Tokenizer (Python + tiktoken) |
| 06 | Attention Is All You Need — architecture walkthrough |
| 07 | Vector Embeddings |
| 08 | Positional Encoding |
| 09 | Multi-Head Attention (this note) |

The next section pivots to **application development**:

- [ ] **Section 2: API Setup & Integration** — connecting to real LLMs via APIs (OpenAI, Anthropic, Google) and starting to build actual applications.

From here on, the course leans heavily into building — no more architectural deep dives.

---

## Related
- [[06 - Attention Is All You Need - Architecture Walkthrough]] — the architecture diagram this note closes out.
- [[07 - Vector Embeddings]] — the input that attention operates on.
- [[08 - Positional Encoding]] — added to embeddings just before attention.
- [[01 - What is an LLM]] — circles back to the high-level picture.

## Sources
- Vaswani et al., *Attention Is All You Need* (2017) — https://arxiv.org/abs/1706.03762
- Jay Alammar, *The Illustrated Transformer*.
- Andrej Karpathy, *Let's build GPT*.
- Anthropic, *In-context Learning and Induction Heads*.
