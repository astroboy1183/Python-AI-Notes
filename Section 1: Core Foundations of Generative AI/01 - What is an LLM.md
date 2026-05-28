---
title: What is an LLM
date: 2026-05-28
source: "Section 1 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 1: Core Foundations of Generative AI"
tags:
  - llm
  - large-language-model
  - generative-ai
  - foundations
  - chatgpt
  - gpt
  - gemini
  - claude
  - natural-language
  - openai
  - google
  - anthropic
  - ai-history
  - transformer
related: []
---

# What is an LLM?

> [!abstract] TL;DR
> **LLM = Large Language Model.** A statistical model trained on massive amounts of human text (the open web, books, code, social media) that learns to do two things really well: **understand natural language input** and **generate natural language output**. Everything modern in AI — ChatGPT, Gemini, Claude, agentic AI, RAG, prompt engineering, AI agents — is built on top of LLMs as the foundational layer. This first note stays definitional; the internals (tokens, embeddings, attention, transformers) are covered in later notes of this section.

> [!info] Where this fits
> First note of **Section 1: Core Foundations of Generative AI**. The section progression:
> 1. **What an LLM is** (this note — the *what*)
> 2. **How LLMs work internally** (the *how* — tokens, embeddings, generation)
> 3. **Vector embeddings**
> 4. **Tokenization**
> 5. **"Attention Is All You Need"** (Vaswani et al., 2017) — the transformer paper that started it all
>
> Everything in later sections of the course (agents, RAG, memory, MCP, LangGraph) rests on this foundation.

---

## 1. The definition

> **LLM = Large Language Model**

| Word | What it means |
|---|---|
| **Large** | Hundreds of millions to **trillions** of *parameters* (the numerical weights inside the model). Trained on **huge** datasets — hundreds of gigabytes to multiple petabytes of text. |
| **Language** | Inputs and outputs are **natural language** (English, Hindi, code, math, JSON, etc.) — not structured queries, not opcodes, just text. |
| **Model** | A mathematical/statistical system whose internal numbers were *learned* from data, not hand-coded by a programmer. |

One-sentence framing: **an LLM is a very large statistical text-prediction system that accepts plain language as input.**

> [!example] What "large" really means
> Scale comparison (parameter counts as of mid-2020s):
>
> | Era | Representative model | Parameters | Year |
> |---|---|---|---|
> | Pre-LLM | Original Transformer | ~65M | 2017 |
> | Early LLM | GPT-2 | 1.5B | 2019 |
> | Breakthrough | GPT-3 | 175B | 2020 |
> | Modern | GPT-4 (estimated) | ~1.7T (mixture of experts) | 2023 |
> | Modern | Llama 3.1 | up to 405B | 2024 |
>
> The "large" in LLM isn't marketing — these models really are orders of magnitude bigger than anything that existed before 2017.

---

## 2. The core capability — two jobs

An LLM does **exactly two things**, and everything else is a wrapper around them:

### 2.1 Understand natural language input
Sample prompts that would work:
- *"hi"*
- *"What is 2 + 2?"*
- *"Translate this email into French and make it more polite."*
- *"Explain quantum entanglement to a 12-year-old."*

The model **interprets intent** — not just keyword matching.

### 2.2 Generate natural language output
Given that interpretation, it produces a response:
- *"Hey Jayanth, what can I help you with?"*
- *"2 + 2 = 4."*
- The translated, more polite email.
- A child-friendly explanation of entanglement.

> [!tip] Mental model
> An LLM is a **probability machine**. Given a prompt, it predicts *"what's the most likely next word?"* — then the most likely word after that, and so on. The fact that this simple objective produces coherent, useful answers is one of the genuine surprises of the deep-learning era.

---

## 3. The "aha" moment — a quick demo

A simple ChatGPT walkthrough:

| Step | Prompt typed | ChatGPT reply |
|---|---|---|
| 1 | `hi` | *"Hey Jayanth, what can I help you with?"* |
| 2 | `what is 2 + 2?` | *"2 + 2 = 4."* |
| 3 | `what is a large language model?` | A multi-paragraph definition |

The point: **it feels like chatting with a person**. There's no command syntax to memorize. Just normal sentences. The name itself gives it away — *ChatGPT* means *chatting with a GPT*.

---

## 4. Decoding "ChatGPT" — three things in one name

| Part | What it is | Concrete |
|---|---|---|
| **Chat** | The user interface — a conversational web app | `chatgpt.com` |
| **GPT** | The underlying LLM family (Generative Pre-trained Transformer) | GPT-3.5, GPT-4, GPT-4o, etc. |
| **OpenAI** | The company that builds, trains, and operates GPT | `openai.com` |

