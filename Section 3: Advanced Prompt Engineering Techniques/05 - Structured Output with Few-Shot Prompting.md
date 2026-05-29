---
title: Structured Output with Few-Shot Prompting
date: 2026-05-28
source: "Section 3 / Lecture 5"
type: lecture-notes
status: in-progress
section: "Section 3: Advanced Prompt Engineering Techniques"
tags:
  - prompts
  - few-shot
  - structured-output
  - json
  - json-mode
  - parsing
  - prompt-engineering
  - hands-on
related:
  - "[[04 - Few-Shot Prompting]]"
  - "[[02 - Using OpenAI API in Python]]"
---

# Structured Output with Few-Shot Prompting

> [!NOTE]
> **TL;DR**
> Few-shot examples don't just teach **what** the model should answer — they also lock down **how** the answer is formatted. By declaring an output JSON schema in the system prompt and providing examples that conform to it, every reply comes back as a parseable JSON object. That makes the model's output **programmatically usable** — `json.loads(content)` → access fields with `.get("code")` etc. Worked example: a coding assistant that returns `{"code": "...", "is_coding_question": true/false}`. Free-form text becomes structured data → unlocks pipelines, automation, and downstream code. This is the foundation pattern for **tool use, agent steps, and reliable workflows** in the rest of the course.

> [!NOTE]
> **Where this fits**
> Fifth note of **Section 3: Advanced Prompt Engineering Techniques**. Direct extension of [[04 - Few-Shot Prompting]] — same few-shot pattern, with examples deliberately designed to teach the model a **specific JSON schema**. The next note ([[06 - Chain of Thought Prompting]]) uses this same technique to implement step-by-step reasoning where each step is a JSON object.

---

## 1. The problem — free-form text is hard to consume

A normal LLM response is a blob of natural language, often with formatting:

```
Here's a Python function to add two numbers:

```python
def add(a, b):
    return a + b
```

This function takes two numbers a and b...
```

A human can read it. **A program can't easily use it.** Code that wants to extract "the code" has to do brittle string parsing:
- Find the triple-backtick fence.
- Extract what's between.
- Pray it's actually Python and not pseudocode.

Worse: there's no reliable way to know if the answer was actually code or just a refusal.

---

## 2. The fix — structured JSON output

What if the model **always** returned JSON like:

```json
{
  "code": "def add(a, b):\n    return a + b",
  "is_coding_question": true
}
```

Now a program can:
- `result = json.loads(content)`
- `if result["is_coding_question"]:` → use `result["code"]`
- Else → show the refusal message.

Reliable, machine-readable, easy to chain into downstream code.

Few-shot prompting can bind **output quality** the same way it binds behaviour. Parse the reply with `json.loads`, then use dot notation (e.g. `result.code`) to access fields directly.

---

## 3. The pattern

Three things stacked into one system prompt:

1. **Instructions** (what to do).
2. **Output schema declaration** (the exact shape required).
3. **Examples that conform to the schema** (the teaching).

```python
system_prompt = """
You should only and only answer coding-related questions.
Your name is Alexa.

Rules:
- Strictly follow the output format in JSON.

Output format:
{
  "code": <string or null>,
  "is_coding_question": <boolean>
}

Examples:

Q: Can you explain (A + B) whole square?
A: {"code": null, "is_coding_question": false}

Q: Write a JavaScript function to add n numbers.
A: {"code": "function add(...nums) { return nums.reduce((a,b)=>a+b, 0); }", "is_coding_question": true}
"""
```

The examples **teach by demonstration** that:
- Non-coding question → `code: null`, `is_coding_question: false`.
- Coding question → `code: "<actual code>"`, `is_coding_question: true`.

---

## 4. The full code

`prompts/02_structured_output.py`:

