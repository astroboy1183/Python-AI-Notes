---
title: Chain of Thought Prompting
date: 2026-05-28
source: "Section 3 / Lecture 6"
type: lecture-notes
status: in-progress
section: "Section 3: Advanced Prompt Engineering Techniques"
tags:
  - prompts
  - chain-of-thought
  - cot
  - reasoning
  - structured-output
  - prompt-engineering
  - o1
  - o3
  - deepseek
  - reasoning-models
  - hands-on
related:
  - "[[05 - Structured Output with Few-Shot Prompting]]"
  - "[[03 - The Transformer - Predicting the Next Token]]"
  - "[[01 - Short-Term Memory in LLMs]]"
---

# Chain of Thought Prompting

> [!NOTE]
> **TL;DR**
> **Chain of Thought (CoT)** prompting tells the LLM to **think step by step before answering**, rather than emitting the final answer directly. The model first produces a **plan** (often multiple planning steps), then the **output**. Mimics human reasoning: rather than blurt out an answer, decompose → plan → solve → verify → finalize. This is the prompting style behind **OpenAI's o1 / o3 models** and **DeepSeek R1** — they're essentially CoT-trained from the ground up. Implementation pattern: declare a JSON schema with `step` ∈ {"start", "plan", "output"} and `content`, then **loop** — each call produces one step, append to history, call again, until `step == "output"`. Output quality jumps dramatically for math, code, and complex reasoning. Personal favorite of mine.

> [!NOTE]
> **Where this fits**
> Sixth note of **Section 3: Advanced Prompt Engineering Techniques**. Combines [[04 - Few-Shot Prompting]] (the examples that teach the pattern) + [[05 - Structured Output with Few-Shot Prompting]] (the JSON schema for each step). The next note ([[07 - Automating Chain of Thought]]) wraps this in a clean loop. Foundation for all the **agent** work later in the course.

> [!TIP]
> **Why this matters so much**
> If you've ever used DeepSeek or OpenAI's o3 — those are built on chain of thought prompting. They think before they act. This is a personal favorite and one of the most important patterns in the entire section.

---

## 1. The problem CoT solves

Default LLM behavior: input → **single forward pass** → final answer.

For simple questions, that's fine. But for hard questions (math word problems, multi-step code, logical puzzles), the model often:
- Skips intermediate steps.
- Makes arithmetic errors.
- Loses track of constraints.
- Outputs plausible-but-wrong answers.

This is because the autoregressive loop ([[03 - The Transformer - Predicting the Next Token]]) gets very little "budget" between input and final answer. There's no scratchpad to think on.

### CoT gives the model a scratchpad

The goal is to make the model **think first, answer second** — just like a human coder mulls things over before committing to a solution. The internal monologue might go: *"the user wants code; there are multiple ways to solve this; option two is more optimal — let me go with that."* Forcing the LLM to externalise that monologue raises accuracy noticeably.

CoT changes the loop to: input → **plan step 1** → **plan step 2** → ... → **final output**. Each step's reasoning becomes part of the next step's input, building up rich context before the final answer is produced.

---

## 2. The pattern

Three components:

1. **System prompt** declaring the step sequence and JSON schema.
2. **Examples** (few-shot) showing one full multi-step trace.
3. **Loop** — call the LLM, get one step, append to history, call again, until `step == "output"`.

This note implements steps 1–2; [[07 - Automating Chain of Thought]] handles step 3.

---

## 3. The system prompt

```text
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

A: {"step": "start", "content": "Can you solve 2 + 3 * 5 / 10?"}

A: {"step": "plan", "content": "Seems like the user is interested in a maths problem around BODMAS."}

A: {"step": "plan", "content": "Looking at the problem, we should solve this using the BODMAS method."}

A: {"step": "plan", "content": "First we must multiply 3 by 5, which gives 15."}

A: {"step": "plan", "content": "Now the new equation is 2 + 15 / 10."}

A: {"step": "plan", "content": "Next, we must perform the divide: 15 / 10 = 1.5."}

A: {"step": "plan", "content": "Now the new equation looks like 2 + 1.5."}

A: {"step": "plan", "content": "Finally let's perform the add: 2 + 1.5 = 3.5."}

A: {"step": "plan", "content": "Great, we have solved it and are left with 3.5 as the answer."}

A: {"step": "output", "content": "3.5"}
```

