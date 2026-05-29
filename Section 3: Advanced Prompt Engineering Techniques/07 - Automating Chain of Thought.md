---
title: Automating Chain of Thought
date: 2026-05-28
source: "Section 3 / Lecture 7"
type: lecture-notes
status: in-progress
section: "Section 3: Advanced Prompt Engineering Techniques"
tags:
  - prompts
  - chain-of-thought
  - cot
  - automation
  - loop
  - message-history
  - python
  - json
  - prompt-engineering
  - hands-on
related:
  - "[[06 - Chain of Thought Prompting]]"
  - "[[01 - Short-Term Memory in LLMs]]"
---

# Automating Chain of Thought

> [!NOTE]
> **TL;DR**
> The manual CoT process from [[06 - Chain of Thought Prompting]] (call → copy reply → paste back → call → repeat) gets wrapped in a clean loop. Build a **`message_history` list** seeded with the system prompt + user input, then `while True: call the LLM → parse JSON → append the response → dispatch on `step` → break if `output``. Each `plan` step prints a "thinking" indicator (🧠); each `start` prints a fire (🔥); the final `output` prints the answer and breaks the loop. Result: a tiny agent that **thinks visibly out loud, step by step, automatically**, until it produces a final answer. This is the foundation pattern for **every reasoning agent** later in the course.

> [!NOTE]
> **Where this fits**
> Seventh note of **Section 3: Advanced Prompt Engineering Techniques**. Implements the automation that [[06 - Chain of Thought Prompting]] hinted at. The pattern here — *seed history → loop → dispatch on parsed JSON → append → continue* — is essentially the **ReAct / agent loop** that powers Section 7's AI agents work.

---

## 1. The problem this note solves

In [[06 - Chain of Thought Prompting]], the workflow was manual:
1. Run the script → get one step.
2. Copy the JSON output.
3. Paste it into `messages` as an assistant turn.
4. Run again → get the next step.
5. Repeat until `step == "output"`.

For a 10-step plan that's 10 manual edits. Unsustainable. Time to automate.

---

## 2. The full automated implementation

`prompts/03_cot_loop.py`:

```python
import json
from dotenv import load_dotenv
from openai import OpenAI

load_dotenv()
client = OpenAI()

system_prompt = """
You are an expert AI assistant in resolving user queries using chain of thought.

You work on start, plan, and output steps.
You need to first plan what needs to be done.
The planning can be multiple steps.
Once enough planning has been done, finally you can give an output.

Rules:
- Strictly follow the given JSON output format.
- Only run one step at a time.
- The sequence of steps is: start → plan (one or more times) → output.

Output JSON format:
{
  "step": "start" | "plan" | "output",
  "content": "<string>"
}

Example:

Q: Can you solve 2 + 3 * 5 / 10?

A: {"step": "start",  "content": "Can you solve 2 + 3 * 5 / 10?"}
A: {"step": "plan",   "content": "Seems like the user is interested in a maths problem around BODMAS."}
A: {"step": "plan",   "content": "First multiply: 3 * 5 = 15. New expression: 2 + 15 / 10."}
A: {"step": "plan",   "content": "Now divide: 15 / 10 = 1.5. New expression: 2 + 1.5."}
A: {"step": "plan",   "content": "Finally add: 2 + 1.5 = 3.5."}
A: {"step": "output", "content": "3.5"}
"""

# Seed the conversation history with the system prompt.
message_history = [
    {"role": "system", "content": system_prompt},
]

# Get the user's actual question.
user_query = input("🙋  > ")
message_history.append({"role": "user", "content": user_query})

# The loop — keep asking the model for the next step until it emits "output".
print()
while True:
    response = client.chat.completions.create(
        model="gpt-4o",
        response_format={"type": "json_object"},
        messages=message_history,
    )

    raw_result = response.choices[0].message.content
    parsed_result = json.loads(raw_result)

    # Append the model's reply to history (so the next call sees it as context).
    message_history.append({"role": "assistant", "content": raw_result})

    step = parsed_result.get("step")
    content = parsed_result.get("content")

    # Dispatch on which step we got back.
    if step == "start":
        print(f"🔥 {content}")
        continue
    elif step == "plan":
        print(f"🧠 {content}")
        continue
    elif step == "output":
        print(f"🤖 {content}")
        break
    else:
        print(f"⚠️  Unknown step '{step}': {content}")
        break

print()
```

That's the entire program — about 40 lines including the system prompt.

---

## 3. Walking through the loop

### What happens on each iteration

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  1. Send message_history to the LLM                         │
│                                                             │
│  2. LLM returns ONE step as JSON                            │
│     (because the system prompt says "one step at a time")  │
│                                                             │
│  3. Parse the JSON                                          │
│                                                             │
│  4. Append the raw JSON string back into message_history   │
│     as the assistant's turn                                 │
│                                                             │
│  5. Dispatch on step:                                       │
│       "start"  → print 🔥 content, loop                     │
│       "plan"   → print 🧠 content, loop                     │
│       "output" → print 🤖 content, BREAK                    │
│                                                             │
│  6. Next iteration starts. The LLM now sees:                │
│     system + user + step1 + step2 + ... + stepN             │
│     and figures out what step N+1 should be.                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

