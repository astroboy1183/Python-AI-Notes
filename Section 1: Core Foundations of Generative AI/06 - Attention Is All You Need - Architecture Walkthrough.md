---
title: Attention Is All You Need - Architecture Walkthrough
date: 2026-05-28
source: "Section 1 / Lecture 6"
type: lecture-notes
status: in-progress
section: "Section 1: Core Foundations of Generative AI"
tags:
  - llm
  - transformer
  - attention-is-all-you-need
  - architecture
  - input-embeddings
  - positional-encoding
  - multi-head-attention
  - masked-attention
  - feed-forward
  - softmax
  - foundations
  - ml-vs-dev
related:
  - "[[01 - What is an LLM]]"
  - "[[02 - How LLMs Work - Decoding GPT]]"
  - "[[03 - The Transformer - Predicting the Next Token]]"
  - "[[04 - What is a Token]]"
  - "[[05 - Coding our Own Tokenizer]]"
---

# Attention Is All You Need — Architecture Walkthrough

> [!abstract] TL;DR
> A high-level tour through the transformer architecture diagram from Google's 2017 *Attention Is All You Need* paper. The flow on the **input (encoder) side**: input → **input embeddings** → **positional encoding** → **multi-head attention** → forwarded to output side. The flow on the **output (decoder) side**: previous output → **output embeddings** → **positional encoding** → **masked multi-head attention** → combined with encoder output → **linear** → **softmax** → next-token probability distribution. There's also a critical line to draw: **deep ML math is for researchers building foundation models, not for developers building applications**. This course leans developer; the architecture overview is **optional bonus context** — useful for intuition, not required to build agents.

> [!info] Where this fits
> Sixth note of **Section 1: Core Foundations of Generative AI**. The previous notes covered: what an LLM is, the GPT acronym, what a transformer does at a high level (predict next token), what tokens are, and how to tokenize in Python. This note is the **architecture walkthrough** — the boxes inside the transformer. Most of the individual boxes get their own deep-dive notes next (vector embeddings, positional encoding, multi-head attention).

> [!warning] This note is "bonus content"
> The deep math/architecture details are for **ML researchers** building foundation models, not for **application developers** building agents. The rest of the course (agents, RAG, memory, MCP, LangGraph) won't require these internals. This walkthrough is a "nice to have for intuition" — not a prerequisite for anything later.

---

## 1. The diagram in one picture

The transformer from the original paper looks roughly like this (left half = encoder, right half = decoder):

```
┌──────────────────────────────┐       ┌──────────────────────────────┐
│         INPUT SIDE           │       │         OUTPUT SIDE          │
│         (Encoder)            │       │         (Decoder)            │
│                              │       │                              │
│  Inputs                      │       │  Outputs (shifted right)     │
│    │                         │       │    │                         │
│    ▼                         │       │    ▼                         │
│  ┌─────────────────────┐     │       │  ┌─────────────────────┐     │
│  │  Input Embeddings   │     │       │  │  Output Embeddings  │     │
│  └─────────┬───────────┘     │       │  └─────────┬───────────┘     │
│            │                 │       │            │                 │
│            ▼                 │       │            ▼                 │
│  ┌─────────────────────┐     │       │  ┌─────────────────────┐     │
│  │ Positional Encoding │     │       │  │ Positional Encoding │     │
│  └─────────┬───────────┘     │       │  └─────────┬───────────┘     │
│            │                 │       │            │                 │
│            ▼                 │       │            ▼                 │
│  ┌─────────────────────┐     │       │  ┌─────────────────────┐     │
│  │  Multi-Head         │     │       │  │  Masked Multi-Head  │     │
│  │  Attention          │     │       │  │  Attention          │     │
│  └─────────┬───────────┘     │       │  └─────────┬───────────┘     │
│            │                 │       │            │                 │
│            ▼                 │       │            ▼                 │
│  ┌─────────────────────┐     │       │  ┌─────────────────────┐     │
│  │  Feed-Forward       │     │       │  │  Multi-Head         │     │
│  └─────────┬───────────┘     │       │  │  Attention          │     │
│            │                 │       │  │  (with encoder)     │     │
│            └────────────────►├──────►│  └─────────┬───────────┘     │
│                              │       │            │                 │
│                              │       │            ▼                 │
│                              │       │  ┌─────────────────────┐     │
│                              │       │  │  Feed-Forward       │     │
│                              │       │  └─────────┬───────────┘     │
│                              │       │            │                 │
│                              │       │            ▼                 │
│                              │       │  ┌─────────────────────┐     │
│                              │       │  │  Linear             │     │
│                              │       │  └─────────┬───────────┘     │
│                              │       │            │                 │
│                              │       │            ▼                 │
│                              │       │  ┌─────────────────────┐     │
│                              │       │  │  Softmax            │     │
│                              │       │  └─────────┬───────────┘     │
│                              │       │            │                 │
│                              │       │            ▼                 │
│                              │       │  Next-token probabilities    │
└──────────────────────────────┘       └──────────────────────────────┘
```