> [!note]
> **GPT is the model. ChatGPT is the product wrapped around the model.** Same intelligence is accessible via the OpenAI API (no chat UI) — just a different surface.

> [!example] What GPT actually stands for
> - **G** = *Generative* → generates new text (doesn't just classify existing text).
> - **P** = *Pre-trained* → first trained on huge generic data, then fine-tuned for specific tasks.
> - **T** = *Transformer* → the neural-network architecture from the 2017 *Attention Is All You Need* paper.
>
> These three properties together describe nearly every modern frontier LLM (Claude, Gemini, Llama, Mistral, etc. — all are generative, pre-trained, transformer-based, even when not called "GPT").

---

## 5. How LLMs got trained — the high-level take

OpenAI (and every other frontier lab) trains these models on essentially **whole-internet data** — tweets, LinkedIn posts, Facebook posts, blog posts, anything publicly scraped. The classic training corpora include:

| Source | What's in it |
|---|---|
| **Common Crawl** | Open-web scrape — billions of web pages |
| **Wikipedia** | All language editions |
| **Books corpora** | Out-of-copyright + licensed fiction/non-fiction |
| **Code** | GitHub public repos, Stack Overflow |
| **Forums / social** | Reddit, Twitter / X, LinkedIn (where permitted) |
| **News / academic** | Articles, papers, transcripts |

### Two stages of training

> [!example] The modern training pipeline
> Real LLM training has at least two stages:
>
> 1. **Pre-training** — feed the model billions of tokens; train it to predict the next token. Produces a "base model" that knows language patterns but is unfocused.
> 2. **Fine-tuning / Alignment** — further training on curated data + human feedback (RLHF: Reinforcement Learning from Human Feedback) to make the model helpful, harmless, honest, and good at following instructions.
>
> Modern variants add stages like **instruction tuning**, **DPO** (Direct Preference Optimization), and **constitutional AI**. Likely revisited later — for now, the spine is: **train on data → align with humans → ship**.

---

## 6. The big three (and their friends)

The "big three" households names are OpenAI, Google, and Anthropic. Fuller landscape as of 2024–2026:

| Company | Family | Notable models | Strengths |
|---|---|---|---|
| **OpenAI** | GPT, o-series | GPT-3.5, GPT-4, GPT-4o, o1, o3, o3-mini | General-purpose, broad ecosystem |
| **Google DeepMind** | Gemini | Gemini 1.5, 2.0, 2.5, 2.5 Pro, preview models | Long context (1M+ tokens), multimodal |
| **Anthropic** | Claude | Claude 3, Claude 3.5 Sonnet, Claude 4, Sonnet/Opus/Haiku tiers | Reasoning, safety, coding, long replies |
| **Meta** | Llama | Llama 2, Llama 3, Llama 3.1 (405B) | Open-weights — runs locally |
| **Mistral AI** | Mistral, Mixtral | Mistral 7B, Mixtral 8x7B, Large | Efficient European models |
| **Cohere** | Command | Command-R, Command-R+ | Enterprise / RAG-focused |
| **xAI** | Grok | Grok-1, Grok-2 | Open-weights (Grok-1) |
| **DeepSeek** | DeepSeek | DeepSeek-V3, DeepSeek-R1 | Open-weights, strong reasoning |

> [!tip] Axes of difference
> All these LLMs share the same core job — *understand language, generate language* — but differ across:
> - **Training data** they were exposed to
> - **Architecture details** (size, attention variants, mixture-of-experts, etc.)
> - **Context window** (how many tokens of input they can handle)
> - **Capabilities** (text only? code? images? audio? video?)
> - **Speed and cost** per token
> - **Open vs closed weights** (downloadable? runnable locally?)
> - **Alignment style** (cautious vs forthcoming, formal vs casual)

---

## 7. Why "natural language" is such a big deal

This is the **single most important conceptual shift** LLMs deliver.

### 7.1 The "before" world

| Task | What it took (pre-LLM) |
|---|---|
| Get data from a database | Write **SQL**: `SELECT name FROM customers WHERE total_spent > 10000 ORDER BY ...` |
| Do math | Open a calculator or write code: `result = 0.17 * 128` |
| Summarize a document | Build (or buy) a summarization pipeline using extractive/abstractive techniques |
| Translate text | Use a dedicated translation model or API |
| Generate creative writing | Hire a writer or use rule-based templates |
| Classify emails | Train a classifier with labeled examples |

Each task required a **different skill, tool, or specialized model**.

### 7.2 The "after" world

With LLMs, **all of the above collapse into one interface**:

```
Prompt: "Show me the top 10 customers by revenue."
LLM:    "Here's the SQL: SELECT name, SUM(total) FROM ... — and here are the results."

Prompt: "What's a 17% tip on $128?"
LLM:    "$21.76."

Prompt: "Summarize this document in three bullet points."
LLM:    <three bullets>

Prompt: "Translate this email into French and make it more polite."
LLM:    <translated, polite version>
```

> [!tip] The paradigm shift
> Before LLMs: humans learned the machine's language (SQL, Python, regex, ML frameworks).
> After LLMs: the machine learned human language (English, code-switching, ambiguity, intent).
>
> This inversion is the entire reason "AI is everywhere now." Not because AI got smarter overnight — but because the **interface** became something every human already knows how to use.

---

## 8. What an LLM is NOT (common misconceptions)

Worth flagging early — these misunderstandings cause real bugs in projects:

| Misconception | Reality |
|---|---|
| "It's a database that looks things up." | It's a **statistical predictor** — generates likely text rather than retrieving facts. (That's why hallucinations happen.) |
| "It thinks like a human." | Doesn't *think* in any biological sense — predicts probable continuations of text. Whether that constitutes "thinking" is a philosophical debate. |
| "It always tells the truth." | Generates **plausible-sounding** text. Plausibility ≠ truth. Always verify facts. |
| "It learns from each conversation." | Most production LLMs are **frozen** after training. They don't update from chats. (Memory features are a layer *on top* — see [[00 - Types of Memory in LLMs]].) |
| "Bigger is always better." | Not always — task fit, latency, cost, and alignment matter more than raw parameter count. |
| "All LLMs are the same." | They differ wildly in capability, style, cost, context size, and modality. |