```python
import json
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
client = OpenAI()

system_prompt = """
You should only and only answer coding-related questions.
Your name is Alexa.

Rules:
- Strictly follow the output format in JSON.

Output format:
{
  "code": <string or null>,
  "is_coding_question": <boolean>
}

Examples:

Q: Can you explain (A + B) whole square?
A: {"code": null, "is_coding_question": false}

Q: Write a JavaScript function to add n numbers.
A: {"code": "function add(...nums) { return nums.reduce((a,b)=>a+b, 0); }", "is_coding_question": true}
"""

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": "Write a code to add n numbers in JS"},
    ],
)

# Parse the JSON reply
content = response.choices[0].message.content
result = json.loads(content)

# Now use it as structured data
if result["is_coding_question"]:
    print("Generated code:")
    print(result["code"])
else:
    print(content)
```

### Run 1 — math question
```python
user: "Can you explain (A + B) whole square?"
```
Output:
```json
{"code": null, "is_coding_question": false}
```

### Run 2 — coding question
```python
user: "Write a code to add n numbers in JS"
```
Output:
```json
{
  "code": "function add(...nums) { return nums.reduce((a, b) => a + b, 0); }",
  "is_coding_question": true
}
```

`json.loads(content)` succeeds in both cases. Downstream code dispatches on `is_coding_question`. **Clean integration.**

---

## 5. Pre-baked support — JSON mode

OpenAI (and Gemini via the compat layer) support a parameter that **forces** the model to emit valid JSON:

```python
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[...],
    response_format={"type": "json_object"},   # ← JSON mode
)
```

This guarantees the response is valid JSON — no stray text before or after. Combine it with few-shot examples in the system prompt and the result is **highly reliable structured output**.

> [!WARNING]
> **JSON mode caveat**
> JSON mode only guarantees **valid JSON syntax**, not that the JSON matches a specific schema. The few-shot examples still do the work of teaching the **shape** of the JSON.

For schema-strict output, OpenAI also offers **Structured Outputs** (a stricter mode that enforces a JSON Schema):

```python
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[...],
    response_format={
        "type": "json_schema",
        "json_schema": {
            "name": "coding_response",
            "schema": {
                "type": "object",
                "properties": {
                    "code": {"type": ["string", "null"]},
                    "is_coding_question": {"type": "boolean"},
                },
                "required": ["code", "is_coding_question"],
                "additionalProperties": False,
            },
            "strict": True,
        },
    },
)
```

With `strict: true`, the model **cannot** emit JSON that doesn't conform — invalid keys, missing fields, wrong types all become impossible.

> [!NOTE]
> **Which to use when**
>
> | Use case | Tool |
> |---|---|
> | Quick prototype, want loose JSON | `response_format={"type": "json_object"}` |
> | Production, exact schema required | `response_format={"type": "json_schema", "json_schema": {...}, "strict": true}` |
> | Cross-provider (Gemini compat) | `json_object` is more widely supported |
> | Combine with Python types | Use `Pydantic` + OpenAI's `.parse()` helper — auto-derives the JSON schema |

---

## 6. Pydantic — the production pattern

For real apps, the cleanest pattern combines **Pydantic models** with OpenAI's typed parsing:

```python
from pydantic import BaseModel
from openai import OpenAI

client = OpenAI()

class CodingResponse(BaseModel):
    code: str | None
    is_coding_question: bool

response = client.beta.chat.completions.parse(
    model="gpt-4o-2024-08-06",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user",   "content": "Write a code to add n numbers in JS"},
    ],
    response_format=CodingResponse,
)

result = response.choices[0].message.parsed   # already a CodingResponse instance!
print(result.code)
print(result.is_coding_question)
```

Benefits:
- Pydantic model = single source of truth for the schema.
- Strongly-typed Python access (`result.code`, not `result["code"]`).
- Auto-validation on parse.
- IDE auto-completion works.

This is the **idiomatic** modern pattern for structured output in production.

---

## 7. Why few-shot still matters with JSON mode

Even with `response_format={"type": "json_object"}`, **examples teach the semantic shape**:

| Concern | What JSON mode handles | What examples handle |
|---|---|---|
| Valid JSON syntax | ✅ | — |
| Specific field names | ❌ | ✅ |
| Specific field types | ❌ | ✅ |
| Sensible default values | ❌ | ✅ |
| Edge-case behavior (refusal as JSON) | ❌ | ✅ |
| Domain conventions | ❌ | ✅ |