Walking through each named box at a high level below. Detailed coverage of the most important ones comes in upcoming notes.

---

## 2. Walking through the flow — example "hey there, how are you?"

Using this example to trace data through the architecture.

### Phase 1 — encoding the input
1. **Inputs**: the user-supplied tokens, e.g., `"hey there, how are you?"`.
2. **Input embeddings**: each token ID → a high-dimensional **vector**. Captures semantic meaning. (Whole note coming: [[07 - Vector Embeddings]].)
3. **Positional encoding**: adds information about **where** each token is in the sequence — preserves order. (Whole note coming: [[08 - Positional Encoding]].)
4. **Multi-head attention**: lets tokens "look at" each other, building context-aware representations. (Whole note coming: [[09 - Multi-Head Attention]].)
5. **Feed-forward**: a plain neural-network layer that further processes the attention output.

By the end of this, the encoder has produced a rich representation of the input that the decoder can use.

### Phase 2 — decoding to produce the output
The decoder generates the response **one token at a time** (the autoregressive loop from [[03 - The Transformer - Predicting the Next Token]]).

1. **Outputs (shifted right)**: whatever has been generated so far. Initially, just a **start token**.
2. **Output embeddings + positional encoding**: same idea as encoder side.
3. **Masked multi-head attention**: like multi-head attention, but with a **mask** that prevents the decoder from "cheating" by peeking at future tokens. (The "masked" word means: when predicting token N, only see tokens 1…N-1.)
4. **Multi-head attention (with encoder output)**: this is where the decoder **incorporates information from the input**. Lets the decoder ask: *"given what the user said, what should I generate next?"*
5. **Feed-forward**: another neural-net layer.
6. **Linear**: projects the final vector into a vector the size of the vocabulary (e.g., 200,000 numbers). Each number is a **score** for one possible next token.
7. **Softmax**: turns those scores into a **probability distribution** — every possible next token gets a probability, all summing to 1.

The token with the highest probability (usually) becomes the next predicted token. Append and loop.

The linear layer produces the raw scores, the softmax turns those scores into a probability distribution — that's literally the next-token prediction.

---

## 3. Why "masked" matters on the decoder side

> The mask is what enforces causality: when generating token N, the decoder can only see tokens 1 through N-1.

Without the mask during training, the model could trivially "cheat" by copying the answer from the future positions. Masking forces the model to actually **learn to predict** rather than copy.

In modern GPT-style models (decoder-only architectures), this masked attention is the **only** attention in the model — there's no separate encoder.

> [!example] Encoder-decoder vs decoder-only
> The original 2017 transformer (the one in the diagram) is **encoder-decoder**. It was designed for translation: encode the English sentence, decode it into French.
>
> Modern **GPT-style** LLMs are **decoder-only** — they skip the encoder entirely. The "input" and the "output so far" are concatenated and fed through the same masked-attention stack. Simpler architecture, scales beautifully.
>
> Other variants:
> - **BERT**: encoder-only (no decoder). Used for classification, embeddings — not generation.
> - **T5**: encoder-decoder. Used for text-to-text tasks.
> - **GPT family, Llama, Mistral, Claude**: decoder-only.
>
> When this course talks about "the transformer" going forward, it almost always means **decoder-only** in practice.

