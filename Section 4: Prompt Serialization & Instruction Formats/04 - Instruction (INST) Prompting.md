---
title: Instruction (INST) Prompting
date: 2026-05-28
source: "Section 4 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 4: Prompt Serialization & Instruction Formats"
tags:
  - prompts
  - inst
  - instruction-prompting
  - prompt-style
  - llama-2
  - meta
  - mistral
  - open-source
  - foundations
related:
  - "[[01 - Prompt Styles - Section Intro]]"
  - "[[02 - Alpaca Prompting]]"
  - "[[03 - ChatML Prompting]]"
---

# Instruction (INST) Prompting

> [!abstract] TL;DR
> **Instruction (INST) prompting** is the prompt format used by **Meta's Llama 2 chat models** (and adopted by Mistral Instruct and others). User instructions are wrapped in `[INST] ... [/INST]` tags. System prompts go inside `<<SYS>> ... <</SYS>>` tags within the first INST block. Sequence boundaries use `<s>` and `</s>` tokens. Compact, model-trained-on-it natively, but **not designed for hosted chat APIs** — it's a raw-prompt format for direct-token-feeding into local Llama 2-style models. Like Alpaca, mostly relevant when running raw local LLMs or fine-tuning open models. Not used by ChatGPT, Gemini, or Claude.

> [!info] Where this fits
> Final note of **Section 4: Prompt Serialization & Instruction Formats**. The third style covered after [[02 - Alpaca Prompting]] and [[03 - ChatML Prompting]]. Closes out Section 4. After this, **Section 5: Local LLM Deployment & API Integration** starts — where knowing this format actually matters in practice (some local Llama 2 setups need raw INST prompts).

---

## 1. Where INST came from

Meta released **Llama 2** in July 2023 with **chat-tuned variants** (Llama-2-7b-chat, 13b-chat, 70b-chat). These chat models were fine-tuned on instruction-response pairs formatted with the **INST template** — bracketed instruction tags that the model learned to recognize as conversation boundaries.

The format became the standard for:
- **Llama 2 chat** family.
- **Mistral Instruct** (slight variant).
- **CodeLlama Instruct**.
- Many community fine-tunes derived from Llama 2.

Llama 3 (mid-2024+) moved to a **new template** (closer to ChatML) — so INST is increasingly historical. Still common in Llama 2-era local-LLM setups.

---

## 2. The format

### Single-turn (no system prompt)

```
<s>[INST] What is the time now? [/INST]
```

| Token | Meaning |
|---|---|
| `<s>` | Beginning-of-sequence (BOS) token |
| `[INST]` | Start of user instruction |
| `[/INST]` | End of user instruction → model continues from here with its reply |

### With a system prompt

```
<s>[INST] <<SYS>>
You are a helpful coding assistant.
<</SYS>>

What is the time now? [/INST]
```

| Token | Meaning |
|---|---|
| `<<SYS>>` | Start of system prompt (only inside the first `[INST]` block) |
| `<</SYS>>` | End of system prompt |

> [!note]
> The system prompt only appears in the **first** `[INST]` block of the conversation. Subsequent turns omit `<<SYS>>...<</SYS>>`.

### Multi-turn

```
<s>[INST] <<SYS>>
You are a helpful coding assistant.
<</SYS>>

How do I reverse a list in Python? [/INST]
Use `my_list[::-1]` or `reversed(my_list)`.</s><s>[INST] Which one is faster? [/INST]
```

Each user turn gets wrapped in `<s>[INST] ... [/INST]`. The model's previous reply ends with `</s>` before the next turn begins.

> [!note] How to read the structure
> Everything sits inside these brace-style tags: `<s>` marks the beginning of the text, `<<SYS>>...<</SYS>>` holds the system prompt, the user input goes inside `[INST]...[/INST]`, and the assistant's reply continues after the closing `[/INST]`.

---

## 3. Example — equivalent prompts in all three styles

