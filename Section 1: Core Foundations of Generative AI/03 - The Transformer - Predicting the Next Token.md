---
title: The Transformer - Predicting the Next Token
date: 2026-05-28
source: "Section 1 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 1: Core Foundations of Generative AI"
tags:
  - llm
  - transformer
  - gpt
  - next-token-prediction
  - attention-is-all-you-need
  - google-translate
  - generative-ai
  - foundations
  - autoregressive
related:
  - "[[01 - What is an LLM]]"
  - "[[02 - How LLMs Work - Decoding GPT]]"
---

# The Transformer — Predicting the Next Token

> [!abstract] TL;DR
> A **transformer** is a neural-network architecture introduced by Google in the 2017 paper *Attention Is All You Need* — the actual "brain" behind every modern LLM (GPT, Gemini, Claude, Llama, etc.). Google's original use case was **sequence-to-sequence translation** (e.g., English → French in Google Translate). OpenAI's GPT is a special flavor of transformer with a deceptively simple job: **given a sequence of input tokens, predict the next single token**. That's it. Everything that looks like a coherent multi-sentence reply is built by **looping** that single prediction over and over, appending each predicted token to the input and re-running. Because every reply word requires another full forward pass through a huge neural network, this loop is why LLMs are **GPU-intensive**.

> [!info] Where this fits
> Third note of **Section 1: Core Foundations of Generative AI**. The previous notes covered the LLM definition ([[01 - What is an LLM]]) and the GPT acronym ([[02 - How LLMs Work - Decoding GPT]]). This one zooms into the **T** of GPT — the transformer itself — and explains its core operation. The deep architecture walkthrough (input embeddings, positional encoding, multi-head attention, softmax, etc.) comes in upcoming notes.

---

## 1. Where the word "transformer" comes from

> **Transformer = neural-network architecture from the 2017 Google paper *Attention Is All You Need*.**

Key facts:
- Published by Google researchers.
- Introduced an architecture that could process sequences without recurrence (no RNNs).
- Quickly became the backbone of every state-of-the-art LLM.
- Google itself used it heavily for **Google Translate** — converting one language sequence into another (English → Hindi, English → French, etc.).

The transformer is the actual internals — the big brain — behind every LLM. Google is the company that introduced it, and this is the core of how LLMs are possible at all in today's world.

A little ironic, given that **OpenAI** (with GPT) is the household name in LLMs — but the underlying architecture they all use was published by Google.

---

## 2. The original transformer — sequence in, sequence out

The original use case from Google's paper:

```
┌──────────────────┐       ┌──────────────────┐       ┌──────────────────┐
│  Input sequence  │ ───→  │   Transformer    │ ───→  │ Output sequence  │
│  "hi and hello"  │       │   (ML magic)     │       │  "bonjour et     │
│                  │       │                  │       │   salut"         │
└──────────────────┘       └──────────────────┘       └──────────────────┘
```

- Input is a **sequence** (a sentence, a paragraph).
- Output is another **sequence** (the translation).
- The transformer learns the mapping during training.

Google Translate is the canonical example: feed it an English sentence, get back the same sentence in Hindi or French. Same architecture under the hood — just trained on parallel translation data.

---

## 3. GPT's variation — only predict the NEXT token

GPT (and every modern chat-style LLM) uses the transformer architecture **slightly differently**:

> **Input: some tokens. Output: a single prediction — the very next token.**

That's the entire job description. Not a whole sentence. Not a paragraph. **One token.**

```
┌────────────────────┐       ┌──────────────────┐       ┌──────────────┐
│   Input tokens     │ ───→  │   Transformer    │ ───→  │  Next token  │
│   "hey there"      │       │      (GPT)       │       │     "I"      │
└────────────────────┘       └──────────────────┘       └──────────────┘
```

That's all the transformer is *technically* responsible for, per forward pass.

> [!tip] The deceptively simple truth
> Behind every multi-paragraph LLM response is a model that, by itself, can only do **one thing**: predict one next token. Coherent essays come from *looping* this prediction thousands of times.

---

## 4. The loop — how a one-token prediction becomes a paragraph

The trick is **autoregression**: keep feeding the model its own previous output.