> [!TIP]
> **What the example teaches**
> The model learns from this single example:
> - **One step per response** (don't dump everything at once).
> - **Step types**: `start` echoes the question, `plan` thinks, `output` is the final answer.
> - **Granularity**: each `plan` is one atomic thought.
> - **Sequence**: start → many plans → output.
> - **JSON shape**: every step has exactly two fields.

---

## 4. The (manual) loop

The full automation comes in [[07 - Automating Chain of Thought]]. For this note, walk through it manually:

### Step 1 — initial call
```python
import json
from openai import OpenAI
client = OpenAI()

messages = [
    {"role": "system", "content": system_prompt},
    {"role": "user",   "content": "Write a code to add n numbers in JavaScript."},
]

response = client.chat.completions.create(
    model="gpt-4o",
    response_format={"type": "json_object"},
    messages=messages,
)

print(response.choices[0].message.content)
# → {"step": "start", "content": "Write a code to add n numbers in JavaScript."}
```

### Step 2 — manually append and call again
```python
messages.append({
    "role": "assistant",
    "content": json.dumps({"step": "start", "content": "Write a code to add n numbers in JavaScript."}),
})

response = client.chat.completions.create(
    model="gpt-4o",
    response_format={"type": "json_object"},
    messages=messages,
)

print(response.choices[0].message.content)
# → {"step": "plan", "content": "I need to provide a JavaScript function that can add any number of arguments..."}
```

### Step 3 — keep appending
Each successive response is one more step. After several `plan` steps, the model finally emits `{"step": "output", "content": "<final code>"}`.

Watching the trace, the model visibly reasons: *"I need to provide a JavaScript function that can add any number of arguments… I will use the rest parameter… I'll use Array.reduce…"* Each line is a thinking step. Once enough thinking is done, it emits the final output — the actual code.

This pattern is what makes the model's reasoning **visible**. Every step is logged. Easy to debug, audit, or display in a UI ("thinking..." spinner with the current plan step).

---

## 5. Why this works — the key insight

> The autoregressive loop ([[03 - The Transformer - Predicting the Next Token]]) gives each output token influence over the next. By forcing intermediate reasoning into the output, **the reasoning becomes input for the final answer**.

Without CoT:
```
[input] → [LLM] → [final answer]
              ^
              | only ~one forward pass of compute between input and answer
```

With CoT:
```
[input]                      → [LLM] → [plan 1]
[input, plan 1]              → [LLM] → [plan 2]
[input, plan 1, plan 2]      → [LLM] → [plan 3]
...
[input, plan 1, ..., plan N] → [LLM] → [final answer]
              ^
              | each step builds on previous; model effectively gets N "passes" to think
```

The total compute budget is **N× higher**, but spent on intermediate reasoning that grounds the final answer.

---

## 6. CoT vs. reasoning models (o1, o3, DeepSeek R1)

OpenAI's o-series and DeepSeek's R1 essentially **build CoT into the model itself**:

| Aspect | Prompt-engineered CoT (this note) | Reasoning models (o1/o3/R1) |
|---|---|---|
| Implementation | System prompt + few-shot + loop | Built into model weights via RL |
| Visibility | Each step explicit in messages | Hidden "thinking" tokens internally |
| Cost | More tokens, longer prompt | Much higher per-call cost (charged for hidden thinking) |
| Latency | Per-step round-trips | One call (but slower) |
| Accuracy on hard problems | Big jump over zero-shot | Even bigger jump |
| When to use | Want control + visibility | Want best accuracy, willing to pay |
| Customization | Full control over schema | Limited (model decides reasoning style) |

> [!NOTE]
> **The lesson**
> Even with reasoning models available, **CoT prompting in plain models is still useful**:
> - Visibility into reasoning (debugging, audit, UI).
> - Cheaper than reasoning models.
> - Customizable schema (e.g., "always check for X").
> - Works on any model, including local LLMs.

---

## 7. CoT example schemas (beyond the basic one)

The basic schema above uses `{"step": ..., "content": ...}`. Other useful schemas:

### Plan-then-execute
```json
{ "phase": "plan" | "execute" | "verify" | "output", "content": "..." }
```

### Tool-calling agent
```json
{
  "step": "think" | "tool_call" | "observe" | "answer",
  "content": "...",
  "tool": "search" | "calculator" | null,
  "tool_args": {...}
}
```

### Self-critique
```json
{ "step": "draft" | "critique" | "revise" | "final", "content": "..." }
```

### Confidence-aware
```json
{ "step": "plan" | "output", "content": "...", "confidence": 0.0-1.0 }
```

All variants share the same idea: **make the reasoning visible and structured**.

---

## 8. The downside — cost and latency

CoT isn't free:

| Cost | Magnitude |
|---|---|
| **Tokens** | 5–20× more output tokens than zero-shot for the same answer. |
| **Latency** | Each step is a separate API call → N× round-trip time. |
| **Cost** | Higher per-question due to both token volume and call count. |

> [!TIP]
> **Mitigations**
> - Use **prompt caching** so the long system prompt isn't reprocessed each step.
> - Use **streaming** to give the user "thinking" feedback in real time.
> - Use a **cheaper model** (`gpt-4o-mini`) for routine planning steps; bigger model only for the final output.
> - **Skip CoT for easy questions** — use it conditionally based on question complexity.

For learning + agentic-AI work, the cost is worth it. CoT is what makes complex agents reliable.

---

## 9. Worked demo flow

Manually building this for the question:
> *"Write a code to add n numbers in JavaScript."*

Trace (illustrative):

| Step | Content |
|---|---|
| `start` | "Write a code to add n numbers in JavaScript." |
| `plan` | "I need to provide a JavaScript function that adds any number of arguments." |
| `plan` | "I will define the function using the rest parameter (`...args`) to accept arbitrary arguments." |
| `plan` | "To make it efficient, I'll use `Array.reduce` for summation." |
| `plan` | "For caching, I could memoize, but let's keep it simple for now." |
| `output` | `function addNumbers(...nums) { return nums.reduce((a, b) => a + b, 0); }` |

Each step is one API call. The full code (the `output`) is then ready for use.

---

## 10. Mental model — when to use CoT

| Use CoT for | Skip CoT for |
|---|---|
| Math word problems | "Translate this to French" |
| Multi-step code generation | "Summarize this in one sentence" |
| Logical / reasoning puzzles | Single-fact lookups |
| Decision-making (which option?) | Simple Q&A from context |
| Debugging (where's the bug?) | Yes/no classification |
| Tool-using agents (which tool, why?) | One-shot transformations |
| Anywhere accuracy >> speed | Anywhere latency matters most |

---

## 11. Main takeaways

- **Chain of Thought (CoT)** prompting forces the model to **think step by step** before producing a final answer.
- Implementation: structured output (`{"step": ..., "content": ...}`) + loop that appends each step to history and calls again.
- Sequence: `start` → many `plan` steps → final `output`.
- Each step's reasoning becomes **input context** for the next — model effectively gets N forward passes to "think."
- Big accuracy jumps on math, code, multi-step problems.
- **OpenAI o-series and DeepSeek R1** are CoT baked into the model — same idea, no manual loop needed.
- Manual CoT is **cheaper, more controllable, more visible** than reasoning models — still worth using.
- Downsides: more tokens, more API calls, more latency.
- **Use selectively** — not every question benefits.

---

## 12. Things I still want to figure out

- Best practices for **deciding when to stop planning** — is "step == output" the only signal?
- How to handle the case where the model **never** emits an output step (infinite loop guard)?
- Optimal **example length** in the few-shot demonstration — 1 full trace? Multiple?
- Can multiple plans be **parallelized** (different angles), then merged?
- How does CoT interact with **structured outputs** strict mode?
- Should the system prompt **forbid** mixing roles (e.g., always one step per response)?
- How to **summarize old plan steps** when the history gets very long?

---

## 13. Things to dig into

- **Paper**: Wei et al., *Chain-of-Thought Prompting Elicits Reasoning in Large Language Models* (2022) — the seminal CoT paper.
- **Paper**: Kojima et al., *Large Language Models are Zero-Shot Reasoners* (2022) — discovered that just "Let's think step by step" can elicit CoT zero-shot.
- **Paper**: Yao et al., *Tree of Thoughts* (2023) — extends CoT to a tree-search exploration.
- **Paper**: Shinn et al., *Reflexion* (2023) — adds self-critique to CoT.
- **OpenAI o1 / o3 docs** — see how built-in reasoning compares to manual CoT.
- **Hands-on**: take a hard math problem. Compare zero-shot vs CoT accuracy on it.

---

## 14. Next up in this section

The manual loop above is tedious. The next note automates it:

- [ ] [[07 - Automating Chain of Thought]] — wrap the step-by-step process in a clean Python loop.

---

## Related
- [[05 - Structured Output with Few-Shot Prompting]] — the JSON-schema foundation.
- [[04 - Few-Shot Prompting]] — examples teach the multi-step pattern.
- [[03 - The Transformer - Predicting the Next Token]] — why the autoregressive loop makes CoT work.
- [[01 - Short-Term Memory in LLMs]] — every CoT step appends to STM; long traces eventually hit context limits.

## Sources
- Section 3, Lecture 6 — *"Chain of Thought Prompting"*.
