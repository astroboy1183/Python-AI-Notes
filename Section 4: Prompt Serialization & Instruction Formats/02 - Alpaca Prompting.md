---
title: Alpaca Prompting
date: 2026-05-28
source: "Section 4 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 4: Prompt Serialization & Instruction Formats"
tags:
  - prompts
  - alpaca
  - prompt-style
  - llama
  - meta
  - stanford-alpaca
  - instruction-tuning
  - open-source
  - foundations
related:
  - "[[01 - Prompt Styles - Section Intro]]"
  - "[[03 - ChatML Prompting]]"
---

# Alpaca Prompting

> [!NOTE]
> **TL;DR**
> **Alpaca prompting** is a plain-text format with three named sections separated by `###` headers: **`### Instruction:`**, **`### Input:`**, **`### Response:`**. The model is fed everything up to and including `### Response:` and is expected to **complete the text from there**. Born from Stanford's **Alpaca** project (2023) which used this format to fine-tune Llama into an instruction-following model on a $600 budget. Still used by many Llama-derived open-source fine-tunes. Simpler than ChatML, doesn't natively support multi-turn conversations, weak separation between "what to do" and "what to do it on."

> [!NOTE]
> **Where this fits**
> Second note of **Section 4: Prompt Serialization & Instruction Formats**. The first of three prompt styles. Worth knowing for context — many Hugging Face open models reference this format, and most pre-2024 LLM tutorials assumed it. Not used by frontier hosted APIs (which use ChatML — see [[03 - ChatML Prompting]]).

---

## 1. Where Alpaca came from

