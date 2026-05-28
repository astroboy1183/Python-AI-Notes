---
title: How LLMs Work - Decoding GPT
date: 2026-05-28
source: "Section 1 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 1: Core Foundations of Generative AI"
tags:
  - llm
  - gpt
  - generative
  - pre-trained
  - transformer
  - tokens
  - input-tokens
  - output-tokens
  - openai
  - generative-ai
  - foundations
  - acronym
related:
  - "[[01 - What is an LLM]]"
---

# How LLMs Work — Decoding GPT

> [!abstract] TL;DR
> An LLM looks like a black box: input goes in, output comes out. The technical terms for what goes in and out are **input tokens** and **output tokens**. The black box itself, for OpenAI's models, is called **GPT** — which stands for **Generative, Pre-trained, Transformer**. Each word matters:
> - **Generative** = generates new text (contrast with Google's search, which only retrieves).
> - **Pre-trained** = generation is grounded in data the model was trained on beforehand.
> - **Transformer** = the actual neural-network architecture (covered next, from Google's *Attention Is All You Need* paper).
>
> The clever insight: every modern LLM (Gemini, Claude, Mistral, etc.) is technically a "generative pre-trained transformer" — but only OpenAI trademarked the literal name. Like naming a car brand "Car" or a shoe brand "Shoe."

> [!info] Where this fits
> Second note of **Section 1: Core Foundations of Generative AI**. The previous note [[01 - What is an LLM]] covered the *definition* of an LLM. This one starts unpacking *what's inside the black box* — the terminology (tokens) and the acronym (GPT). The next note goes into the **transformer architecture** itself (from the 2017 Google paper).

---

## 1. The black-box picture

The mental model so far:

```
┌──────────┐       ┌─────────┐       ┌──────────┐
│   User   │ ───→ │   LLM   │ ───→ │   User   │
│  "hi"    │       │ (???)   │       │ "Hey…"   │
└──────────┘       └─────────┘       └──────────┘
   input            black box           output
```

The LLM accepts an input from the user and produces a response. *How* the box works internally is still unknown — but it somehow produces "magical" responses on demand.

This note starts peeling back the box.

---

## 2. Terminology — input tokens & output tokens

Two technical terms used throughout the rest of the course:

| Term | What it refers to |
|---|---|
| **Input tokens** | Whatever the user sends into the LLM (the prompt) |
| **Output tokens** | Whatever the LLM produces in response |

```
┌──────────┐                                ┌──────────┐
│   User   │ ─── input tokens ─────────→  │   LLM    │
└──────────┘                                └──────────┘
                                                  │
┌──────────┐                                      │
│   User   │ ←──── output tokens ────────────────┘
└──────────┘
```

> [!note] What's a "token"?
> Conceptually, a token is a chunk of text — sometimes a whole word, sometimes a part of a word, sometimes punctuation. The full mechanics (why models work on tokens instead of characters or words) is covered in a later note on **tokenization**. For now, treat "tokens" as "pieces of text the model reads/writes."

> [!example] Token examples
> A rough sense of how text becomes tokens (using a typical BPE tokenizer):
> - `"hi"` → 1 token
> - `"What is 2 + 2?"` → 6 tokens
> - `"unbelievable"` → often 2 tokens (`un` + `believable`)
> - `"jayanth_appalla@rediffmail.com"` → ~12 tokens (the email breaks into many sub-pieces)
>
> Tokens matter because:
> 1. LLM **pricing** is per-token (e.g., $0.01 per 1k input tokens, $0.03 per 1k output tokens).
> 2. LLM **context windows** are measured in tokens (e.g., 128k tokens ≈ ~96k English words).

---

## 3. Decoding "GPT" — the heart of it

> **GPT = Generative + Pre-trained + Transformer**

The name is genuinely brilliant — it literally describes what the model *is*. Three words, three orthogonal properties:

```
                        GPT
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                ▼
    Generative      Pre-trained      Transformer
   (the nature)     (the basis)      (the object)
```

| Part | What it answers |
|---|---|
| **Generative** | *What does the model do?* → It generates. |
| **Pre-trained** | *Based on what?* → Data it was trained on beforehand. |
| **Transformer** | *What kind of system is it?* → A neural-network architecture. |

The rest of this note unpacks each word with concrete analogies.

---

## 4. "Generative" — what it actually means

Generative means the LLM **produces new text on the spot**, not retrieves existing text from somewhere.

### The Google contrast

A comparison with Google search makes this concrete:

| Google Search | LLM (ChatGPT, etc.) |
|---|---|
| **Search engine** | **Generative engine** |
| Takes a query → returns relevant **existing** links | Takes a query → **generates** a new response |
| Works on **keywords + indexing** | Works on **prediction + neural patterns** |
| Output already exists somewhere on the web | Output is **produced fresh** each time |

> When typing "jwks" into Google, the result is a list of indexed websites that contain that keyword. Google found things that already existed. **No new text is created.**

### A quick live test

To prove the LLM is genuinely generating (not retrieving), run a test:

| Step | Prompt | Result |
|---|---|---|
| 1 | *"From now onwards, address me as cute Jayanth."* | LLM acknowledges the instruction. |
| 2 | *"Hey, who am I?"* | LLM replies: *"You are cute Jayanth"* (or similar). |

That phrase — *"cute Jayanth"* — doesn't exist anywhere on the internet. It's **invented on the spot** based on:
- The instruction given earlier in the conversation.
- The LLM's learned ability to follow such instructions.

It's not searching for something, it's actually generating on the spot.

> [!tip] Key insight
> Search retrieves. **Generation creates.** The output doesn't have to exist anywhere before — the model produces it fresh. That's the difference between Google and an LLM.

---

## 5. "Pre-trained" — what it actually means

If the model can generate text, the next obvious question: **on what basis?** What does it use to decide which words to produce?

> Answer: **the data it was pre-trained on.**

Generation isn't random. The model has already absorbed massive amounts of language data before it ever talks to a user. That data is what shapes its outputs.

### The "teacher" analogy

A self-referential way to see it: a person teaching about LLMs is also generating content — but only because they previously researched it, read books and articles, watched courses, talked to experts. They're "pre-trained" too.

The mapping is direct:

| A person teaching | An LLM |
|---|---|
| Read books, articles, papers on AI | Trained on web pages, books, code, conversations |
| Watched courses, talked to experts | Saw billions of text examples during training |
| Can now generate explanations | Can now generate responses |
| Wasn't born knowing this | Wasn't deployed knowing this |

Both are **generators with prior knowledge** — that's "pre-trained" in a sentence.

### Why this matters
- The model can't generate things wildly outside its training distribution.
- If the training data is biased / outdated / wrong, the outputs reflect that.
- The model has a knowledge **cutoff** — events after that date weren't in the training data.
- "Pre-trained" is what makes the generations **useful and grounded**, not just plausible-sounding noise.

> [!example] What "pre-training" looks like technically
> Pre-training is a process where:
> 1. The model is fed billions to trillions of tokens of text.
> 2. For each chunk, it's asked: *"given these N tokens, what's the most likely next token?"*
> 3. When wrong, its internal weights get nudged via **backpropagation** so it would have predicted better.
> 4. Repeat for **weeks** on **thousands of GPUs**.
>
> The result: a model whose weights encode statistical patterns of how language is structured and used. That's what allows it to be generative *and* coherent.

---

## 6. "Transformer" — the architecture itself

Generative and pre-trained describe the *nature* and *basis* of the LLM. **Transformer** describes the *actual thing* underneath — the neural-network architecture.

### The sports-car analogy

A useful way to separate "nature" from "object": **sports car**. Two words. *Sports* is the nature — the type or flavor of car. *Car* is the actual real object.

Mapping back to GPT:

| Layer | Sports car analogy | GPT analogy |
|---|---|---|
| **The object** | Car | Transformer |
| **The nature** | Sporty | Generative |
| **The basis** | (whatever it was built from) | Pre-trained data |

In other words: a **transformer** that is **generative** in nature, built on the basis of **pre-training**.

The transformer is the **noun**. Generative and pre-trained are **modifiers**.

### What IS a transformer?
A specific neural-network architecture introduced in a 2017 paper by Google researchers — *"Attention Is All You Need."* The full mechanics (self-attention, encoder/decoder layers, positional encodings) are covered in dedicated upcoming notes in this section.

> [!info] Coming next
> The next note deep-dives into the transformer architecture from Google's white paper. For now, the headline: **transformer = the kind of neural network all modern LLMs use.**

---

## 7. The "brilliant naming" insight

The most memorable point: **every modern LLM is technically a "generative pre-trained transformer."** OpenAI just took that literal phrase as the name of their product.

### The car-brand analogy

Imagine a car company named *Audi*. Technically Audi is a car brand, but it's not obvious from the name. Same with BMW, Mercedes — none of those names tell you "this is a car." Now imagine opening a new car company and naming it *Car*. The brand name of the car is literally "Car."

| Brand | What it is |
|---|---|
| Audi, BMW, Mercedes | Cars (but the name doesn't say it) |
| **"Car"** (hypothetical brand) | A car. Trademark the generic word. |

That's exactly what OpenAI did:

| Model | What it is | Branded as |
|---|---|---|
| **Gemini** (Google) | Generative Pre-trained Transformer | "Gemini" |
| **Claude** (Anthropic) | Generative Pre-trained Transformer | "Claude" |
| **Mistral** | Generative Pre-trained Transformer | "Mistral" |
| **Llama** (Meta) | Generative Pre-trained Transformer | "Llama" |
| **GPT** (OpenAI) | Generative Pre-trained Transformer | **"GPT"** ← literal name |

The shoe-brand variant of the analogy: for shoes, there's Adidas, Puma — what if someone opened a new shoe brand and named it *Shoes*?

> [!tip] The point in one line
> Gemini is a GPT. Claude is a GPT. Mistral is a GPT. OpenAI's GPT is also a GPT — but they were the only ones who just **named it that**.

This is part marketing, part technical honesty. The name says exactly what the product is.

---

## 8. Putting it together — the working model so far

After this note, the mental model is:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   User input ──[input tokens]──┐                                │
│                                ▼                                │
│                       ┌────────────────────┐                    │
│                       │   GPT (the LLM)    │                    │
│                       │                    │                    │
│                       │  ┌──────────────┐  │                    │
│                       │  │ Transformer  │  │  ← the architecture │
│                       │  │  (G-P-T's T) │  │                    │
│                       │  └──────────────┘  │                    │
│                       │   generative ←──── nature                │
│                       │   pre-trained ←─── basis                 │
│                       └────────┬───────────┘                    │
│                                ▼                                │
│                          [output tokens]                        │
│                                │                                │
│                                ▼                                │
│                            User reads                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

The "magical responses" are now slightly less magical:
- They're **generated** (not retrieved).
- They're based on **pre-training data** (not random).
- They're produced by a **transformer** (a specific neural-network architecture).

What's still a black box: *how* the transformer actually does this. That's the next note.

---

## 9. Cross-check with [[01 - What is an LLM]]

The previous note already mentioned the G/P/T decomposition briefly. This note goes much deeper. The pieces line up:

| Concept | [[01 - What is an LLM]] | This note (02) |
|---|---|---|
| G/P/T acronym | One-line mention | **Whole note is this** |
| Generative vs. search | Brief note | Deep dive with Google contrast + live test |
| Pre-trained | "First trained on huge generic data" | "Books and articles" self-analogy |
| Transformer | Mentioned as architecture | Set up with sports-car analogy; mechanics still to come |
| Other LLMs are also GPTs | Listed in big-three table | Made explicit with "Car brand named Car" analogy |

---

## 10. Main takeaways

- LLM I/O is technically called **input tokens** and **output tokens**.
- A **token** ≈ a chunk of text (full mechanics come in the tokenization note).
- **GPT = Generative + Pre-trained + Transformer.**
- **Generative**: produces new text (vs. Google, which retrieves existing pages).
- **Pre-trained**: the generation is grounded in prior training data — same way a teacher's explanations are grounded in prior reading.
- **Transformer**: the actual neural-network architecture — the *noun* underneath the modifiers "generative" and "pre-trained."
- Sports-car analogy: "sporty" = nature, "car" = object. Same for GPT: generative = nature, transformer = object.
- **Every modern LLM is technically a GPT** (Gemini, Claude, Mistral, Llama, ...). OpenAI just named theirs the literal generic phrase.
- Brand-name analogy: like a car brand called "Car" or a shoe brand called "Shoes."
- The transformer architecture itself comes from Google's 2017 paper *Attention Is All You Need* — covered next.

---

## 11. Things I still want to figure out

- What's actually happening **inside** the transformer when input tokens become output tokens?
- What does a **token** look like exactly — words? sub-words? bytes?
- How does the transformer decide which token to emit next (sampling? greedy? temperature?)?
- Why is the transformer architecture so much better than what came before (RNNs, LSTMs)?
- What's the **encoder/decoder** distinction in the original transformer paper, and how does GPT differ?
- How are input and output tokens different in cost / mechanics?
- What happens if the input is longer than the context window?

---

## 12. Things to dig into

- **Paper to read**: Vaswani et al., *Attention Is All You Need* (2017) — https://arxiv.org/abs/1706.03762
- **Tokenizer playground**: https://platform.openai.com/tokenizer — paste any text, see how it gets tokenized.
- **Visual transformer explainer**: Jay Alammar, *The Illustrated Transformer* — incomparable intuition builder.
- **Hands-on**: Andrej Karpathy's *"Let's build GPT from scratch"* — implements a tiny GPT in pure PyTorch.

---

## 13. Next up in this section

The next note starts unpacking the *transformer* itself — how it actually produces output:

- [x] [[03 - The Transformer - Predicting the Next Token]] — the autoregressive loop.
- [x] [[04 - What is a Token]] — definitions + tiktoken visualizer.
- [x] [[05 - Coding our Own Tokenizer]] — hands-on Python with tiktoken.
- [x] [[06 - Attention Is All You Need - Architecture Walkthrough]] — the full diagram.
- [x] [[07 - Vector Embeddings]] — meaning as geometry.
- [x] [[08 - Positional Encoding]] — preserving sentence order.
- [x] [[09 - Multi-Head Attention]] — closing the architecture stack.

---

## Related
- [[01 - What is an LLM]] — definitional intro that this note extends.
- [[00 - Types of Memory in LLMs]] — Section 13 preview (memory is a *layer* added on top of these stateless GPTs).

## Sources
- Vaswani et al., *Attention Is All You Need* (2017) — https://arxiv.org/abs/1706.03762
- OpenAI tokenizer playground — https://platform.openai.com/tokenizer
- Jay Alammar, *The Illustrated Transformer*.
