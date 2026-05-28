---
title: Prompt Styles - Section Intro
date: 2026-05-28
source: "Section 4 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 4: Prompt Serialization & Instruction Formats"
tags:
  - prompts
  - prompt-styles
  - chatml
  - alpaca
  - instruction-prompting
  - serialization
  - section-overview
  - foundations
related:
  - "[[02 - What is Prompting]]"
  - "[[01 - Section Intro - Why Prompts Matter]]"
---

# Prompt Styles — Section Intro

> [!abstract] TL;DR
> Prompt **styles** are different from prompt **types**. Section 3 covered *what* to put in a prompt (zero-shot, few-shot, CoT, persona). This section covers *how the prompt is wire-formatted* — the literal text/JSON structure used to feed instructions into the model. Three popular styles: **ChatML** (OpenAI, Gemini, Claude — the de facto standard), **Alpaca** (Llama / Meta-style models), and **Instruction / INST** (Llama 2). For 99% of real work, **ChatML is the only one needed**. This section is bonus context for understanding the broader ecosystem (especially when running local LLMs).

> [!info] Where this fits
> First note of **Section 4: Prompt Serialization & Instruction Formats**. Section 3 was about *what to say* (technique). This section is about *how to say it* (format). After this, **Section 5** (Local LLM Deployment) starts to matter — local LLMs may expect Alpaca or INST format, so knowing they exist is useful.

> [!tip] Treat this section as bonus
> This isn't the only way to give instructions to an LLM — there are several. The point here is to recognize the formats when they show up, not to use them daily.

---

## 1. Styles vs Types — disambiguation

Two different axes:

| Axis | What it controls | Examples |
|---|---|---|
| **Prompt TYPE** (Section 3) | The technique / reasoning pattern | Zero-shot, few-shot, CoT, persona |
| **Prompt STYLE** (this section) | The wire format / structural envelope | ChatML, Alpaca, INST |

They're **orthogonal** — a "few-shot CoT persona" prompt can be written in any of the three styles. Same content, different on-the-wire shape.

---

## 2. Why styles exist at all

Different models were **trained on different prompt formats**. The model expects to see prompts in the same format it saw during fine-tuning. Mismatched format → degraded output (sometimes catastrophic).

| Model family | Native style |
|---|---|
| OpenAI GPT (3.5, 4, 4o, o-series) | **ChatML** |
| Google Gemini | **ChatML** (via OpenAI compat) |
| Anthropic Claude | **ChatML** + XML tags |
| Meta Llama 2 (chat / instruct) | **INST** |
| Stanford Alpaca, Vicuna, many fine-tunes | **Alpaca** |
| Mistral Instruct | **INST** (variant) |
| Hugging Face open models | Varies — usually documented per-model |

When using the **chat completions API** from OpenAI or compatible providers, the SDK handles wire-formatting automatically. When running a **raw local model** (Section 5), the prompt needs to be **manually formatted** in whichever style the model expects.

---

## 3. The three styles covered in this section

| Style | Where it came from | Used by |
|---|---|---|
| **Alpaca** | Stanford's Alpaca instruction-tuning dataset | Llama-derived models, many open fine-tunes |
| **ChatML** | OpenAI for GPT-3.5 / 4 | OpenAI GPT, Gemini, Claude — the **de facto standard** |
| **Instruction (INST)** | Meta's Llama 2 chat fine-tuning | Llama 2 family, Mistral Instruct |

Each gets its own dedicated note:
- [[02 - Alpaca Prompting]]
- [[03 - ChatML Prompting]]
- [[04 - Instruction (INST) Prompting]]

---

## 4. Why ChatML is "the one that matters" in practice

ChatML is the format actually used in day-to-day work because OpenAI, Gemini, and Claude all speak it. Knowing the `role` / `content` shape is enough to operate across all three. The big tech APIs converged on it, so this is the style to stick with.

Reasons ChatML dominates:

| Factor | Why ChatML wins |
|---|---|
| **API standardization** | Industry has converged on `messages: [{"role":..., "content":...}]` |
| **Frontier-model native** | GPT, Gemini, Claude all use it |
| **Tooling** | LangChain, LlamaIndex, every wrapper supports it first |
| **Local LLMs often translate** | Ollama / vLLM accept ChatML and reformat internally |

So even when running a Llama model locally, the **front door is usually ChatML** — the local server handles the conversion.

---

## 5. What this section is really useful for

| Use case | Why this section helps |
|---|---|
| **Running raw Llama 2 / Mistral locally** | Need to know INST format |
| **Fine-tuning open models** | Training data must match the model's expected style |
| **Reading old LLM tutorials / papers** | Pre-2023 content often uses Alpaca/INST |
| **Debugging weird local-LLM output** | Wrong style → garbled responses; recognizing the issue saves hours |
| **Studying open fine-tunes** | Hugging Face model cards often specify a style |

For 99% of agentic-AI work on hosted APIs, this knowledge is just nice-to-have context.

---

## 6. The three styles at a glance

All three encoding the same prompt — *"You are a coding assistant. Write a Python function to add two numbers."*

### Alpaca
```
### Instruction:
You are a coding assistant.

### Input:
Write a Python function to add two numbers.

### Response:
```

### ChatML
```python
messages = [
    {"role": "system",  "content": "You are a coding assistant."},
    {"role": "user",    "content": "Write a Python function to add two numbers."},
]
```

### Instruction (INST)
```
<s>[INST] <<SYS>>
You are a coding assistant.
<</SYS>>

Write a Python function to add two numbers.
[/INST]
```

Same intent, three very different shapes. Each was designed around a specific model family's training data conventions.

---

## 7. Main takeaways

- **Prompt styles** ≠ **prompt types** — styles are wire formats, types are techniques.
- Three popular styles: **Alpaca**, **ChatML**, **Instruction (INST)**.
- **ChatML is the de facto standard** (OpenAI, Gemini, Claude).
- Styles matter most when:
  - Running **raw local LLMs** (Section 5).
  - **Fine-tuning** open models.
  - Reading **older content** that pre-dates ChatML's dominance.
- For hosted API work, the SDK handles formatting → this section is bonus knowledge.

---

## 8. Things I want to come away with

- Recognize each style on sight in unfamiliar code or model cards.
- Know which style a given open model expects without re-googling.
- Understand why a local LLM might produce gibberish if fed the wrong style.

---

## 9. Next up in this section

- [ ] [[02 - Alpaca Prompting]] — the Llama/Stanford Alpaca format.
- [ ] [[03 - ChatML Prompting]] — the de facto standard.
- [ ] [[04 - Instruction (INST) Prompting]] — the Llama 2 chat format.

---

## Related
- [[02 - What is Prompting]] — system prompts (the *content* this section's *formats* carry).
- [[01 - Section Intro - Why Prompts Matter]] — Section 3 intro.
- [[04 - Using Gemini through OpenAI SDK]] — how the OpenAI ChatML format becomes the universal client API.

## Sources
- Stanford Alpaca project: https://crfm.stanford.edu/2023/03/13/alpaca.html
- OpenAI Chat Completions API docs.
- Meta Llama 2 paper: https://arxiv.org/abs/2307.09288