> [!warning] Hallucinations
> An LLM will confidently invent plausible-but-false answers — fake citations, made-up APIs, wrong dates. This is a **fundamental property** of the architecture, not a bug to be patched. Reliable systems on top of LLMs require designing around this.

---

## 9. The training-to-use pipeline (mental model)

```
┌──────────────────────────────────────────────────────────────┐
│  PHASE 1: TRAINING (done once, by the model provider)         │
│                                                                │
│   Internet text  →  Tokenization  →  Massive neural network   │
│   (petabytes)        (turn text       (transformer)            │
│                       into numbers)        │                   │
│                                            ▼                   │
│                                    Trained model weights       │
│                                    (hundreds of GB to TBs)     │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼  ship to data centers
┌──────────────────────────────────────────────────────────────┐
│  PHASE 2: INFERENCE (every actual use of the model)           │
│                                                                │
│   Prompt        →  Tokenization  →  Forward pass  →  Tokens   │
│   ("what is        (numbers)        through the      out      │
│    2+2?")                           trained model    │         │
│                                                       ▼         │
│                                              Detokenize → text │
│                                              ("2 + 2 = 4.")   │
└──────────────────────────────────────────────────────────────┘
```

> [!note]
> **Training is rare and expensive** (millions to hundreds of millions of dollars, weeks of GPU time on thousands of GPUs).
> **Inference is the daily-use cost** (a few cents per query at most).
> End-users only ever interact with **Phase 2**.

This pipeline is the spine for the rest of Section 1 — every later lecture (tokenization, embeddings, attention) fills in a box of this diagram.

---

## 10. Brief history

Tracing where LLMs came from:

| Year | Milestone | Significance |
|---|---|---|
| 1950 | **Turing test** proposed | First serious framing of "machine that talks like a human" |
| 1986 | **Backpropagation** popularized | Algorithm for training multi-layer neural nets |
| 2013 | **Word2Vec** (Mikolov et al.) | Words as vectors — embeddings as we know them |
| 2014 | **Seq2seq + attention** (Bahdanau et al.) | Attention mechanism debuts |
| **2017** | **"Attention Is All You Need"** (Vaswani et al.) | The **transformer** — birth of the modern LLM. *Covered later in this section.* |
| 2018 | BERT, GPT-1 | First transformer LMs at scale |
| 2019 | GPT-2 | OpenAI shows scale alone produces shocking text quality |
| 2020 | GPT-3 (175B params) | The scale-up moment — LLMs become useful for general tasks |
| 2022 | **ChatGPT launches** (Nov 30) | Mass adoption begins — 1M users in 5 days |
| 2023 | GPT-4, Claude, Llama 2, Gemini | Multiple frontier players |
| 2024–2026 | Reasoning models (o1, o3), agentic AI, MCP, long context | The era this course covers |

