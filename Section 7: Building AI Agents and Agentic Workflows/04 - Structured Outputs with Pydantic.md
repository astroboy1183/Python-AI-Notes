---
title: Structured Outputs with Pydantic
date: 2026-05-28
source: "Section 7 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 7: Building AI Agents and Agentic Workflows"
tags:
  - agents
  - structured-output
  - pydantic
  - type-safety
  - openai
  - parsed-completions
  - validation
  - hands-on
related:
  - "[[03 - Building a Weather Agent]]"
  - "[[05 - Structured Output with Few-Shot Prompting]]"
  - "[[02 - Using OpenAI API in Python]]"
---

# Structured Outputs with Pydantic

> [!abstract] TL;DR
> The weather agent in [[03 - Building a Weather Agent]] has one **huge bug**: it relies on `json.loads()` of free-form text. If the LLM ever produces invalid JSON, the dispatcher crashes. Fix it with **OpenAI's Structured Outputs feature + Pydantic**. Define a Pydantic `BaseModel` describing the agent's reply shape (step, content, tool, input). Switch the API call from `client.chat.completions.create(...)` to `client.beta.chat.completions.parse(...)` and pass the Pydantic class as `response_format`. The model now **guarantees** a JSON object matching the schema — invalid output becomes impossible. Access the result via `response.choices[0].message.parsed` as a typed Pydantic object: `parsed.step`, `parsed.tool`, `parsed.input` — fully typed, with IDE autocomplete, and no `json.loads` anywhere.

> [!info] Where this fits
> Fourth note of **Section 7: Building AI Agents and Agentic Workflows**. Pure reliability upgrade to the weather agent from [[03 - Building a Weather Agent]]. The architecture, tools, and dispatch logic stay the same — only the response-parsing layer changes. After this, [[05 - Building a CLI Coding Assistant]] applies the same agent pattern to file/system tools.

---

## 1. The bug — why the weather agent is fragile

In [[03 - Building a Weather Agent]], the call was:

```python
response = client.chat.completions.create(
    model="gpt-4o",
    response_format={"type": "json_object"},
    messages=message_history,
)
raw_result = response.choices[0].message.content    # a string
parsed = json.loads(raw_result)                     # 🤞 hope it's valid JSON
step = parsed.get("step")                           # 🤞 hope this field exists
```

Three levels of "hope":

| Hope | Failure mode |
|---|---|
| LLM produces valid JSON | Stray text: *"Sure! Here you go: {...}"* → `json.loads` crashes |
| JSON has the right fields | Missing `step` → `.get("step")` returns `None`, dispatcher silently breaks |
| Field values are valid | LLM emits `step: "thinking"` instead of `"plan"` → unknown step path |

The bug: relying on string outputs and being optimistic that `json.loads` will work every time. Better approach — actually tell the LLM what structure the response should be in.

The cost of those hopes: in production, **maybe 1 in 200 calls** fails on a JSON parse error. Multiply across thousands of agent runs and the bug becomes constant noise.

---

## 2. The fix — OpenAI Structured Outputs

OpenAI shipped a feature called **Structured Outputs** in mid-2024 that **guarantees** the model's output conforms to a JSON Schema. Two ways to use it:

| Approach | API |
|---|---|
| **Raw JSON Schema** | Pass a dict-based schema to `response_format` |
| **Pydantic model** (recommended) | Pass a `BaseModel` class to `response_format` via `client.beta.chat.completions.parse` |

Pydantic is cleaner — define a Python class, get back a typed instance. That's the approach used here.

---

## 3. Installing Pydantic

```bash
pip install pydantic
pip freeze > requirements.txt
```

Pydantic is the de facto Python validation library — already a transitive dependency of the OpenAI SDK, so this might be a no-op in some setups.

---

## 4. Defining the schema

A Pydantic model defines the exact shape the LLM **must** output:

```python
from typing import Optional
from pydantic import BaseModel, Field

class AgentStep(BaseModel):
    step: str = Field(
        ...,                                                  # required
        description="The ID of the step. Example: plan, output, tool, etc.",
    )
    content: Optional[str] = Field(
        None,                                                  # default
        description="Optional string content for the step.",
    )
    tool: Optional[str] = Field(
        None,
        description="The ID of the tool to call.",
    )
    input: Optional[str] = Field(
        None,
        description="The input params for the tool.",
    )
```