### Walkthrough — a concrete example
Input: `"hey there"`. Expected eventual reply: `"I am good"`.

| Iter | Input fed to transformer | Predicted next token | Running output |
|---|---|---|---|
| 1 | `hey there` | `I` | `I` |
| 2 | `hey there I` | ` am` (with space) | `I am` |
| 3 | `hey there I am` | ` good` | `I am good` |
| 4 | `hey there I am good` | `<end>` token | `I am good` (stop) |

After 4 forward passes, the reply `"I am good"` is built. The `<end>` (or end-of-sequence) token signals the loop to terminate.

### Visual flow

```
┌────────────────┐
│  hey there     │ ── pass 1 ──→ transformer → "I"
└────────────────┘
        │ append
        ▼
┌────────────────┐
│  hey there I   │ ── pass 2 ──→ transformer → " am"
└────────────────┘
        │ append
        ▼
┌────────────────────┐
│ hey there I am     │ ── pass 3 ──→ transformer → " good"
└────────────────────┘
        │ append
        ▼
┌────────────────────────┐
│ hey there I am good    │ ── pass 4 ──→ transformer → <end>
└────────────────────────┘
        │
        ▼
   LOOP TERMINATES
```

The transformer is only and only concerned with the **next token**. It might emit a space, then `good`, then a period — one token per forward pass. That's how GPT works: for any input, it only ever predicts the next single token. Then the process just keeps repeating.

---

## 5. A second concrete example — "hey there, cute Jayanth"

A more colorful example that demonstrates the same loop:

| Iter | Running text | Predicted next |
|---|---|---|
| 1 | `hey there` | `hey there` (acknowledgment) |
| 2 | `hey there ,` | `,` |
| 3 | `hey there, cute` | `cute` |
| 4 | `hey there, cute Jayanth` | `Jayanth` |
| 5 | `hey there, cute Jayanth ,` | `,` |
| 6 | `hey there, cute Jayanth, what's cooking today?` | `what's cooking today?` |
| 7 | (end token) | `<end>` |

Same principle as before: **one token per pass**, accumulating the full response over many iterations.

---

## 6. Why this is so GPU-intensive

An obvious question: **isn't running the model 50+ times per response overkill?**

> [!warning] Compute cost
> Generating a single 50-token reply means running the transformer's full forward pass **~50 separate times**. Each pass involves hundreds of billions of multiply-add operations across the model's parameters.

That's why:
- LLMs need **GPUs / TPUs** — CPUs are too slow for tensor math at this scale.
- High-end LLMs require **high-VRAM, high-bandwidth** accelerators (A100, H100, B200, TPU v5).
- Inference is far cheaper than training, but **still much more expensive than serving static content**.
- Reply latency grows roughly **linearly** with reply length — longer reply = more loop iterations = more GPU time.

This isn't cheap. The transformer is a machine-learning model that has to be run over and over — the prediction loop never stops until the end-of-sequence token. Even for a short response like *"hey there"*, that's five to six full forward passes through a multi-billion-parameter network. A lot of compute goes into producing even a tiny reply.

> [!example] Autoregressive vs other generation modes
> The way GPT works (loop one-token-at-a-time, feeding output back as input) is technically called **autoregressive generation**. Other generation patterns exist:
> - **Non-autoregressive** (e.g., BERT-style masked language models) — predict missing tokens in parallel, but don't generate fluent long-form text well.
> - **Diffusion text models** (research area) — generate the full sequence at once via iterative denoising.
> - **Sequence-to-sequence** (Google's original transformer in Translate) — encoder reads the whole input, decoder generates the output (also autoregressive on the decode side).
>
> Modern chat-style LLMs are all autoregressive on the decoder side. That's why the "one token at a time" loop is universal across GPT, Claude, Gemini, Llama, etc.

---

## 7. Original transformer (Google) vs GPT (OpenAI)

| | Google's transformer (2017) | GPT (OpenAI's flavor) |
|---|---|---|
| **Use case** | Sequence → sequence (translation) | Sequence → next token (generation) |
| **Architecture** | Encoder + Decoder | Decoder-only |
| **Trained on** | Parallel sentence pairs (e.g., English ↔ French) | Massive general-purpose text corpus |
| **Output style** | Whole target sentence | One token, then loop |
| **Example product** | Google Translate | ChatGPT, GPT-4, GPT-4o |