Same intent — *"You are a coding assistant. Write a Python function to add two numbers."*

### Alpaca
```
### Instruction:
You are a coding assistant.

### Input:
Write a Python function to add two numbers.

### Response:
```

### ChatML (Python)
```python
messages = [
    {"role": "system", "content": "You are a coding assistant."},
    {"role": "user",   "content": "Write a Python function to add two numbers."},
]
```

### INST
```
<s>[INST] <<SYS>>
You are a coding assistant.
<</SYS>>

Write a Python function to add two numbers. [/INST]
```

Same intent → three very different envelopes. Each was designed around what its target model family was fine-tuned to expect.

---

## 4. ChatML → INST conversion

The mapping:

| ChatML | INST |
|---|---|
| `role: system` | Inside `<<SYS>>...<</SYS>>` |
| First `role: user` | After `<<SYS>>...<</SYS>>` inside `[INST]...[/INST]` |
| Subsequent `role: user` | Wrapped in `<s>[INST]...[/INST]` |
| `role: assistant` | Plain text between `[/INST]` and `</s>` |

### A multi-turn ChatML
```python
[
    {"role": "system",    "content": "You are a coding assistant."},
    {"role": "user",      "content": "How do I reverse a list?"},
    {"role": "assistant", "content": "Use `my_list[::-1]`."},
    {"role": "user",      "content": "Which is faster?"},
]
```

### Equivalent INST
```
<s>[INST] <<SYS>>
You are a coding assistant.
<</SYS>>

How do I reverse a list? [/INST] Use `my_list[::-1]`.</s><s>[INST] Which is faster? [/INST]
```

Notice how `<s>` and `</s>` mark **sequence boundaries** between turns.

---

## 5. Strengths and weaknesses

### Strengths
- **Native to Llama 2 chat** — the format the model was actually trained on.
- **Token-efficient** for the model's tokenizer (special tokens are single-token).
- **Clean separation** of system from user using `<<SYS>>` tags.
- **Compact** — fewer "wasted" tokens than ChatML's `<|im_start|>` delimiters for single-turn.

### Weaknesses

| Issue | Why it matters |
|---|---|
| **Llama 2-specific** | Not adopted by GPT, Gemini, Claude. |
| **Manual formatting** | Easy to get whitespace, BOS tokens, or `<<SYS>>` placement wrong. |
| **Multi-turn is awkward** | Need to manually insert `</s><s>[INST]` between turns. |
| **No tool-call support** | Designed before agent / tool patterns became common. |
| **Superseded in Llama 3** | Meta moved Llama 3 to a ChatML-like format. |
| **Brittle parsing** | Slight whitespace differences can confuse the model. |

For modern work, INST is a **historical / local-model-specific** thing.

---

## 6. Mistral Instruct variation

Mistral's Instruct format is **similar but not identical**:

```
<s>[INST] What is the time now? [/INST]
```

No `<<SYS>>` — Mistral's recommended pattern is to **prepend** the system prompt to the first user message:

```
<s>[INST] You are a helpful assistant.

What is the time now? [/INST]
```

> [!warning] Don't mix Llama 2 and Mistral formats
> Both use `[INST]` tags, but the system-prompt handling differs. A Llama 2-style `<<SYS>>` block fed to Mistral may degrade quality (and vice versa).

---

## 7. Practical relevance today

| Situation | Need to know INST? |
|---|---|
| Calling OpenAI / Gemini / Claude APIs | ❌ No |
| Calling Llama 3 / Llama 4 via API | ❌ No (they use ChatML-like) |
| Running Llama 2 chat locally with raw token feeding | ✅ Yes |
| Using Llama 2 via Ollama / vLLM / `text-generation-inference` | ❌ The server abstracts it |
| Fine-tuning Llama 2 on custom data | ✅ Training data must use INST |
| Reading old Llama 2 tutorials | ✅ Helps |
| Using Mistral Instruct directly | ✅ (slight variant) |

