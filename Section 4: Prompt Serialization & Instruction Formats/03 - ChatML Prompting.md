---
title: ChatML Prompting
date: 2026-05-28
source: "Section 4 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 4: Prompt Serialization & Instruction Formats"
tags:
  - prompts
  - chatml
  - prompt-style
  - openai
  - gemini
  - claude
  - role-content
  - messages
  - foundations
  - de-facto-standard
related:
  - "[[01 - Prompt Styles - Section Intro]]"
  - "[[02 - What is Prompting]]"
  - "[[02 - Using OpenAI API in Python]]"
---

# ChatML Prompting

> [!abstract] TL;DR
> **ChatML** = the **chat-completions message format**: a Python list of dictionaries, each with `role` (one of `system` / `user` / `assistant`) and `content` (string). Created by OpenAI for GPT-3.5 / GPT-4 and now the **de facto standard** across the LLM ecosystem — OpenAI, Gemini (via the OpenAI-compat endpoint), Claude (with minor variations), and most LLM gateways/proxies all speak ChatML. Cleanly handles multi-turn conversations, structured roles, and tool calls. **The only style that really matters in 99% of agentic-AI work.** Already used in [[02 - Using OpenAI API in Python]] and every code example in Section 3.

> [!info] Where this fits
> Third note of **Section 4: Prompt Serialization & Instruction Formats**. The format every code example so far already uses. This note formalizes what's been implicit.

---

## 1. The format

A ChatML "prompt" is a **list of messages**:

```python
messages = [
    {"role": "system",    "content": "<<<system prompt>>>"},
    {"role": "user",      "content": "<<<first user message>>>"},
    {"role": "assistant", "content": "<<<assistant's reply>>>"},
    {"role": "user",      "content": "<<<follow-up user message>>>"},
]
```

Every entry has exactly two fields:

| Field | Type | Values |
|---|---|---|
| `role` | string | `"system"`, `"user"`, `"assistant"`, `"tool"` |
| `content` | string (or list of parts) | The actual text |

That's the whole format. Simple.

> [!note] How the roles map
> Each message is an object with a `role` and a `content`. If `role` is `system`, `content` is the system prompt. If `role` is `user`, `content` is what the human typed. If `role` is `assistant`, `content` is a previous model reply — fed back in so the model has context for the next set of tokens.

---

## 2. The three (four) roles

| Role | Who it represents | Typical use |
|---|---|---|
| **`system`** | The application / developer | Persona, rules, constraints — set once at the top |
| **`user`** | The end user (human) | Whatever the human typed |
| **`assistant`** | The LLM (in past turns) | Previous LLM replies, retained for context |
| **`tool`** | Tool / function call results | Used with function calling / tool use (later) |

A `developer` role was added by OpenAI in 2024 — a stronger-than-`system` instruction layer used by the o-series models. For most work, the `system` role is still the right choice.

---

## 3. Wire format — what the model actually sees

Inside OpenAI's servers, the ChatML message list gets serialized into a special tokenized form using **delimiter tokens**:

```
<|im_start|>system
You are a helpful assistant.<|im_end|>
<|im_start|>user
Hey there.<|im_end|>
<|im_start|>assistant
Hi! How can I help?<|im_end|>
```

Each turn is wrapped in `<|im_start|>...<|im_end|>` markers (these are **special tokens** in the tokenizer — see [[04 - What is a Token]]). The role appears as a plain token after `<|im_start|>`.

> [!note] Why this matters
> The OpenAI client SDK **handles this serialization automatically**. As an application developer, only the Python dict list is exposed. But it explains *why* the `role` field is needed — it's literally what the model sees in its tokens.

---

## 4. Why ChatML won

ChatML beat other styles for several reasons:

| Reason | Detail |
|---|---|
| **Native multi-turn** | Trivially supports back-and-forth conversation |
| **Explicit roles** | No guessing who's saying what |
| **Structured JSON** | Easy to construct, serialize, store, debug |
| **Strong frontier-model support** | OpenAI invented it; everyone followed |
| **Tool calling extension** | `tool` role added cleanly |
| **Multimodal extension** | `content` can be a list of typed parts (text, image, audio) |
| **Streaming-friendly** | Easy to identify when one message ends |

OpenAI and Gemini both use ChatML, and for ~99% of agentic-AI work this is the only style needed. Knowing the `role` / `content` shape is enough to operate against every major hosted API.

---

## 5. Multi-turn example

A full three-turn exchange:

```python
messages = [
    {"role": "system",    "content": "You are Jayanth's coding assistant. Keep replies short."},
    {"role": "user",      "content": "How do I reverse a list in Python?"},
    {"role": "assistant", "content": "Use `my_list[::-1]` or `reversed(my_list)`."},
    {"role": "user",      "content": "Which one is faster?"},
]

response = client.chat.completions.create(
    model="gpt-4o",
    messages=messages,
)
```

The model sees the **entire history** and responds to the latest user message in context. The application then **appends the new assistant reply** to `messages` for the next turn.

This is exactly the pattern in [[01 - Short-Term Memory in LLMs]] — the message list **is** STM.

---

## 6. Multimodal content (modern ChatML)

For models that support images / audio / video, `content` becomes a **list of typed parts**:

