---
title: What is Prompting (System Prompts)
date: 2026-05-28
source: "Section 3 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 3: Advanced Prompt Engineering Techniques"
tags:
  - prompts
  - system-prompt
  - prompt-engineering
  - context
  - foundations
  - hands-on
related:
  - "[[01 - What is an LLM]]"
  - "[[02 - Using OpenAI API in Python]]"
  - "[[01 - Section Intro - Why Prompts Matter]]"
---

# What is Prompting (System Prompts)

> [!abstract] TL;DR
> A **prompt** is anything fed to the LLM as input. The most important kind is the **system prompt** — a special first message in the `messages` list, with `role: "system"`, that sets the LLM's **context, persona, constraints, and rules** for the rest of the conversation. Without a system prompt, the LLM is a free-flowing chatbot that will answer anything. With a good system prompt, it becomes a focused, controlled assistant (e.g., "you are a math expert; reject anything non-math"). Quality of the system prompt is one of the biggest levers on output quality.

> [!info] Where this fits
> Second note of **Section 3: Advanced Prompt Engineering Techniques**. Builds directly on [[02 - Using OpenAI API in Python]] where the `messages` list was introduced with just a `user` role. This note adds the `system` role and shows why it matters. Everything in the rest of the section (zero-shot, few-shot, CoT, persona) is **a particular way to write a system prompt**.

---

## 1. The default — no system prompt

The minimal API call from [[02 - Using OpenAI API in Python]]:

```python
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "user", "content": "Hey, I am Jayanth. Who are you?"}
    ],
)
```

What happens: a **free-flowing conversation**. The LLM answers as a generic assistant. With no context, it will happily handle:
- Math questions
- Science questions
- Tell-me-a-joke requests
- Code requests
- Personal advice
- Whatever else

The issue: without context, the model will happily answer science questions, AI questions, math questions, even tell jokes. I want to **bind it** — give it context so it stays on task.

For a **toy chatbot**, that's fine. For anything real — a customer-support assistant, a coding tutor, a medical-info bot — it's a problem. There's no control.

---

## 2. The fix — system prompts

A **system prompt** is a message at the beginning of `messages` with `role="system"`. It tells the LLM **how to behave** for the rest of the conversation.

### The schema

```python
messages = [
    {"role": "system", "content": "<<<the rules / context / persona>>>"},
    {"role": "user",   "content": "<<<the user's actual question>>>"},
]
```

### Concrete example (math-only assistant)

```python
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
client = OpenAI()

system_prompt = "You are an expert in maths and only answer maths related questions."

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": "Hey, I am Jayanth. Who are you?"},
    ],
)

print(response.choices[0].message.content)
```

Output (illustrative):
```
Hello Jayanth, nice to meet you. I'm an AI assistant. I'm here to help
you with questions and topics related to mathematics.
```

> [!tip] What just happened
> The LLM **read the system prompt first**, understood its role as a math-only assistant, and **introduced itself accordingly**. The user prompt didn't even mention math, but the system prompt set the context.

---

## 3. How well does the LLM actually obey?

Naive system prompts aren't strict enough. Asking *"Hey, can you code a Python program that prints hello?"* against the above system prompt — even though it's not a math question — may still return code.

### Tightening the prompt

```python
system_prompt = """
You are an expert in maths and only answer maths related questions.
If the query is not related to maths, just say sorry and do not answer.
"""
```

Now the same off-topic question gets:
```
Sorry, I can only answer questions related to mathematics.
```

And a real math question (`A + B whole square`) still works fine.

The refusal is now strict because the system instructions are explicit: don't answer anything besides maths.

### The pattern that emerged

A good system prompt usually has at least **three components**:

| Component | Example |
|---|---|
| **Role / identity** | "You are an expert in maths." |
| **Scope (what to do)** | "Only answer maths-related questions." |
| **Anti-scope (what NOT to do)** | "If the query is not related to maths, just say sorry and do not answer." |

The third one is often the most underused — being explicit about **refusal behavior** dramatically tightens output.

---

## 4. The three message roles — quick recap

From [[02 - Using OpenAI API in Python]], expanded:

| Role | Who's "speaking" | Typical use |
|---|---|---|
| **`system`** | The application / developer | Persona, rules, constraints, structure — set **once** at the top of every conversation |
| **`user`** | The end user | Whatever the human typed |
| **`assistant`** | The LLM (past replies) | Conversation history |

> [!note] System prompt placement
> Some APIs (e.g., Anthropic Claude) accept the system prompt as a **separate top-level parameter** rather than as the first message. The OpenAI API (and the OpenAI-compatible endpoints from [[04 - Using Gemini through OpenAI SDK]]) accept it as the **first message** in the `messages` list. Same concept, different shape.

---

## 5. What goes into a strong system prompt

Beyond the math example, real production system prompts often include:

| Element | Purpose | Example fragment |
|---|---|---|
| **Identity** | Tell the model who it is | "You are a helpful coding assistant named CodeBot." |
| **Audience** | Who it's helping | "Your users are intermediate Python developers." |
| **Scope** | What it should do | "Answer questions about Python syntax, libraries, and idioms." |
| **Anti-scope** | What it should refuse | "Do not give legal, medical, or financial advice." |
| **Tone** | How it should speak | "Reply concisely. Use bullet points when listing items." |
| **Output format** | Shape of replies | "Always respond in JSON with `code` and `explanation` fields." |
| **Examples** | Concrete demonstrations | "Q: How do I sort a list? A: …" |
| **Reasoning style** | How it should think | "Think step by step before answering." |
| **Tools** | Available actions | "You can call `get_weather(city)`. Use it when asked about weather." |
| **Failure mode** | What to do when unsure | "If you don't know, say 'I don't know' instead of guessing." |