The flow in plain English: ask the user for input, seed `message_history`, then `while True`: call the model, append whatever the assistant returns to `message_history`, print the step content, and break out of the loop when the step is `output`.

---

## 4. The two key tricks

### Trick 1 — append the raw JSON string, not the parsed object

```python
message_history.append({"role": "assistant", "content": raw_result})
#                                                       ^^^^^^^^^^
#                                                       string, not dict
```

The OpenAI API expects `content` to be a **string**. The raw JSON string serializes nicely — when the model reads the history next iteration, it sees `{"step": "plan", "content": "..."}` as the assistant's literal reply.

If using `json.dumps(parsed_result)` instead, the result is functionally the same (just reserialized).

### Trick 2 — `response_format={"type": "json_object"}` guarantees valid JSON

Without it, the model might return JSON inside a markdown code fence or with stray text. With it, `json.loads()` is safe.

---

## 5. Sample run

Asking: *"Hey, can you solve 2 + 3 / 10 * 6 * 4 / 1 - 50?"*

```
🙋  > Hey, can you solve 2 + 3 / 10 * 6 * 4 / 1 - 50?

🔥 The user wants to solve 2 + 3 / 10 * 6 * 4 / 1 - 50.
🧠 First, identify the BODMAS order: divisions and multiplications before additions/subtractions.
🧠 Compute 3 / 10 = 0.3.
🧠 Now expression: 2 + 0.3 * 6 * 4 / 1 - 50.
🧠 Compute 0.3 * 6 = 1.8.
🧠 Now expression: 2 + 1.8 * 4 / 1 - 50.
🧠 Compute 1.8 * 4 = 7.2.
🧠 Now expression: 2 + 7.2 / 1 - 50.
🧠 Compute 7.2 / 1 = 7.2.
🧠 Now expression: 2 + 7.2 - 50.
🧠 Compute 2 + 7.2 = 9.2.
🧠 Compute 9.2 - 50 = -40.8.
🤖 -40.8
```

That's CoT in action: the model's reasoning is **visible**, **structured**, and **automatic**.

---

## 6. What just got built — a tiny agent


The pattern is general:
- **State**: `message_history` (the running conversation).
- **Loop**: keep asking the LLM for the next action.
- **Dispatch**: do something different based on what the LLM said (print, call tool, finish).
- **Termination**: break when a sentinel value appears (`step == "output"`).

This is **exactly the agent loop pattern** introduced in Section 7. The difference between "CoT prompt" and "agent" is:
- CoT: steps are just **thinking**.
- Agent: some steps are **tool calls** (search the web, call a function, query a DB).

> [!TIP]
> **What to remember**
> If [[06 - Chain of Thought Prompting]] showed *what CoT looks like*, this note shows *how to run it*. Once the loop pattern clicks, the leap to building agents is small.

---

## 7. Connection back to short-term memory

The `message_history` list is exactly [[01 - Short-Term Memory in LLMs|STM]] from Section 13.


```
message_history = [
    system prompt,
    user query,
    assistant: step 1,
    assistant: step 2,
    ...
]
```

Every turn, the **entire history** is re-sent. The LLM is stateless ([[01 - What is an LLM]]), so the application owns the state.

> [!WARNING]
> **Watch out for context overflow**
> If the model takes 50 plan steps, the history grows. Eventually it hits the context window limit (e.g., 128k tokens for GPT-4o) and the call fails. Mitigations:
> - **Summarize old plan steps** periodically.
> - **Cap max steps** (e.g., `for _ in range(20)`).
> - **Use longer-context models** (Gemini 1.5 Pro = 1M tokens).

---

## 8. Robustness — production-ready upgrades

The loop above is minimal. For real use, consider these additions:

### Cap iteration count
```python
MAX_STEPS = 20
for i in range(MAX_STEPS):
    response = ...
    if step == "output":
        break
else:
    print("⚠️  Reached max steps without producing output.")
```

### Handle JSON parse errors
```python
try:
    parsed_result = json.loads(raw_result)
except json.JSONDecodeError as e:
    print(f"❌ Bad JSON from model: {e}\nRaw: {raw_result}")
    break
```

### Handle missing fields
```python
step = parsed_result.get("step")
content = parsed_result.get("content")
if not step or content is None:
    print("❌ Missing step/content fields.")
    break
```

### Stream the thinking
For UX, stream tokens within each step so the user sees "thinking..." in real time rather than per-step blocks.

### Persist history
Save `message_history` to disk between sessions so the agent can resume conversations.

### Multi-turn (re-prompt)
After `output`, loop back to `input()` so the user can ask follow-up questions while the model retains the planning history.