The local-LLM tooling (Ollama, vLLM, llama-cpp-python) typically **handles INST formatting internally** when given a ChatML-style message list — so even when running local Llama 2, the application code can usually stay in ChatML.

---

## 8. Quick recognition guide

| Visual cue | Style |
|---|---|
| `[INST]`, `[/INST]`, `<<SYS>>`, `<</SYS>>`, `<s>`, `</s>` | **INST (Llama 2)** |
| `### Instruction:`, `### Input:`, `### Response:` | **Alpaca** |
| `messages=[{"role":..., "content":...}]` or `<|im_start|>` tokens | **ChatML** |

Seeing `<s>[INST]` in code? It's INST format being constructed manually for a Llama 2 / Mistral local model.

---

## 9. End of Section 4

This closes out **Section 4: Prompt Serialization & Instruction Formats**:

| Note | Topic |
|---|---|
| 01 | Section Intro — Prompt Styles |
| 02 | Alpaca Prompting |
| 03 | ChatML Prompting (the one that matters) |
| 04 | Instruction (INST) Prompting (this note) |

**Next**: Section 5 — **Local LLM Deployment & API Integration**. Where the formats just covered become real: running Llama / Mistral models on the local machine and choosing how to feed prompts in.

---

## 10. Main takeaways

- **INST format** = `[INST] ... [/INST]` tags around user instructions, `<<SYS>> ... <</SYS>>` for system prompt.
- Used by **Llama 2 chat** and **Mistral Instruct** (with small differences).
- Sequence boundaries marked by `<s>` (BOS) and `</s>` (EOS) tokens.
- System prompt only inside the **first** `[INST]` block.
- **Llama 3+ moved to ChatML-style** — INST is increasingly historical.
- Knowing INST matters when:
  - Running raw Llama 2 / Mistral locally.
  - Fine-tuning open models.
  - Reading older tutorials.
- Modern local-LLM tooling typically handles INST formatting internally — app code stays in ChatML.

---

## 11. Things I still want to figure out

- What's the **exact** Llama 3 format and how does it compare to ChatML?
- For Hugging Face `transformers`, does `tokenizer.apply_chat_template(...)` handle INST → tokens automatically?
- How does the Llama 2 model behave if fed ChatML vs INST? Soft degradation or hard failure?
- What's the role of the **BOS token** `<s>` — special-cased by the tokenizer, or just plain text?
- How does Mistral's Instruct format differ in subtler ways (whitespace, newlines)?
- For fine-tuning, does using INST format on a base Llama 2 model match the chat-tuned variant's behavior?

---

## 12. Things to dig into

- **Llama 2 paper** (Meta, 2023): https://arxiv.org/abs/2307.09288 — original INST format spec.
- **Hugging Face chat templates**: https://huggingface.co/docs/transformers/main/en/chat_templating — how `transformers` auto-applies the right format per model.
- **Llama 3 prompt format**: search for "Llama 3 chat template" for the modern replacement.
- **Hands-on**: load Llama-2-7b-chat via `transformers` and call `tokenizer.apply_chat_template(messages, tokenize=False)` — see what it emits.

---

## 13. Next up

End of Section 4. Next:

- [ ] **Section 5: Local LLM Deployment & API Integration** — running Llama / Mistral on the local machine and the OpenAI-compat layer that abstracts these prompt formats away.

---

## Related
- [[01 - Prompt Styles - Section Intro]] — section intro.
- [[02 - Alpaca Prompting]] — sibling style.
- [[03 - ChatML Prompting]] — sibling style (the dominant one).
- [[04 - Using Gemini through OpenAI SDK]] — the `base_url` trick that also bridges local-LLM endpoints.

## Sources
- Llama 2 paper: https://arxiv.org/abs/2307.09288
- Hugging Face chat templating docs: https://huggingface.co/docs/transformers/main/en/chat_templating