---

## 4. End-to-end walkthrough with the example

For `"hey there, how are you?"` going through a (simplified) transformer:

```
INPUT SIDE                                  OUTPUT SIDE
─────────────                               ──────────────

"hey there, how are you?"                   <start>
       │                                          │
       ▼                                          ▼
Tokenize → [25216, 1354, ...]                Tokenize → [<start>]
       │                                          │
       ▼                                          ▼
Input embeddings (vectors)                   Output embeddings (vectors)
       │                                          │
       ▼                                          ▼
+ Positional encoding                        + Positional encoding
       │                                          │
       ▼                                          ▼
Multi-head attention                         Masked multi-head attention
(tokens look at each other)                  (only past tokens, no peeking)
       │                                          │
       ▼                                          ▼
Feed-forward                                 Multi-head attention WITH encoder
       │                                     (combines decoder state +
       │                                      encoder representation)
       │                                          │
       │                                          ▼
       │                                     Feed-forward
       │                                          │
       │                                          ▼
       │                                     Linear  → vocab-sized score vector
       │                                          │
       │                                          ▼
       │                                     Softmax → probability distribution
       │                                          │
       │                                          ▼
       └─────────────────────────────────────► "I"  ← predicted

(loop: feed "I" back through decoder, predict next token, repeat...)
```

After enough loop iterations, the full reply `"I am doing fine"` (or whatever) gets built.

---

## 5. The ML vs Developer line — important framing

Worth pausing to draw a line that's relevant for the **rest of the course**:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   ┌────────────────────────────┐  ┌──────────────────────────┐   │
│   │  ML / RESEARCH side        │  │  APPLICATION DEV side    │   │
│   │                            │  │                          │   │
│   │  - Math-heavy              │  │  - Build apps            │   │
│   │  - Research papers         │  │  - Solve business probs  │   │
│   │  - Build foundation models │  │  - Use existing LLMs     │   │
│   │  - Train new architectures │  │  - Agents, RAG, etc.     │   │
│   │  - PhD-level focus         │  │  - "Engineering" focus   │   │
│   │                            │  │                          │   │
│   │  Tools: PyTorch, TF,       │  │  Tools: LangChain,       │   │
│   │  CUDA, distributed         │  │  LangGraph, OpenAI API,  │   │
│   │  training, etc.            │  │  Mem0, MCP, etc.         │   │
│   │                            │  │                          │   │
│   └────────────────────────────┘  └──────────────────────────┘   │
│                                                                  │
│         "The white papers,              "The course"             │
│          equations, math"               (this side)              │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

| ML / Research | Application Development |
|---|---|
| Deep math + research | Use trained models |
| Build foundation models | Build agents, RAG, apps |
| White papers like *Attention Is All You Need* | High-level APIs (OpenAI, LangGraph) |
| Train models from scratch | Compose existing capabilities |
| Career: research scientist, ML engineer | Career: AI engineer, backend dev, full-stack |

This course is for developers. Agentic AI, agentic workflows, agents themselves — all of that lives in **application development**. In application development, there's no need for the mathematics or the formulas. Knowing them is a nice bonus, but absolutely not required.

### Why this framing matters
- The rest of this section's architecture content (this note + embeddings + positional encoding + multi-head attention) is **optional / bonus**.
- The course is intentionally choosing the developer track.
- Not understanding every detail of self-attention won't block any later note.
- Honest framing about scope.

> [!tip] My read on this
> Even on the developer track, having **intuition** about how the model works under the hood is genuinely useful — it helps with debugging weird LLM behavior, designing better prompts, and understanding cost/latency trade-offs. So the bonus content is worth absorbing at a "mental model" level even without the math.

---

