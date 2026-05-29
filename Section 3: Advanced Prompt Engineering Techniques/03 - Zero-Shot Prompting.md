---
title: Zero-Shot Prompting
date: 2026-05-28
source: "Section 3 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 3: Advanced Prompt Engineering Techniques"
tags:
  - prompts
  - zero-shot
  - prompt-engineering
  - system-prompt
  - foundations
  - hands-on
related:
  - "[[01 - What is an LLM]]"
  - "[[02 - What is Prompting]]"
  - "[[01 - Section Intro - Why Prompts Matter]]"
---

# Zero-Shot Prompting

> [!NOTE]
> **TL;DR**
> **Zero-shot prompting** = giving the LLM **direct instructions with no examples**. Just tell it what to do in natural language and trust the pre-trained model to figure out the rest. Simplest prompting pattern, lowest token cost, fastest to write. Works surprisingly well for well-defined tasks ("translate to French", "summarize", "extract dates"). Breaks down when the task is ambiguous, format-sensitive, or requires demonstrations of nuance. Worked example: a coding-only assistant named **Alexa** that refuses non-coding questions — built with one system prompt, zero examples.

> [!NOTE]
> **Where this fits**
> Third note of **Section 3: Advanced Prompt Engineering Techniques**. The simplest of the prompting patterns. Sets the baseline — every subsequent pattern (few-shot, structured output, CoT, persona) adds something on top.

---

## 1. The definition

> **Zero-shot prompting:** the model is given a direct question or task **without any prior examples**.

That's it. Just instructions. No "here's what I want, here are 5 examples of how to do it" — just "do this."

### Formal definition

> *"In zero-shot prompting, the model is given a direct question or task without any prior examples."*

---

## 2. The pattern

```python
system_prompt = "<<<direct instructions to the model — no examples>>>"

messages = [
    {"role": "system", "content": system_prompt},
    {"role": "user",   "content": "<<<actual question>>>"},
]

response = client.chat.completions.create(model="gpt-4o", messages=messages)
```

Everything is in the system prompt's **natural-language instructions**. The LLM's pre-trained knowledge fills in the rest.

---

## 3. Worked example — coding-only assistant "Alexa"

`prompts/00_zero_shot.py`:

```python
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()

client = OpenAI(
    # If using Gemini via OpenAI compat:
    # api_key=os.environ["GEMINI_API_KEY"],
    # base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
)

system_prompt = """
You should only and only answer coding related questions.
Do not answer anything else.
Your name is Alexa.
If user asks something other than coding, just say sorry.
"""

response = client.chat.completions.create(
    model="gpt-4o",   # or "gemini-2.5-flash" with compat
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": "Hey, can you tell me a joke?"},
    ],
)

print(response.choices[0].message.content)
```

### Run 1 — non-coding question
```
User:      Hey, can you tell me a joke?
Assistant: Sorry.
```

### Run 2 — translation (still non-coding)
```
User:      Hey, can you translate the word 'hello' to Hindi?
Assistant: Sorry.
```

### Run 3 — coding request
```
User:      Hey, can you write a Python code to translate text?
Assistant: <a working Python translation snippet>
```

This is what zero-shot prompting looks like: a direct instruction ("only answer coding questions; refuse anything else; your name is Alexa"), no examples, thrown straight at the LLM.

The model **inferred** from the instructions alone what to do. No examples of "good question / bad question" needed.

---

## 4. Why zero-shot often works

Modern LLMs are pre-trained on **trillions of tokens** of text. They've seen:
- Millions of code snippets.
- Millions of "instruction → response" pairs from instruction-tuning data.
- Patterns of how to follow natural-language directives.

So when a system prompt says *"only answer coding questions, otherwise say sorry"*, the model doesn't need to be **shown** what that means — it generalizes from its training.