> [!NOTE]
> **Adding multi-turn**

```python
while True:
    user_query = input("🙋  > ")
    if not user_query.strip():
        break
    message_history.append({"role": "user", "content": user_query})

    # inner CoT loop (same as before)
    while True:
        response = client.chat.completions.create(...)
        ...
        if step == "output":
            break
```

Now it's a full chat agent that thinks before each reply.

---

## 9. Gotchas to watch for

A common failure: the thinking goes fine, but the JSON decode blows up somewhere in the loop. When that happens with the Gemini OpenAI-compat endpoint, switching to the real OpenAI client tends to clear it up — Gemini occasionally emits malformed JSON.

Two real-world snags that show up in practice:

| Gotcha | Cause | Fix |
|---|---|---|
| JSON decode error mid-loop | Model occasionally emits malformed JSON (Gemini compat) | Use OpenAI directly; or wrap in try/except + retry |
| `model not found: gpt-4.1` against Gemini endpoint | Forgot to change model name when switching providers | Make model name a config var (see [[04 - Using Gemini through OpenAI SDK]]) |
| API key from wrong provider | `.env` mismatch | Re-source `.env`, double-check `OPENAI_API_KEY` vs `GEMINI_API_KEY` |
| Loop never terminates | Model never emits `output` step | Add `MAX_STEPS` cap |

---

## 10. The bigger pattern — call-loop-dispatch

What this loop really demonstrates is a **general architectural pattern** for LLM-driven systems:

```
┌──────────────────────────────────────────────┐
│                                              │
│    state ──→ call LLM ──→ parse reply        │
│      ↑                       │               │
│      │                       ▼               │
│      │                  dispatch on type     │
│      │                       │               │
│      │              ┌────────┼────────┐      │
│      │              ▼        ▼        ▼      │
│      │           "think"   "call    "done"   │
│      │              │       tool"      │     │
│      │              │        │         │     │
│      │              │        ▼         │     │
│      │              │     execute      │     │
│      │              │     tool         │     │
│      │              │        │         │     │
│      └──────────────┴────────┘         │     │
│                                        │     │
│                                       BREAK  │
│                                              │
└──────────────────────────────────────────────┘
```

This is essentially:
- **CoT prompting** → only "think" and "done" steps.
- **ReAct agent** → adds "call tool" and "observe result" steps.
- **Multi-agent system** → adds "delegate to other agent."
- **MCP-based tools** ([[Section 16 / MCP]]) → standardizes the tool-call payload.

Mastering this loop is mastering ~80% of what makes "AI agents" work.

---

## 11. Main takeaways

- Manual CoT (copy-paste between steps) → **`while True` loop** with `message_history`.
- Seed `message_history` with system prompt + user query.
- Loop: call → parse JSON → append to history → dispatch on `step` → break on `output`.
- Append the **raw JSON string** (not the parsed dict) to `message_history`.
- Use `response_format={"type": "json_object"}` to guarantee parseable replies.
- Emojis (🔥 🧠 🤖) make the visible reasoning more pleasant to read in the terminal.
- For production: cap max steps, handle JSON errors, persist history, add multi-turn.
- This loop pattern is the **foundation of agents** later in the course.
- `message_history` = [[01 - Short-Term Memory in LLMs|STM]] — eventually hits context limits without summarization.

---

## 12. Things I still want to figure out

- What's the ideal **MAX_STEPS** cap — task-dependent?
- How to **prune old plan steps** when history grows too long (summarize? drop oldest?)?
- Best practice for **logging/observability** in real CoT pipelines (LangSmith? OpenTelemetry?)?
- How to **stream** within a step so the UI feels alive during long plans?
- Can the dispatch handle **parallel** plan branches (Tree of Thoughts style)?
- How to make the loop **resumable** after a crash?
- Token-cost optimization — when does it make sense to use a cheap model for plans and a strong one for output?

---

## 13. Things to dig into

- **Paper**: Yao et al., *ReAct: Synergizing Reasoning and Acting in Language Models* (2023) — the foundational agent-loop pattern.
- **LangGraph docs**: https://langchain-ai.github.io/langgraph/ — production-grade implementation of this loop pattern.
- **OpenAI Assistants API** — pre-built threads + tool calling on top of this idea.
- **Hands-on**: extend this loop with a `"tool_call"` step that can search the web. That's a working ReAct agent.

---

## 14. Next up in this section

The final prompting style — making the model talk like a specific person:

- [ ] [[08 - Persona-Based Prompting]] — clone someone's tone with examples.

---

## Related
- [[06 - Chain of Thought Prompting]] — the pattern this note automates.
- [[05 - Structured Output with Few-Shot Prompting]] — the JSON-mode trick used here.
- [[01 - Short-Term Memory in LLMs]] — what `message_history` actually is.
- [[01 - What is an LLM]] — why the model is stateless (so the app must manage history).

## Sources
- Section 3, Lecture 7 — *"Automating Chain of Thought"*.