## 6. Component preview — what's coming in the next notes

| Box in the diagram | Dedicated note |
|---|---|
| Input / Output embeddings | [[07 - Vector Embeddings]] |
| Positional encoding | [[08 - Positional Encoding]] |
| Multi-head attention (and self-attention) | [[09 - Multi-Head Attention]] |
| Feed-forward layer | Briefly touched in [[09 - Multi-Head Attention]] (just "a neural network") |
| Linear + softmax | Briefly touched in [[09 - Multi-Head Attention]] (probability distribution) |

So this note functions as the **map**; later notes fill in the legend.

---

## 7. Main takeaways

- The transformer diagram has **two halves**: encoder (input side) and decoder (output side).
- Each half processes its data through: **embedding → positional encoding → attention → feed-forward**.
- The **decoder's attention is masked**: it can only attend to past tokens, not future ones.
- The decoder also has a **second attention layer** that incorporates the encoder's output — this is how the decoder grounds its generation in the input.
- The decoder ends with **Linear → Softmax**, producing a **probability distribution over the vocabulary** — that's the next-token prediction.
- Tokens are emitted one at a time, looped back into the decoder, until an end-of-sequence token.
- Modern GPT-style models are **decoder-only** — no encoder, simpler architecture.
- **ML researcher work** ≠ **AI application developer work**. This course is firmly on the developer side. The architecture details are bonus context.

---

## 8. Things I still want to figure out

- What does the **inside** of attention actually compute? (Queries, keys, values — covered next.)
- What does the **feed-forward layer** do that attention doesn't?
- How many layers do real models stack? (GPT-3: 96 layers. GPT-4: rumored ~120. Llama 3.1 405B: 126.)
- Why is the linear → softmax projection at the end so expensive? (It's a `model_dim × vocab_size` matrix multiply — huge.)
- What's the difference between the encoder and decoder's positional encodings? (None really — same formula.)
- For decoder-only models, what does the architecture look like compared to the original encoder-decoder diagram?
- Are there modern architectural improvements over the 2017 paper? (Yes: RMSNorm, RoPE, GQA, MoE — worth exploring later.)

---

## 9. Things to dig into

- **The paper itself**: Vaswani et al., *Attention Is All You Need* (2017) — https://arxiv.org/abs/1706.03762
- **Illustrated walkthrough**: Jay Alammar, *The Illustrated Transformer* — annotates every box of this same diagram beautifully.
- **Code-from-scratch**: Andrej Karpathy, *Let's build GPT* on YouTube — implements a working transformer in ~200 lines of PyTorch.
- **Modern improvements**: search for *"GPT-3.5 vs GPT-4 architecture"*, *"RoPE positional encoding"*, *"Grouped Query Attention (GQA)"*.
- **Mathematical depth (if curious)**: 3Blue1Brown's *Neural Networks* series + *Attention in transformers* video.

---

## 10. Next up in this section

The next three notes take the most important boxes from this diagram and explain them properly:

- [ ] [[07 - Vector Embeddings]] — what input/output embeddings actually are.
- [ ] [[08 - Positional Encoding]] — why and how position info is added.
- [ ] [[09 - Multi-Head Attention]] — the heart of the transformer.

After Section 1 ends, the course pivots to **application development** (Section 2 onwards): APIs, prompts, deployment, agents, RAG, memory, etc.

---

## Related
- [[01 - What is an LLM]] — definitional intro.
- [[02 - How LLMs Work - Decoding GPT]] — the GPT acronym.
- [[03 - The Transformer - Predicting the Next Token]] — what the whole architecture is for.
- [[04 - What is a Token]] — the input/output unit.
- [[05 - Coding our Own Tokenizer]] — hands-on Python.

## Sources
- Vaswani et al., *Attention Is All You Need* (2017) — https://arxiv.org/abs/1706.03762
- Jay Alammar, *The Illustrated Transformer*.
- Andrej Karpathy, *Let's build GPT*.
- 3Blue1Brown's *Neural Networks* series and *Attention in transformers*.