Key points:

| Pattern | Meaning |
|---|---|
| `step: str = Field(...)` | Required field, the `...` is Pydantic's "no default — must provide" sentinel |
| `Optional[str] = Field(None, ...)` | Optional field, defaults to `None` |
| `description="..."` | **Used by OpenAI** to guide the model — what each field is for |
| `BaseModel` | Base class that handles validation, serialization, JSON schema generation |

> [!tip] Why the description matters
> When this Pydantic model is passed to OpenAI's API, it's auto-converted to a **JSON Schema**, and the `description` fields are sent to the model as **schema hints**. The model reads which fields it can output, their types, and their descriptions, then uses that to decide what to put in each field. Descriptive `description=` values = better-behaved agents.

---

## 5. The upgraded API call

Switch from `create` to `parse`:

```python
from openai import OpenAI

client = OpenAI()

response = client.beta.chat.completions.parse(
    model="gpt-4o-2024-08-06",      # structured outputs require recent model
    messages=message_history,
    response_format=AgentStep,        # ← Pydantic class as response_format
)

parsed: AgentStep = response.choices[0].message.parsed
```

| Old API | New API |
|---|---|
| `.create(...)` | `.beta.chat.completions.parse(...)` |
| `response_format={"type": "json_object"}` | `response_format=AgentStep` (Pydantic class) |
| `response.choices[0].message.content` (string) | `response.choices[0].message.parsed` (typed object) |
| `json.loads(...)` needed | Not needed |
| `parsed.get("step")` (could be None) | `parsed.step` (typed `str`) |

> [!note] `parsed` AND `content` both exist
> The response still has `.message.content` (the raw JSON string), but `.message.parsed` is the **already-validated Pydantic instance**. Use `parsed`.

---

## 6. The upgraded dispatcher

The dispatcher becomes type-safe:

### Before (from [[03 - Building a Weather Agent]])
```python
raw_result = response.choices[0].message.content
parsed = json.loads(raw_result)

step = parsed.get("step")
content = parsed.get("content")

if step == "tool":
    tool_name = parsed.get("tool")
    tool_input = parsed.get("input")
    ...
```

### After
```python
parsed = response.choices[0].message.parsed

if parsed.step == "tool":
    tool_name = parsed.tool                              # typed: Optional[str]
    tool_input = parsed.input                            # typed: Optional[str]
    ...
```

Differences:
- No `json.loads`.
- No `.get("...")` — direct attribute access.
- **IDE autocomplete** works — typing `parsed.` shows the available fields.
- **Type checking** at edit time (mypy, pyright) catches typos like `parsed.steps`.

---

## 7. The full upgraded agent

Pulling it all together:

```python
import json
from typing import Optional

from dotenv import load_dotenv
from openai import OpenAI
from pydantic import BaseModel, Field

import requests

load_dotenv()
client = OpenAI()

# ── Tool ────────────────────────────────────────────────────────────
def get_weather(city: str) -> str:
    url = f"https://wttr.in/{city.lower()}?format=%C+%t"
    response = requests.get(url)
    if response.status_code == 200:
        return f"The weather in {city} is {response.text}"
    return "Something went wrong"

available_tools = {"get_weather": get_weather}

# ── Output schema ───────────────────────────────────────────────────
class AgentStep(BaseModel):
    step: str = Field(..., description="One of: start, plan, tool, output")
    content: Optional[str] = Field(None, description="Text content for the step")
    tool: Optional[str] = Field(None, description="Name of the tool to call")
    input: Optional[str] = Field(None, description="Input argument for the tool")

# ── System prompt ──────────────────────────────────────────────────
system_prompt = "..."     # same as Note 3

# ── Agent loop ─────────────────────────────────────────────────────
def main():
    message_history = [{"role": "system", "content": system_prompt}]

    while True:
        user_query = input("\n🙋 > ")
        if not user_query.strip():
            break
        message_history.append({"role": "user", "content": user_query})

        while True:
            response = client.beta.chat.completions.parse(
                model="gpt-4o-2024-08-06",
                messages=message_history,
                response_format=AgentStep,
            )

            parsed: AgentStep = response.choices[0].message.parsed

            # Append the raw response to history (still need this for context)
            message_history.append({
                "role": "assistant",
                "content": response.choices[0].message.content,
            })

            if parsed.step == "start":
                print(f"🔥 {parsed.content}")

            elif parsed.step == "plan":
                print(f"🧠 {parsed.content}")

            elif parsed.step == "tool":
                print(f"🔧 Calling {parsed.tool}({parsed.input!r})")
                tool_response = available_tools[parsed.tool](parsed.input)
                print(f"🔍 Tool result: {tool_response}")

                # Inject observe message
                observe_message = {
                    "step": "observe",
                    "tool": parsed.tool,
                    "input": parsed.input,
                    "output": tool_response,
                }
                message_history.append({
                    "role": "developer",
                    "content": json.dumps(observe_message),
                })

            elif parsed.step == "output":
                print(f"🤖 {parsed.content}")
                break

if __name__ == "__main__":
    main()
```