So: **few-shot + JSON mode = belt and suspenders**.

---

## 8. Common patterns for structured output

Beyond the basic coding-assistant case:

### Classification
```json
{ "category": "billing" | "tech" | "shipping", "confidence": 0.0-1.0 }
```

### Entity extraction
```json
{ "people": [...], "dates": [...], "places": [...] }
```

### Tool use / function calling
```json
{ "tool": "get_weather", "args": { "city": "Bangalore" } }
```

### Multi-step reasoning (preview of [[06 - Chain of Thought Prompting]])
```json
{ "step": "plan" | "output", "content": "..." }
```

### Summarization with structure
```json
{ "summary": "...", "key_points": [...], "action_items": [...] }
```

All of these become trivially consumable in code — no string parsing, no regex.

---

## 9. Anti-patterns

> [!WARNING]
> **Common mistakes**

| Mistake | Fix |
|---|---|
| Schema in description but not in examples | Add concrete examples conforming to the schema. |
| Examples disagree on field names | Be consistent across all examples. |
| Asking for too many fields | Each field is one more thing to get wrong; trim. |
| Allowing too much nesting | Flat schemas are easier; nest only when truly needed. |
| Forgetting `null` for missing-value cases | Define a sentinel (`null`, `false`, `""`) and use it consistently. |
| Mixing prose and JSON in the same reply | Use JSON mode to prevent stray prose. |
| Not validating after parsing | Wrap `json.loads` in try/except; use Pydantic for validation. |

---

## 10. Main takeaways

- Few-shot examples **lock down output format**, not just behavior.
- Pattern: instructions → schema declaration → examples that conform.
- Free-form replies become **JSON the calling code can parse**.
- `response_format={"type": "json_object"}` forces valid JSON output.
- `response_format={"type": "json_schema", ..., "strict": true}` forces a **specific schema**.
- **Pydantic + `client.beta.chat.completions.parse`** is the idiomatic production pattern.
- JSON mode alone doesn't enforce field names — combine with examples.
- Structured output unlocks **tool use, agents, and pipelines** later in the course.

---

## 11. Things I still want to figure out

- Cost difference: does `response_format` add latency?
- What happens if the model **can't** produce valid JSON for an input — does it error or fudge?
- How does **structured output** interact with **streaming** (`stream=True`)?
- Best practice for **error fields** — `{"error": "..."} ` vs throwing exceptions?
- How does this interact with **function calling** in OpenAI / **tools** in Anthropic?
- Token cost of explicit schemas vs. inline examples — which is cheaper at scale?
- Do other providers (Gemini native, Claude) have equivalent strict-schema modes?

---

## 12. Things to dig into

- **OpenAI structured outputs docs**: https://platform.openai.com/docs/guides/structured-outputs — definitive reference.
- **Pydantic docs**: https://docs.pydantic.dev — the standard Python validation library, deeply integrated with OpenAI SDK.
- **Anthropic tool use**: how Claude does similar work via XML-tagged tool definitions.
- **Gemini structured output**: native Gemini SDK also supports schema-constrained generation.
- **Hands-on**: turn a free-form GPT prompt into a strict-JSON Pydantic pattern. Note the reliability difference.

---

## 13. Next up in this section

The next note takes structured output to the next level — using a `{"step": "...", "content": "..."}` schema to implement **step-by-step reasoning** (chain of thought):

- [ ] [[06 - Chain of Thought Prompting]] — a personal favorite, and the foundation for reasoning agents.

---

## Related
- [[04 - Few-Shot Prompting]] — the pattern this builds on.
- [[02 - Using OpenAI API in Python]] — `response_format` parameter context.
- [[06 - Chain of Thought Prompting]] — next note uses structured output for reasoning steps.

## Sources
- Section 3, Lecture 5 — *"Structured Output with Few-Shot Prompting"*.
