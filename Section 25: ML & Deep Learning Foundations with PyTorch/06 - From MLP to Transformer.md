---
title: From MLP to Transformer
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 25: ML & Deep Learning Foundations with PyTorch"
tags:
  - deep-learning
  - transformer
  - architecture
  - foundations
related:
  - "[[05 - Training a Model in PyTorch]]"
  - "[[06 - Attention Is All You Need - Architecture Walkthrough]]"
---

# From MLP to Transformer

> [!NOTE]
> **TL;DR**
> This closes the loop back to §1: a transformer is **the same neural network machinery** from this section (layers, activations, backprop, gradient descent, cross-entropy on next-token prediction) — plus the architectural ideas that make it work for **sequences**. The story of architectures: a plain **MLP** (note 02) can't handle variable-length, ordered text; **RNNs/LSTMs** added sequence memory but were **slow (sequential)** and forgot long-range context; the **Transformer** (§1) replaced recurrence with **self-attention** (every token attends to every other, in parallel) — fixing both speed and long-range memory. Crucially, none of the *training* changes: it's still the forward→loss→backprop→step loop from note 05, just with attention layers and at massive scale. Seeing this means the LLMs I've used all year are demystified — they're big neural nets trained by the loop I now understand.

> [!NOTE]
> **Where this fits**
> Final note of **Section 25** and the **bridge back to §1**. It connects the foundations just built (notes 01–05) to [[06 - Attention Is All You Need - Architecture Walkthrough]] — turning "the transformer" from a given into something grounded.

---

## 1. The same machinery, all the way up

Everything in notes 01–05 applies **unchanged** to a transformer:

| Concept (this section) | In a transformer |
|---|---|
| Neurons / layers (note 02) | Stacked layers (attention + feed-forward) |
| Non-linear activations (note 02) | GELU/ReLU in the feed-forward blocks |
| Forward pass (note 02) | tokens → layers → next-token probabilities |
| Loss = cross-entropy (note 03) | cross-entropy on **next-token prediction** |
| Backprop + gradient descent (notes 02–03) | exactly the same — Adam, mini-batches |
| Training loop (note 05) | the same loop, at massive scale |

> [!IMPORTANT]
> **An LLM is "just" a big neural net trained by the loop from note 05**
> No new *learning* mechanism appears at the top — the transformer trains via forward → loss → backprop → step (notes 02–05), on next-token cross-entropy (note 03), over enormous text data. What's special is the **architecture** (how the layers are arranged), not the training principle. That reframe demystifies the whole course.

---

## 2. Why a plain MLP isn't enough for text

The MLP from note 02/04 takes a **fixed-size** input and treats inputs independently. Text breaks both assumptions:

- **Variable length** — sentences differ in length; an MLP expects fixed dimensions.
- **Order matters** — "dog bites man" ≠ "man bites dog"; an MLP has no notion of sequence.
- **Long-range dependencies** — a word can depend on one far earlier.

So sequence-specific architectures were needed.

---

## 3. The architecture lineage

```
MLP            → fixed-size, order-blind            (note 02) — can't do sequences
   ▼
RNN / LSTM     → process tokens one-by-one, carry a "memory" state
                 ✅ handles sequences
                 ❌ SEQUENTIAL (slow, can't parallelize) ; forgets long-range context
   ▼
TRANSFORMER    → self-attention: every token attends to every other, IN PARALLEL
                 ✅ long-range context (direct connections)
                 ✅ parallel (fast to train on GPUs → scale)
                 (§1)
```

