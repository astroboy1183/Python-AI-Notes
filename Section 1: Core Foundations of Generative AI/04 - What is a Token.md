---
title: What is a Token
date: 2026-05-28
source: "Section 1 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 1: Core Foundations of Generative AI"
tags:
  - llm
  - tokens
  - tokenization
  - detokenization
  - gpt
  - tiktoken
  - openai
  - gemini
  - byte-pair-encoding
  - bpe
  - foundations
related:
  - "[[01 - What is an LLM]]"
  - "[[02 - How LLMs Work - Decoding GPT]]"
  - "[[03 - The Transformer - Predicting the Next Token]]"
---

# What is a Token?

> [!NOTE]
> **TL;DR**
> A **token** is a chunk of text that's been mapped to a **number** so a computer (and the transformer) can work with it. Computers don't understand letters or words — they understand math. Tokenization is the process of converting human text → list of numbers. **Detokenization** is the reverse — converting the model's output numbers back into readable text. Every LLM has its own tokenizer; GPT-4o, Gemini, and Claude all break the same sentence into different tokens. Tokens aren't always whole words — they're often **sub-word chunks** (e.g., `"Piyush"` might split into `P`, `iy`, `ush`). The transformer never sees text directly; it sees numbers, predicts the next number, and then those numbers get decoded back to text for the user.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 1: Core Foundations of Generative AI**. The previous note ([[03 - The Transformer - Predicting the Next Token]]) explained that the transformer predicts "the next token" in a loop. This note answers the dangling question: *what IS a token?* The next note ([[05 - Coding our Own Tokenizer]]) makes this concrete with Python code using `tiktoken`.

---

## 1. Why tokens exist at all

> **Computers are good at math. They're not good at letters.**

Writing `dog` gives three letters humans understand. But a neural network is just a bunch of matrix multiplications — it needs **numbers** to operate on.

So the very first step of any LLM pipeline is to **convert text into numbers**. Those numbers are called **tokens**.

```
"hey there"  ──[tokenizer]──→  [9220, 1009]  ──→  [transformer]
```

> [!TIP]
> **Mental model**
> A token is a chunk of text that has a **unique ID number** in the model's vocabulary. The model thinks in IDs, not in strings.

---

## 2. The simplest mental model — letter = token

A deliberately oversimplified version helps build intuition:

> Imagine: every letter is a token.

| Letter | Token ID |
|---|---|
| A | 1 |
| B | 2 |
| C | 3 |
| D | 4 |
| E | 5 |

So typing `BDE` would become tokens `[2, 4, 5]`.

Then, feeding `[1, 2, 3]` (= `ABC`) to a transformer, it might predict `4` (= `D`). Feeding `[1, 2, 3, 4]` next, it might predict `5` (= `E`). The transformer is doing the same next-token prediction explored in the previous note — just in the world of numbers.

> [!WARNING]
> **This isn't how it really works**
> Real tokenization is **much** more sophisticated than letter-by-letter. This is only a teaching device.

---

## 3. How tokenization REALLY works

In practice, every modern LLM uses **sub-word tokenization** — chunks bigger than a letter, often smaller than a word. The exact algorithm varies (BPE, WordPiece, SentencePiece), but the idea is similar:

- Common words → single token (e.g., `"the"` = 1 token)
- Rare or compound words → multiple sub-word tokens (e.g., `"unbelievable"` might split to `un` + `believable`)
- Punctuation, spaces, special chars → their own tokens
- **Special tokens** mark the start/end of sequences, roles (`user`, `assistant`), etc.

> [!NOTE]
> **Byte-Pair Encoding (BPE)**
> OpenAI and most modern LLMs use a variant of **BPE (Byte-Pair Encoding)**. The high-level idea:
> 1. Start with every individual byte/character as a token.
> 2. Find the most common adjacent pair → merge it into a new token.
> 3. Repeat until the desired vocabulary size is reached (~50k–200k tokens).
>
> The result: a vocabulary that's a mix of whole common words (`the`, `and`, `is`), common prefixes/suffixes (`un-`, `-ing`), and rare-word fallback chunks. It handles any text — including made-up words, code, and other languages — without an "unknown token" problem.

---

## 4. Every model has its own tokenizer

Tokens in reality are different from model to model. The GPT-4 tokenizer is different from Gemini's, which is different from Claude's. Even GPT-3.5's tokens are different from GPT-4's.