About 60 lines including the (omitted) system prompt — production-grade structurally.

---

## 8. What the API does under the hood

When OpenAI receives a request with `response_format=AgentStep`:

1. The SDK **converts** the Pydantic model into a JSON Schema.
2. That schema is sent to the model along with the messages.
3. The model's decoding is **constrained** — at each token-generation step, only tokens that lead to valid-schema completions are sampled.
4. The output is **guaranteed** to be valid JSON matching the schema.
5. The SDK parses the JSON back into a Pydantic instance and exposes it as `.parsed`.

The "constrained decoding" step is implemented server-side by OpenAI — it's not a post-hoc validation. Invalid output is **mathematically impossible**.

> [!info] Constrained decoding
> The technique behind structured outputs is called **constrained sampling** or **grammar-constrained generation**. At every token step, the runtime computes the set of next-tokens that could still lead to schema-valid output, masks the rest, then samples from the allowed set. Used by:
> - OpenAI Structured Outputs (server-side).
> - **Outlines** library (open-source).
> - **lm-format-enforcer** (open-source).
> - **vLLM**'s structured output support.
>
> Trade-off: slightly slower inference (a few % overhead) for **100% reliability**.

---

## 9. Strict mode and required fields

By default, Pydantic-derived schemas are **non-strict** — extra fields and missing fields are tolerated. For stricter behavior:

```python
class AgentStep(BaseModel):
    model_config = {"extra": "forbid"}     # no extra fields allowed

    step: str = Field(..., description="...")
    # ...
```

Strict mode means: every field is required, no extras. OpenAI's Structured Outputs with Pydantic enable strict mode automatically when fields have no defaults.

For **optional** fields (like `tool` and `input` here), the schema marks them nullable. The model can choose to set them or leave them `null`.

---

## 10. Type-safety wins beyond reliability

Structured outputs unlock several developer-experience improvements:

### IDE autocomplete
Typing `parsed.` brings up `step`, `content`, `tool`, `input` automatically.

### Static type checking
```python
def handle(parsed: AgentStep):
    if parsed.step == "tol":   # ← typo!
        ...                    #    mypy/pyright catches this at edit time
```

### Refactoring safety
Renaming a field in `AgentStep` triggers errors **everywhere** it's used. With `parsed.get("step")`, the typo would silently return `None`.

### Documentation as schema
The `description=` fields in `Field(...)` show up:
- In IDE tooltips when hovering.
- In generated docs (Sphinx, mkdocs).
- As schema hints sent to the LLM.

Same docstring serves three audiences. Clean.

---

## 11. When to use structured outputs vs JSON mode

Quick decision matrix:

| Need | Use |
|---|---|
| Free-form JSON, any shape | `response_format={"type": "json_object"}` |
| Specific schema, want type-safety | **`client.beta.chat.completions.parse` + Pydantic** |
| Production agent with strict contract | Pydantic with `extra: forbid` |
| Compatibility with older models | JSON mode (not Structured Outputs) |
| Multi-provider code (works with non-OpenAI) | JSON mode + Pydantic on the client side for validation |