> [!NOTE]
> **When zero-shot is enough**
> Zero-shot is typically sufficient for tasks that are:
> - **Well-defined in plain English** ("translate to X", "summarize", "extract entities").
> - **Common in training data** ("write a Python function for X", "answer this trivia").
> - **Forgiving of variation** (style of summary doesn't matter much).
> - **Single-step** (no complex chained reasoning).
>
> For more specialized or format-sensitive tasks, few-shot ([[04 - Few-Shot Prompting]]) or CoT ([[06 - Chain of Thought Prompting]]) become necessary.

---

## 5. When zero-shot breaks down

Zero-shot starts failing when:

| Failure mode | Example |
|---|---|
| **Ambiguous task** | "Make this professional" — without examples, what does "professional" mean? |
| **Format-sensitive** | "Return JSON" without an example schema → inconsistent JSON shapes. |
| **Edge cases** | "Extract dates" — does "yesterday" count? US vs European format? |
| **Domain-specific** | Legal, medical, niche tech — model may need explicit guidance via examples. |
| **Multi-step reasoning** | Math word problems → zero-shot accuracy drops sharply vs CoT. |
| **Style mimicry** | "Write like Hemingway" — vague description ≠ actual demonstrations. |

For any of these, **adding examples** (few-shot, [[04 - Few-Shot Prompting]]) is usually the fix.

---

## 6. The trade-off table

| Aspect | Zero-shot | (Few-shot for comparison) |
|---|---|---|
| **Tokens used** | Lowest | Higher (examples cost tokens) |
| **Latency** | Fastest | Slower (longer prompt = more processing) |
| **Cost per call** | Lowest | Higher |
| **Time to write** | Seconds | Minutes to hours |
| **Output quality** | Variable | Usually higher |
| **Best for** | Common tasks, prototyping | Specialized tasks, production accuracy |

> [!TIP]
> **Practical advice**
> **Start with zero-shot.** If the output is good enough for the use case, stop there. Only add examples (few-shot) when zero-shot doesn't meet quality requirements. Over-engineering prompts costs tokens, money, and maintenance.

---

## 7. Anti-pattern — zero-shot ambiguity

A common rookie mistake: writing zero-shot prompts that are **too vague**.

### Bad
```
You are a writing assistant. Help users with their writing.
```

### Better
```
You are a writing assistant for software engineers.
- Help with technical blog posts, documentation, and PR descriptions.
- Match the user's tone — formal for docs, casual for blogs.
- Output should be Markdown.
- If the user's request is ambiguous, ask one clarifying question.
- Do NOT help with creative fiction or marketing copy.
```

The better one is **still zero-shot** (no examples), but **specific enough** that the model doesn't have to guess.

> [!WARNING]
> **Don't confuse "zero-shot" with "thin prompt"**
> Zero-shot just means **no examples**. The instructions themselves can (and usually should) be detailed and specific.

---

## 8. Variants of zero-shot

| Variant | What it adds |
|---|---|
| **Plain zero-shot** | Just instructions. |
| **Zero-shot with role** | "You are X" + instructions. (What the Alexa example above does.) |
| **Zero-shot with constraints** | Adds explicit rules like "always JSON" or "max 100 words". |
| **Zero-shot CoT** | Adds "Think step by step" — surprisingly powerful for math/logic. Covered in [[06 - Chain of Thought Prompting]]. |
| **Zero-shot with output format** | "Reply in this JSON format: { … }" without examples. |

These all stay technically zero-shot (no demonstrations), but add **structure** to the instructions.

> [!NOTE]
> **"Think step by step" magic**
> A famous finding: simply adding the phrase **"Let's think step by step"** to a zero-shot prompt can dramatically improve accuracy on math/logic tasks. This is called **zero-shot CoT** (Kojima et al., 2022). The model uses its own internal reasoning capacity better when prompted to. Section 6 deep-dives this idea further.

---

## 9. Code recap — the full file

```python
# prompts/00_zero_shot.py
# Zero-shot prompting: direct instructions, no examples.

from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
client = OpenAI()

system_prompt = """
You should only and only answer coding related questions.
Do not answer anything else.
Your name is Alexa.
If user asks something other than coding, just say sorry.
"""

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": "Hey, can you write a Python code to translate text?"},
    ],
)

print(response.choices[0].message.content)
```

That's the complete pattern. Everything else this section will cover **extends** this skeleton — same `messages` shape, just more sophistication inside the system prompt.

---

## 10. Main takeaways

- **Zero-shot prompting** = direct instructions, no examples.
- The model uses its pre-trained knowledge to figure out the task.
- Simplest, fastest, cheapest prompting pattern.
- Often sufficient for **well-defined, common** tasks (translation, summarization, extraction).
- Breaks down on **ambiguous, format-sensitive, domain-specific, multi-step** tasks — fix with [[04 - Few-Shot Prompting|few-shot]].
- Zero-shot does **not** mean "thin" — instructions should still be specific, with scope and anti-scope.
- The phrase *"Let's think step by step"* turns plain zero-shot into **zero-shot CoT** — cheap accuracy boost.
- **Start with zero-shot.** Only upgrade when needed.

---

## 11. Things I still want to figure out

- How do **reasoning models** (o1, o3, DeepSeek R1) change the zero-shot game? Do they need fewer examples?
- What's the **measured accuracy** difference between zero-shot and few-shot across benchmarks?
- Is there a way to know **a priori** whether a task needs few-shot?
- Can zero-shot ever **beat** few-shot? (Yes, if examples are bad or biased.)
- How does zero-shot interact with **structured outputs / JSON mode**?
- What's the best practice for **iteratively improving** a zero-shot prompt without falling into over-specification?

---

## 12. Things to dig into

- **Paper**: Brown et al., *Language Models are Few-Shot Learners* (2020) — the GPT-3 paper. Where "zero-shot vs few-shot" became a household distinction.
- **Paper**: Kojima et al., *Large Language Models are Zero-Shot Reasoners* (2022) — where "Let's think step by step" was discovered.
- **OpenAI prompt engineering guide**: https://platform.openai.com/docs/guides/prompt-engineering — has good zero-shot examples.
- **Try in Playground**: write 5 zero-shot prompts for different tasks (translation, summarization, code, math, extraction). Note where the LLM struggles. Those struggles are where few-shot will help.

---

## 13. Next up in this section

When zero-shot isn't enough, add examples:

- [ ] [[04 - Few-Shot Prompting]] — concrete I/O examples baked into the prompt.

---

## Related
- [[02 - What is Prompting]] — system prompts in general.
- [[01 - Section Intro - Why Prompts Matter]] — section context.
- [[02 - Using OpenAI API in Python]] — the API call this pattern runs on.

## Sources
- Section 3, Lecture 3 — *"Zero-Shot Prompting"*.