That means:
- `"hey there, my name is Jayanth"` → produces **different token sequences** in GPT-4o vs Gemini vs Claude.
- A note tokenized for one model can't be fed directly to another.
- Token counts vary across models (affects pricing + context window utilization).

| Model | Tokenizer family |
|---|---|
| GPT-3.5 | `cl100k_base` |
| GPT-4 / GPT-4o | `o200k_base` (newer, ~200k vocab) |
| Gemini | Google's SentencePiece |
| Claude | Anthropic's BPE variant |
| Llama 3 | TikToken-style (modified) |

---

## 5. Visualizing tokenization — the `tiktoken` website

A live visualizer is the easiest way to see how text gets broken up. Tokens are color-highlighted, with their numeric IDs displayed.

Example walkthrough: typing `"hey there, my name is Jayanth"` into the **GPT-4o tokenizer** view produces something like:

| Position | Token text | Token ID | Notes |
|---|---|---|---|
| 0 | `<\|im_start\|>` | 200264 | Special "start of message" token |
| 1 | `user` | 1428 | Role marker |
| 2 | `hey` | 25216 | Common word as one token |
| 3 | ` there` | 3274 | Note the leading space — it's part of the token |
| 4 | `,` | … | Punctuation token |
| 5 | ` my name is` | … | Could be one or multiple tokens |
| 6 | ` J` | … | The word `Jayanth` splits into sub-pieces |
| 7 | `ay` | … | … |
| 8 | `anth` | … | … |
| n | `<\|im_end\|>` | … | "End of message" marker |
| n+1 | `assistant` | … | Where the model is expected to reply |

> [!NOTE]
> **Surprising fact**
> The **leading space** is usually part of the next token. ` there` (with space) is a different token from `there` (without). This makes tokenization more compact for typical English text where words are space-separated.

> [!TIP]
> **Try it**
> `tiktokenizer` web app: paste any text, pick a model, see the live tokenization.
> URL: https://platform.openai.com/tokenizer (for OpenAI models specifically).

---

## 6. The full pipeline — tokenize → predict → detokenize

Putting tokens back into the bigger picture of how an LLM responds:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│  1. User types:  "hey there"                                    │
│                                                                 │
│  2. TOKENIZATION: text → numbers                                │
│     "hey there" → [25216, 3274]                                 │
│                                                                 │
│  3. Numbers fed to transformer                                  │
│                                                                 │
│  4. Transformer predicts next token (number)                    │
│     [25216, 3274] → 40   (where 40 might decode to "I")         │
│                                                                 │
│  5. Append, loop:                                               │
│     [25216, 3274, 40] → 939   (might decode to " am")           │
│     [25216, 3274, 40, 939] → 1695   (might decode to " good")   │
│     [..., 1695] → <end>                                         │
│                                                                 │
│  6. DETOKENIZATION: numbers → text                              │
│     [40, 939, 1695] → "I am good"                               │
│                                                                 │
│  7. Display to user:  "I am good"                               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

Whenever something is typed into ChatGPT — *"hey there"* — that string doesn't go directly to the LLM. It first gets converted into numbers (tokens). Those tokens are sent to the LLM, which predicts the next token. The loop repeats. Eventually there's a big list of predicted numbers, which then get **detokenized** back into English.

Two definitions to lock in:

| Term | Meaning |
|---|---|
| **Tokenization** | Converting human-readable text → numeric token IDs the model can process. |
| **Detokenization** | The reverse — converting the model's predicted token IDs back into human-readable text. |

---

## 7. Why tokens (not characters, not words)

| Approach | Pros | Cons |
|---|---|---|
| **Character-level** | Tiny vocabulary; handles any text | Sequences become extremely long; semantics are hard to learn at char level |
| **Word-level** | Each token has clear meaning | Vocabulary explodes; can't handle rare or made-up words; whitespace handling is awkward |
| **Sub-word (tokens)** | Compromise: medium vocabulary, compact sequences, handles any input via fallback chunks | The boundaries don't always match human intuition (e.g., `Jayanth` splits weirdly) |

Sub-word tokenization (BPE, etc.) won out because it has the best **size vs. coverage** trade-off. That's why every modern LLM uses something in this family.

---

## 8. Practical implications

### Pricing
LLM APIs charge **per token** — both input and output. So token count matters for cost:
- GPT-4o input: ~$2.50 per million tokens
- GPT-4o output: ~$10 per million tokens
- A single "Hello world" reply might be ~5 tokens.
- A 4000-word essay might be ~5000 tokens.