> [!note]
> Both are "transformers" — they share the same fundamental architectural ideas (attention, positional encoding, feed-forward layers). The difference is what they're trained to do and how the output side is structured.

---

## 8. The mental model after this note

The picture of an LLM now looks like:

```
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│  User prompt: "hey there"                                        │
│       │                                                          │
│       ▼                                                          │
│  ┌──────────────────────────────┐                                │
│  │      THE LOOP                │                                │
│  │                              │                                │
│  │   tokens ──→ transformer ──→ next token                       │
│  │     ▲                          │                              │
│  │     │                          │                              │
│  │     └────── append ────────────┘                              │
│  │                                                                │
│  │     (stops when transformer outputs <end>)                    │
│  └──────────────────────────────┘                                │
│       │                                                          │
│       ▼                                                          │
│  Full response: "I am good"                                      │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

The "transformer" box itself is still partly opaque — what's inside it? That's the next several notes (tokenization, embeddings, attention mechanism, etc.).

---

## 9. Main takeaways

- The **transformer** is a neural-network architecture from Google's 2017 paper *Attention Is All You Need*.
- It's the underlying engine of every modern LLM: GPT, Gemini, Claude, Llama, Mistral, …
- Google originally used it for **sequence-to-sequence** tasks like translation (Google Translate).
- **GPT-style LLMs** use a simpler version: **predict only the next single token**.
- A multi-token reply is built by **looping** — append predicted token to input, re-run, repeat.
- The loop ends when the model emits a special **end-of-sequence token**.
- Looping = many forward passes per reply = **GPU-intensive**.
- This is also called **autoregressive generation**.
- Despite the apparent simplicity (predict one token), this approach produces coherent, useful long-form text — one of the surprises of the deep-learning era.

---

## 10. Things I still want to figure out

- What's actually inside the transformer? (input embeddings, attention, etc. — covered in upcoming notes)
- How does the model decide between multiple possible next tokens? (Greedy? Sampling? Temperature?)
- What's the `<end>` token literally — a special reserved token ID?
- Why one token at a time and not, say, a few at once? (Speculative decoding exists — interesting follow-up.)
- How much faster is inference with techniques like **KV-cache** that avoid recomputing past tokens every pass?
- How does the encoder/decoder split in the original Google transformer differ from GPT's decoder-only setup?

---

## 11. Things to dig into

- **The paper**: Vaswani et al., *Attention Is All You Need* (2017) — https://arxiv.org/abs/1706.03762
- **Visual**: Jay Alammar, *The Illustrated Transformer* — the gold-standard intuition-builder.
- **Code**: Andrej Karpathy, *Let's build GPT from scratch* — implements an autoregressive transformer in pure PyTorch.
- **Modern variant**: read about **speculative decoding** and **KV cache** — engineering tricks that speed up the loop without changing the math.

---

## 12. Next up in this section

The transformer loop predicts the "next token" — but what IS a token, exactly? Covered next:

- [ ] [[04 - What is a Token]] — definitions, examples, tokenization mechanics.

After that, expected:

- [ ] [[05 - Coding our Own Tokenizer]] — hands-on Python with `tiktoken`.
- [ ] [[06 - Attention Is All You Need - Architecture Walkthrough]] — the full transformer diagram, layer by layer.
- [ ] [[07 - Vector Embeddings]] — how tokens become numbers with semantic meaning.
- [ ] [[08 - Positional Encoding]] — preserving sentence order.
- [ ] [[09 - Multi-Head Attention]] — how tokens "talk" to each other.

---

## Related
- [[01 - What is an LLM]] — definitional intro.
- [[02 - How LLMs Work - Decoding GPT]] — the GPT acronym (where the **T** in this note comes from).

## Sources
- Vaswani et al., *Attention Is All You Need* (2017) — https://arxiv.org/abs/1706.03762
- Jay Alammar, *The Illustrated Transformer*.
- Andrej Karpathy, *Let's build GPT from scratch*.