In March 2023, **Stanford researchers** released the [Alpaca paper / project](https://crfm.stanford.edu/2023/03/13/alpaca.html). The story:
- Take Meta's **Llama 7B** base model (not instruction-tuned).
- Generate **52,000 instruction/response pairs** using OpenAI's `text-davinci-003`.
- Fine-tune Llama on those pairs.
- Result: a model that follows instructions surprisingly well, for ~$600 total cost.

The format Stanford used for the training data — `### Instruction:` / `### Input:` / `### Response:` — became known as the **Alpaca format**. Many subsequent open-source fine-tunes adopted the same format because:
- Stanford's training-data pipeline (Self-Instruct) was open-sourced.
- The format is dead-simple to parse.
- Re-using it lets fine-tuned models inherit Alpaca's instruction-following behavior.

---

## 2. The format

```
### Instruction:
<<<what the model should do>>>

### Input:
<<<the actual input data — optional>>>

### Response:
<<<model fills in from here>>>
```

Three named sections, each prefixed with three hashes. Blank line between sections. The `### Response:` line is at the end of the prompt; the model is expected to **continue the text** after it.

### Notes on each section

| Section | Role | Required? |
|---|---|---|
| `### Instruction:` | The task / system prompt / what to do | ✅ Yes |
| `### Input:` | The data to operate on / user query | Optional |
| `### Response:` | Where the model's output begins | ✅ Yes (the model writes after it) |

The `### Input:` section is sometimes omitted when the instruction is self-contained.

---

## 3. Example

### Without input section

```
### Instruction:
Write a Python function to add two numbers.

### Response:
```

The model completes after `### Response:` with a Python function.

### With input section

```
### Instruction:
You are a coding assistant. Answer the user's question.

### Input:
Write a Python function to add two numbers.

### Response:
```

Here the **Instruction** is the system prompt and **Input** is the user query.

### With a longer system prompt + chain of thought

```
### Instruction:
You are an AI expert assistant. Your task is to solve user queries
using chain-of-thought reasoning. Plan multiple steps before
producing the final answer.

### Input:
Hey, write a code to add N numbers in JavaScript.

### Response:
```

The model continues from `### Response:` and emits the CoT plan + final code.

---

## 4. ChatML → Alpaca conversion

Take a ChatML prompt and convert it to Alpaca:

**ChatML:**
```python
messages = [
    {"role": "system", "content": "You are a coding assistant. Answer the user's question."},
    {"role": "user",   "content": "Write a code to add N numbers in JavaScript."},
]
```

**Equivalent Alpaca:**
```
### Instruction:
You are a coding assistant. Answer the user's question.

### Input:
Write a code to add N numbers in JavaScript.

### Response:
```

Same intent, different envelope. The mapping:

| ChatML | Alpaca |
|---|---|
| `role: system` | `### Instruction:` |
| `role: user` | `### Input:` |
| `role: assistant` | `### Response:` |

---

## 5. Strengths and weaknesses

### Strengths
- **Dead simple** — plain text, no escaping concerns.
- **Easy to parse and generate** — just string concatenation.
- **Direct mapping to training data** — what the model was trained on.
- **Compact** — minimal overhead per prompt.

### Weaknesses

| Issue | Why it matters |
|---|---|
| **No native multi-turn** | Alpaca was designed for single-turn instruction-response. Conversations require kludgy concatenation. |
| **Weak instruction/input separation** | The line between "system rules" and "user data" is fuzzy. |
| **No turn boundaries** | Hard to distinguish past turns from current turn. |
| **No structured roles** | `user` vs `assistant` distinction must be inferred from `### Response:` markers. |
| **Streaming is awkward** | The model just continues text — harder to know when one "turn" ends. |

These limitations are why ChatML became dominant for chat applications. Alpaca format is fine for **single-shot instruction following**, less good for **multi-turn conversations**.

---

## 6. Where Alpaca is still seen today

| Where | Why |
|---|---|
| **Hugging Face open-model fine-tunes** | Many community models keep Alpaca format for compatibility. |
| **Pre-2024 LLM tutorials / books** | Most early instruction-tuned model material used it. |
| **Local LLM tooling** | Some `llama.cpp` flow examples assume Alpaca. |
| **Instruction-tuning datasets** | Released-as-Alpaca datasets are still being used for fine-tuning. |

In **2024+ production work**, almost everything has moved to ChatML or a chat-template equivalent.

---

## 7. Multi-turn Alpaca (when it's needed)

If forced to use Alpaca for multi-turn (rare in practice), one convention is to **concatenate previous turns**:

```
### Instruction:
You are a helpful assistant.

### Input:
User: Hi, what's the weather like in Bangalore today?
Assistant: I don't have access to real-time weather data.
User: Ok then. Tell me a fact about Bangalore.

### Response:
```

But this is **awkward** — the `### Input:` becomes a transcript blob. ChatML's role-tagged messages handle this naturally.

> [!WARNING]
> **Don't actually do this if it's avoidable**
> If multi-turn conversation is needed, switch to ChatML. Alpaca multi-turn is a workaround, not a strength.

---

## 8. Quick recognition guide

Spotted in the wild:

| Visual cue | Style |
|---|---|
| `### Instruction:`, `### Input:`, `### Response:` | **Alpaca** |
| `[INST]`, `[/INST]`, `<<SYS>>` | **INST (Llama 2)** — see [[04 - Instruction (INST) Prompting]] |
| `<|im_start|>`, `<|im_end|>` (in raw text), or `{"role":..., "content":...}` (in code) | **ChatML** — see [[03 - ChatML Prompting]] |

---

## 9. Main takeaways

- **Alpaca format** = three sections: `### Instruction:`, `### Input:`, `### Response:`.
- Comes from Stanford's 2023 Alpaca project that fine-tuned Llama on instruction data.
- Still used by many open-source Llama-derived fine-tunes.
- Simple and clean for **single-shot** instruction tasks.
- **Weak at multi-turn conversations** — that's why ChatML dominates chat use cases.
- Direct mapping from ChatML: `system → Instruction`, `user → Input`, `assistant → Response`.
- Practical relevance: knowing it on sight when reading model cards or older tutorials.

---

## 10. Things I still want to figure out

- For Llama-derived models accessed via Hugging Face `transformers`, does the **chat template** handle Alpaca formatting automatically?
- What happens if Alpaca-trained model is fed ChatML format — gibberish, or degraded but workable?
- Are there formal Alpaca-style multi-turn extensions, or is concatenation the only option?
- How does Stanford's `Self-Instruct` data-generation pipeline produce the Alpaca-format pairs?
- What's the modern equivalent — instruction datasets in ChatML format?

---

## 11. Things to dig into

- **Original Alpaca blog post**: https://crfm.stanford.edu/2023/03/13/alpaca.html
- **Alpaca GitHub**: https://github.com/tatsu-lab/stanford_alpaca
- **Hands-on**: load a Llama-derived Alpaca-fine-tuned model via `transformers`, see what its chat template emits.
- **Compare**: feed the same prompt in Alpaca vs ChatML format to the same model. Note quality differences.

---

## 12. Next up in this section

- [ ] [[03 - ChatML Prompting]] — the format we already use; what makes it special.

---

## Related
- [[01 - Prompt Styles - Section Intro]] — section intro.
- [[03 - ChatML Prompting]] — sibling style (the dominant one).
- [[04 - Instruction (INST) Prompting]] — sibling style (Llama 2).

## Sources
- Stanford Alpaca blog post: https://crfm.stanford.edu/2023/03/13/alpaca.html
- Stanford Alpaca GitHub: https://github.com/tatsu-lab/stanford_alpaca