### Context window
LLM context windows are measured in tokens, not characters:
- GPT-4o: ~128,000 tokens (~96k English words).
- Claude 3.5: ~200,000 tokens.
- Gemini 1.5 Pro: up to 1,000,000 tokens.

### Languages
- English is **token-efficient** — typical ratio ~0.75 tokens per word.
- Non-English text (Hindi, Chinese, Arabic) usually takes **2–3× more tokens** per character because OpenAI's tokenizer was English-optimized.
- Code is mid-range.

### Common gotcha
Token boundaries can split words in surprising ways. The model handles it fine, but copy-pasting a token slice from one place to another may not produce a complete word.

---

## 9. Mental model after this note

The LLM pipeline now looks like:

```
                   ┌──── tokenization ────┐
   user text  ─→   │  text → token IDs    │  ─→  numeric sequence
                   └──────────────────────┘
                                                          │
                                                          ▼
                                                ┌─────────────────┐
                                                │   TRANSFORMER   │
                                                │  (next token    │
                                                │   prediction    │
                                                │   loop)         │
                                                └─────────────────┘
                                                          │
                                                          ▼
                   ┌── detokenization ────┐
   reply text ←─   │  token IDs → text    │  ←─  predicted numeric sequence
                   └──────────────────────┘
```

Every "token" mentioned in [[03 - The Transformer - Predicting the Next Token]] is now concretely defined: it's an entry in a numeric vocabulary the tokenizer maintains.

---

## 10. Main takeaways

- A **token** = a chunk of text mapped to a **unique number** in the model's vocabulary.
- Computers do math, not letters → text must be **tokenized** before the transformer can read it.
- Tokenization is usually **sub-word**, not letter-by-letter and not whole-word.
- Common words = single token; rare/compound words = multiple tokens.
- The leading **space** is usually part of the token (` there` ≠ `there`).
- Special tokens mark message boundaries, roles, system prompts.
- Every model has its **own** tokenizer — GPT-4o, Gemini, Claude all tokenize differently.
- Pipeline: **tokenize → predict next token (loop) → detokenize → show to user.**
- Token counts drive **pricing** and **context window** limits.
- Non-English text typically takes **more tokens** per character with OpenAI's tokenizer.

---

## 11. Things I still want to figure out

- What exactly is the BPE algorithm — the merge process during tokenizer training?
- Why is the leading space part of the token, not a separate token?
- Why does the same word sometimes tokenize differently depending on context?
- Can a single Unicode character ever span multiple tokens? (Likely yes — emojis, rare CJK chars.)
- How do tokenizers handle truly novel strings (made-up brand names, gibberish)?
- What's `cl100k_base` vs `o200k_base` — and why did OpenAI move to a larger vocab?
- How big is the vocabulary for Llama 3, Gemini, Claude?

---

## 12. Things to dig into

- **Live tokenizer demos**:
  - https://platform.openai.com/tokenizer — official OpenAI tokenizer playground.
  - `tiktokenizer` web app — shows tokens with color highlighting and IDs.
- **Library**: `tiktoken` (Python, MIT) — the actual tokenizer OpenAI uses, open-sourced. Covered in the next note.
- **BPE explainer**: search *"Byte-Pair Encoding tokenization explained"* — many great visual guides.
- **Paper**: Sennrich et al., *Neural Machine Translation of Rare Words with Subword Units* (2016) — introduced BPE for NLP.

---

## 13. Next up in this section

The next note makes this hands-on by writing a Python tokenizer using OpenAI's library:

- [ ] [[05 - Coding our Own Tokenizer]] — `pip install tiktoken`, encode + decode in code.

After that:

- [ ] [[06 - Attention Is All You Need - Architecture Walkthrough]]
- [ ] [[07 - Vector Embeddings]]
- [ ] [[08 - Positional Encoding]]
- [ ] [[09 - Multi-Head Attention]]

---

## Related
- [[01 - What is an LLM]] — definitional intro.
- [[02 - How LLMs Work - Decoding GPT]] — the GPT acronym.
- [[03 - The Transformer - Predicting the Next Token]] — the loop that consumes tokens and predicts them.

## Sources
- Sennrich et al., *Neural Machine Translation of Rare Words with Subword Units* (2016) — introduced BPE for NLP.
- OpenAI tokenizer playground — https://platform.openai.com/tokenizer
- `tiktoken` repo — https://github.com/openai/tiktoken