```python
messages = [
    {
        "role": "user",
        "content": [
            {"type": "text",      "text": "What's in this image?"},
            {"type": "image_url", "image_url": {"url": "https://example.com/cat.jpg"}},
        ],
    },
]
```

Same `role` field; richer `content`. The text-only string form is the special case where there's only one text part.

---

## 7. Tool calls (modern ChatML)

When the model wants to call a tool (function calling):

```python
# Model emits an assistant message with `tool_calls`:
{
    "role": "assistant",
    "content": None,
    "tool_calls": [
        {
            "id": "call_123",
            "type": "function",
            "function": {
                "name": "get_weather",
                "arguments": '{"city": "Bangalore"}',
            },
        }
    ],
}

# App responds with the tool result:
{
    "role": "tool",
    "tool_call_id": "call_123",
    "content": '{"temp_c": 28, "condition": "sunny"}',
}
```

The pattern: assistant asks for a tool → app executes → app sends back a `tool` role message with the result → assistant continues. This is the foundation of **agents** (covered in Section 7).

---

## 8. Equivalent to other styles

The same intent across all three styles in this section:

| Style | Format |
|---|---|
| **Alpaca** | `### Instruction: ... ### Input: ... ### Response:` |
| **ChatML** | `messages=[{"role":"system",...}, {"role":"user",...}]` |
| **INST** | `<s>[INST] <<SYS>>...<</SYS>> ... [/INST]` |

ChatML wins on:
- Multi-turn support.
- Explicitness.
- Tooling.

It loses to Alpaca / INST on:
- Token efficiency (delimiter tokens add overhead).
- Simplicity for one-shot tasks.

For production agentic AI, the trade-off **always favors ChatML**.

---

## 9. ChatML across providers

Even when not using OpenAI directly, ChatML is what most providers accept:

| Provider | ChatML support |
|---|---|
| OpenAI | ✅ Native |
| Google Gemini | ✅ Via OpenAI-compat endpoint ([[04 - Using Gemini through OpenAI SDK]]) |
| Anthropic Claude | ✅ Slight schema variation (system at top level, not in messages) |
| Groq, Together AI, OpenRouter | ✅ Native (OpenAI-compatible) |
| Ollama / vLLM (local) | ✅ Via OpenAI-compatible endpoint |
| LangChain, LlamaIndex | ✅ Native abstraction |

The result: writing code against the ChatML message format unlocks the **entire LLM ecosystem**.

---

## 10. Common gotchas

> [!warning] Things to watch for

| Gotcha | Detail |
|---|---|
| Roles must alternate user/assistant after system | Some models error if two `user` messages in a row |
| `content` must be a string (or list for multimodal) — never `None` for plain text | Edge case with tool calls only |
| First message should usually be `system` | Some models require it; others tolerate any order |
| Anthropic's quirk | System prompt goes as a **top-level parameter**, not in `messages` |
| Very long histories | Eventually hit context limits; summarize old turns |
| Mixing tool calls without `tool_call_id` | Strict APIs reject mismatched IDs |

---

## 11. Main takeaways

- **ChatML** = a list of `{"role": ..., "content": ...}` dictionaries.
- Roles: **`system`**, **`user`**, **`assistant`**, **`tool`** (and newer `developer`).
- Created by OpenAI; adopted by Gemini, Claude, and ~every other major API.
- Multi-turn is **trivial** — just append messages to the list.
- Multimodal content uses a **typed-parts list** instead of a plain string.
- Tool calls use a **special structure** in the assistant message + a `tool` response message.
- Under the hood, gets serialized to `<|im_start|>role\n...\n<|im_end|>` tokens.
- **The only prompt style that matters in 99% of agentic-AI work.**
- Already used by every code example in [[02 - Using OpenAI API in Python]] and Section 3.

---

## 12. Things I still want to figure out

- What's the exact OpenAI `developer` role meant for and how does it differ from `system`?
- For Anthropic's variation (system as top-level), what's the cleanest abstraction in code that works across providers?
- How are **streaming chunks** delimited in ChatML — token-level or message-level?
- What's the cost difference (in tokens) between ChatML's delimiters and a plain Alpaca prompt?
- For very large message lists (100+ turns), is there a best-practice summarization pattern?
- How does ChatML handle **partial / interrupted** assistant responses?

---

## 13. Things to dig into

- **OpenAI ChatML spec** (semi-formal): https://github.com/openai/openai-python — see how the SDK serializes.
- **Anthropic message API docs**: https://docs.anthropic.com/en/api/messages — the slightly-different variant.
- **Tool calling deep dive**: OpenAI's function-calling guide.
- **Hands-on**: print the raw tokens of a ChatML prompt using `tiktoken` — see the `<|im_start|>` boundaries.

---

## 14. Next up in this section

- [ ] [[04 - Instruction (INST) Prompting]] — the Llama 2 chat format.

---

## Related
- [[01 - Prompt Styles - Section Intro]] — section intro.
- [[02 - Alpaca Prompting]] — sibling style.
- [[02 - What is Prompting]] — system prompts in context.
- [[02 - Using OpenAI API in Python]] — where ChatML is already used.
- [[04 - Using Gemini through OpenAI SDK]] — how ChatML becomes a cross-provider standard.

## Sources
- OpenAI Python SDK: https://github.com/openai/openai-python
- Anthropic Messages API: https://docs.anthropic.com/en/api/messages