> [!info] The "Attention Is All You Need" paper
> Single 2017 paper (15 pages, 8 authors, Google Brain + UToronto) introduced the **transformer architecture** that powers literally every modern LLM. Covered in detail later in this section. For now, the headline: **2017 = the year LLMs as we know them became possible.**

---

## 11. Why LLMs matter for the rest of this course

Every later section of "Full Stack AI with Python" builds on LLMs:

| Course Section | Why LLMs are foundational |
|---|---|
| Section 2: API Setup & Integration | Talking to LLMs via APIs (OpenAI, Anthropic, Google) |
| Section 3: Advanced Prompt Engineering | Getting better answers out of LLMs |
| Section 4: Prompt Serialization | Structured ways to send/receive LLM I/O |
| Section 5: Local LLM Deployment | Running LLMs on a local machine |
| Section 6: Hugging Face | Open-source LLM ecosystem |
| Section 7: AI Agents | LLMs that take actions, use tools |
| Section 8–9: RAG | LLMs grounded in external data |
| Section 10: Multi-modal Agents | LLMs that see, hear, generate images |
| Section 11–12: LangGraph | Orchestrating LLM workflows |
| Section 13: Memory Layer | Giving LLMs persistent memory (see [[00 - Types of Memory in LLMs]]) |
| Section 14: Graph Memory | Knowledge graphs + LLMs |
| Section 15: Voice agents | LLMs + speech in/out |
| Section 16: MCP | Model Context Protocol — standard way for LLMs to talk to tools |

**Without LLMs, nothing else in this course exists.** That's why this section comes first.

---

## 12. Main takeaways

- **LLM = Large Language Model** — a statistical text predictor trained on massive data.
- Core job: **understand natural language input** → **generate natural language output**.
- Trained on internet-scale data (web, books, code, social, forums).
- **ChatGPT** = chat interface + GPT model + OpenAI brand.
- **GPT** = Generative Pre-trained Transformer (the architecture matters — covered later).
- Major families: **GPT, Gemini, Claude, Llama, Mistral, Command, Grok, DeepSeek**.
- They differ across **training data, size, context window, modality, speed, cost, openness**.
- The paradigm shift: **the machine learned human language** (humans no longer have to learn the machine's).
- **LLMs are not databases** — they hallucinate. Truth requires verification or grounding.
- **Training is rare and expensive; inference is the daily-use action.**
- The whole modern LLM era starts with the **2017 transformer paper**.
- This note stays **definitional** — internals come next.

---

## 13. Things I still want to figure out

- How does an LLM literally generate the next word — what's happening inside the neural network?
- What are **tokens**? Why does the model see them instead of raw characters?
- What are **vector embeddings**? Why map words to numbers?
- What does the **attention mechanism** actually compute?
- What's a **transformer** layer and why does stacking them work so well?
- What's the difference between **pre-training**, **fine-tuning**, and **prompting**?
- How do LLMs deal with **context length** — why is a "1M-token context" a big deal?
- Why do LLMs **hallucinate**, and what mitigates it?
- What's the difference between **base models** and **instruct models**?
- How is LLM "quality" actually measured? (Benchmarks: MMLU, HumanEval, GSM8K, etc.)

---

## 14. Things to dig into

Resources worth coming back to:

- **Paper**: "Attention Is All You Need" (Vaswani et al., 2017) — https://arxiv.org/abs/1706.03762
- **Visual explanation**: Jay Alammar's *"The Illustrated Transformer"* — incomparable for intuition.
- **Hands-on**: Andrej Karpathy's *"Let's build GPT from scratch"* video — implements a mini-LLM in PyTorch.
- **Free book**: Sebastian Raschka, *Build a Large Language Model (From Scratch)*.
- **History**: Stephen Wolfram, *"What Is ChatGPT Doing… and Why Does It Work?"*

---

## 15. Next up in this section

The next note unpacks the *"magic"* of how an LLM turns *"hi"* into *"Hey Jayanth, what can I help you with?"*:

- [ ] [[02 - How LLMs Work Internally]] — what actually happens inside the model

Expected after that:

- [ ] [[03 - Tokenization]]
- [ ] [[04 - Vector Embeddings]]
- [ ] [[05 - Attention Is All You Need]]

---

## Related
- [[00 - Types of Memory in LLMs]] — Section 13 preview (memory is a *layer* added on top of stateless LLMs)
- (more notes will be added as the section progresses)

## Sources
- Vaswani et al., *Attention Is All You Need* (2017) — https://arxiv.org/abs/1706.03762
- Jay Alammar, *The Illustrated Transformer*.
- Sebastian Raschka, *Build a Large Language Model (From Scratch)*.
- Stephen Wolfram, *What Is ChatGPT Doing… and Why Does It Work?*