### RNN/LSTM — sequence memory, but slow
Recurrent nets read tokens **one at a time**, updating a hidden "memory." This handles order but is **inherently sequential** (can't parallelize across the sequence → slow to train) and struggles to remember **long-range** dependencies (the signal fades).

### Transformer — attention replaces recurrence
The transformer (§1) drops recurrence entirely. **Self-attention** lets every token look at every other token **directly and in parallel**:
- **Long-range**: any token connects to any other in one step (no fading memory).
- **Parallel**: the whole sequence processes at once → trains efficiently on GPUs → **scales** to huge models/data.

This is the "**Attention Is All You Need**" insight ([[06 - Attention Is All You Need - Architecture Walkthrough]], §1).

---

## 4. What the transformer adds on top of the basics

Beyond standard layers, the transformer introduces (all covered in §1):

| Piece | Role | §1 note |
|---|---|---|
| **Tokenization** | text → discrete tokens | [[04 - What is a Token]] |
| **Embeddings** | tokens → vectors | [[07 - Vector Embeddings]] |
| **Positional encoding** | inject order (no recurrence to carry it) | [[08 - Positional Encoding]] |
| **Self-attention** | tokens attend to each other | [[06 - Attention Is All You Need - Architecture Walkthrough]] |
| **Multi-head attention** | several attention "views" in parallel | [[09 - Multi-Head Attention]] |
| **Feed-forward + residuals + layer norm** | the standard NN parts (notes 02–03) | §1 |

> [!TIP]
> **Positional encoding exists *because* attention is order-blind**
> An RNN gets order for free (it reads left-to-right). Self-attention sees all tokens at once with no inherent order, so the transformer **adds position information explicitly** (positional encoding, §1). It's a direct consequence of trading recurrence for parallel attention — a nice example of how the architecture's pieces fit together.

---

## 5. The payoff: scaling

Because the transformer is **parallelizable**, it can be trained on massive data with massive compute — and it keeps improving with scale (the basis of "scaling laws"). RNNs couldn't scale this way. **Scale + the transformer architecture + the training loop from note 05 = the LLMs** used throughout the course.

```
transformer (parallel) + huge data + huge compute → LLM
   trained by: forward → cross-entropy loss → backprop → gradient descent (notes 02–05)
```

---

## 6. The full arc (this section → the whole course)

```
note 01  ML: learn from data, minimize loss, generalize
note 02  neural nets: layers + activations + backprop
note 03  gradient descent + cross-entropy
note 04  PyTorch: tensors, autograd, nn.Module
note 05  the training loop (forward→loss→backward→step)
note 06  transformer = that machinery + attention, at scale  ──► §1 LLMs
                                                              ──► fine-tuning (§21)
                                                              ──► everything else
```

Every section of the course now rests on understood foundations rather than black boxes.

---

## 7. Main takeaways

- A transformer uses the **same machinery** from this section (layers, activations, backprop, gradient descent, cross-entropy) — the **training loop (note 05) is unchanged**.
- **An LLM is a big neural net** trained by that loop on **next-token cross-entropy** at scale — the architecture is what's special, not the learning principle.
- **MLPs** can't handle text (fixed-size, order-blind); **RNNs/LSTMs** added sequence memory but were **sequential (slow)** and forgot long-range context.
- The **Transformer** replaced recurrence with **self-attention** — **long-range** + **parallel** → trainable at scale.
- It adds **tokenization, embeddings, positional encoding, (multi-head) attention** on top of standard NN parts (all §1).
- **Positional encoding** exists *because* attention is order-blind.
- **Parallelism → scaling → LLMs**; this closes the loop back to §1.

---

## 8. Things I still want to figure out

- Re-read §1 (attention, positional encoding) now with the foundations in hand — does it click deeper?
- Implement a tiny transformer in PyTorch (e.g. a minGPT-style exercise)?
- How attention's compute scales with sequence length (quadratic cost)?

---

## 9. Things to dig into

- **Re-read §1** with notes 01–05 as background: [[06 - Attention Is All You Need - Architecture Walkthrough]].
- **"The Annotated Transformer"** / minGPT — build one in PyTorch.
- Scaling laws; attention efficiency variants.

---

## 10. Section wrap-up

Section 25 builds the **foundations under everything**: ML basics (note 01), neural nets + backprop (note 02), gradient descent + loss (note 03), PyTorch (note 04), the training loop (note 05), and the path **from MLP to Transformer** (this note). The result: the LLMs, embeddings, and fine-tuning used across the whole course are no longer black boxes — they're big neural networks trained by a loop I now understand, with attention as the architectural key that made them scale.

---

## Related
- [[05 - Training a Model in PyTorch]] — the loop that trains a transformer too.
- [[06 - Attention Is All You Need - Architecture Walkthrough]] — the §1 deep-dive this grounds.
- [[01 - What is an LLM]] — now demystified.

## Sources
- [Attention Is All You Need (paper)](https://arxiv.org/abs/1706.03762)
- [The Annotated Transformer](https://nlp.seas.harvard.edu/annotated-transformer/)