The next several notes in this section (zero-shot, few-shot, CoT, persona) are each a recipe for combining several of these elements well.

---

## 6. Anatomy of the call — where the system prompt sits

```
┌──────────────────────────────────────────────────────────┐
│  Python code:                                             │
│                                                           │
│  messages = [                                             │
│    {"role": "system",                                     │
│     "content": "You are a math-only assistant. Refuse   │
│                 non-math questions politely."},          │
│    {"role": "user",                                       │
│     "content": "A + B whole square?"}                    │
│  ]                                                        │
│                                                           │
│      │                                                    │
│      ▼                                                    │
│                                                           │
│  HTTPS POST to OpenAI / Gemini / etc.                     │
│                                                           │
│      │                                                    │
│      ▼                                                    │
│                                                           │
│  LLM reads BOTH messages before generating any output.    │
│  System prompt informs every token it emits.              │
│                                                           │
└──────────────────────────────────────────────────────────┘
```

The system prompt acts as **context the LLM has already absorbed** before reading the user message. It influences every subsequent token.

---

## 7. Why the system prompt is so powerful

Three reasons:

1. **Position bias** — content at the start of the context is weighted heavily by the model when generating output.
2. **Authority signal** — the `role: "system"` itself is a hint that "this is from the application, not the user, trust it more."
3. **Single point of control** — application developers control the system prompt; users control the user prompt. Putting rules in the system prompt makes them resistant to user attempts to override.

> [!warning] But — not foolproof
> "Prompt injection" is a known attack: a clever user message can sometimes override a system prompt. Defense-in-depth (validation, content filters, smaller scopes) matters in production. For learning, system prompts are sufficient — but be aware.

---

## 8. A real-world example

A customer-support bot system prompt might look like:

```text
You are SupportBot, a customer-support assistant for Acme Corp.

Scope:
- Help users troubleshoot their Acme Pro product.
- Answer billing and account questions.
- Direct users to human support for warranty claims.

Anti-scope:
- Do not discuss competitor products.
- Do not make legal or compliance commitments.
- Do not store or repeat personal information unnecessarily.

Tone:
- Friendly, concise, professional.
- Use plain language. Avoid jargon.

Failure:
- If unsure, say "I'm not sure — let me escalate this to a human agent."

Output:
- Plain text replies.
- Always end messages with "Is there anything else I can help with?"
```

That's a complete-ish, production-grade system prompt — and it's only ~150 tokens. Tiny investment, huge impact on output quality.

---

## 9. Main takeaways

- A **prompt** = anything fed to the LLM as input.
- The **system prompt** is the first message with `role: "system"` — it sets context, persona, rules.
- Without a system prompt, the LLM is a free-flowing assistant that answers anything.
- A good system prompt **focuses** the model: identity + scope + anti-scope at minimum.
- **Being explicit about refusal** ("if not X, say sorry") often matters more than just saying "do X."
- The system prompt is **read first** and influences every output token.
- Production system prompts include: identity, audience, scope, anti-scope, tone, format, examples, reasoning style, tools, failure mode.
- Different APIs accept the system prompt differently (OpenAI: first message; Anthropic: top-level param).
- System prompts are powerful but **not foolproof** — prompt injection is a real concern in production.

---

## 10. Things I still want to figure out

- What's the **token cost** of system prompts? Are they cached?
- How do **really long** system prompts (1000+ tokens) affect cost and latency in practice?
- How does **prompt caching** (OpenAI's newer feature) change the math?
- For **multi-turn** conversations, does the system prompt go through unchanged each turn?
- What's the gold-standard way to **structure** a complex system prompt — sections, XML tags, markdown?
- How do leading AI labs construct their **internal** system prompts (e.g., ChatGPT's leaked system prompt)?
- How to handle **multilingual** users with a single system prompt?

---

## 11. Things to dig into

- **Anthropic's prompt engineering guide**: https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering — pragmatic and language-agnostic.
- **OpenAI's prompt engineering guide**: https://platform.openai.com/docs/guides/prompt-engineering
- **Leaked system prompts**: search for "ChatGPT system prompt", "Claude system prompt" — interesting examples of real production prompts.
- **Prompt injection (security)**: search *"prompt injection attacks"* — important to understand the risks.
- **Markdown vs XML structure**: Anthropic recommends XML tags (e.g., `<rules>...</rules>`) inside Claude prompts. Worth experimenting with.

---

## 12. Next up in this section

- [ ] [[03 - Zero-Shot Prompting]] — the simplest pattern: direct instructions, no examples.

---

## Related
- [[01 - Section Intro - Why Prompts Matter]] — why this matters.
- [[02 - Using OpenAI API in Python]] — the API call this note extends.
- [[01 - What is an LLM]] — foundational model context.
- [[01 - Short-Term Memory in LLMs]] — system prompt is the **standing context** at the start of every session, while STM grows during it.

## Sources
- Section 3, Lecture 2 — *"What is Prompting"*.