The **only reason** to skip structured outputs for new code is model compatibility — only newer OpenAI models support it. For frontier work, always use it.

---

## 12. Common gotchas

> [!warning] First-time issues

| Symptom | Cause | Fix |
|---|---|---|
| `model_not_supported` for structured outputs | Older model | Use `gpt-4o-2024-08-06` or later, or `gpt-4o-mini-2024-07-18` |
| Pydantic schema not allowed | Complex Pydantic features (Union of literals, etc.) | Simplify or wrap in `RootModel` |
| `extra fields not permitted` | Schema doesn't allow extra fields | Either add them to the model or set `extra: ignore` |
| `parsed` is None | Model refused (safety filter triggered) | Check `response.choices[0].message.refusal` |
| Streaming + structured outputs | Slightly different API | Use `stream=True` with `parse` — supported but check docs |
| Slow first response | Schema compilation is per-request | First request is slower; subsequent are fast |

---

## 13. Comparison — before vs after

A side-by-side of the dispatcher logic:

```python
# BEFORE — relies on json.loads
raw_result = response.choices[0].message.content
parsed = json.loads(raw_result)
if parsed.get("step") == "tool":
    tool_name = parsed.get("tool")
    tool_input = parsed.get("input")
    tool_response = available_tools[tool_name](tool_input)

# AFTER — type-safe Pydantic
parsed = response.choices[0].message.parsed
if parsed.step == "tool":
    tool_response = available_tools[parsed.tool](parsed.input)
```

Half as much code. Twice as safe. Zero parse errors in production.

---

## 14. Main takeaways

- **The weather agent's `json.loads()` is a reliability bomb** in production.
- **Pydantic + OpenAI Structured Outputs** = guaranteed-shape output.
- Pattern:
  ```python
  class MySchema(BaseModel): ...
  response = client.beta.chat.completions.parse(..., response_format=MySchema)
  parsed = response.choices[0].message.parsed       # typed instance
  ```
- `description=` on Pydantic fields **guides the model** (not just for humans).
- `.parsed` attribute returns a **typed object** — no `json.loads`, no `.get("...")`.
- Type-safety unlocks **IDE autocomplete, mypy/pyright checking, refactoring safety**.
- Use **constrained decoding** server-side — invalid output is mathematically impossible.
- For production agents: **always** use structured outputs over raw JSON mode.
- Compatible models: `gpt-4o-2024-08-06`+ and `gpt-4o-mini-2024-07-18`+.

---

## 15. Things I still want to figure out

- How to define a **discriminated union** in Pydantic for agent steps? (`step: Literal["start", "plan", "tool", "output"]` and conditional fields per step type)
- Performance: how much overhead does structured output add per call?
- Does **streaming** with structured outputs preserve schema guarantees on partial chunks?
- How do **other providers** (Gemini, Claude) handle structured outputs — equivalent APIs?
- Can the schema include **examples** that get sent to the model?
- How does this interact with **multi-modal** outputs (text + image)?
- For very large schemas, is there a token-cost hit?

---

## 16. Things to dig into

- **OpenAI Structured Outputs guide**: https://platform.openai.com/docs/guides/structured-outputs
- **Pydantic docs**: https://docs.pydantic.dev
- **Constrained decoding background**: search for "outlines library", "grammar-constrained generation"
- **Hands-on**: take the agent from [[03 - Building a Weather Agent]], swap in Pydantic, observe how often `json.loads` was actually failing before.

---

## 17. Next up in this section

Same agent pattern, different tool — give the agent a `run_command` tool that can write files and execute shell commands. The result: vibe-code an entire app from a single prompt.

- [ ] [[05 - Building a CLI Coding Assistant]] — the big finale of Section 7.

---

## Related
- [[03 - Building a Weather Agent]] — the agent this lecture hardens.
- [[05 - Structured Output with Few-Shot Prompting]] — Section 3 introduction to structured outputs.
- [[02 - Using OpenAI API in Python]] — the underlying API.

## Sources
- Section 7, Lecture 4 — *"Structured Outputs with Pydantic"*.
- OpenAI Structured Outputs guide — https://platform.openai.com/docs/guides/structured-outputs
- Pydantic docs — https://docs.pydantic.dev
