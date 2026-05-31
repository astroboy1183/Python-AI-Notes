---
title: ReAct - Reasoning and Acting
date: 2026-05-31
source: Self-authored reference notes
type: reference-notes
status: complete
section: "Section 23: Advanced Reasoning & Prompting"
tags:
  - reasoning
  - react
  - agents
  - prompting
  - foundations
related:
  - "[[06 - Chain of Thought Prompting]]"
  - "[[02 - What are AI Agents]]"
---

# ReAct - Reasoning and Acting

> [!NOTE]
> **TL;DR**
> **ReAct (Reasoning + Acting)** is the pattern that powers most tool-using agents — and I've already built it without naming it (the agent loop in §7). The idea: interleave **Thought** (reasoning about what to do), **Action** (call a tool), and **Observation** (the tool's result), looping until the answer is reached. It marries **chain-of-thought** (§3 — reason step by step) with **tool use** (§7 — act on the world), so the model can *think*, *gather real information*, and *think again* with that information in hand. This beats pure CoT (which can only reason about what it already knows and may hallucinate facts) and pure tool-calling (which acts without deliberation). The trace `Thought → Action → Observation → Thought → ...` is the canonical agent loop.

> [!NOTE]
> **Where this fits**
> First note of **Section 23: Advanced Reasoning & Prompting**. It names and formalizes the loop behind §7's agents and connects it to CoT (§3). Reflection (note 02) and search-based reasoning (note 03) build on it.

---

## 1. Two halves that needed joining

| Pattern | Strength | Weakness |
|---|---|---|
| **Chain-of-thought** (§3) | Reasons step by step | Only uses **internal** knowledge; can hallucinate facts |
| **Tool calling** (§7) | Acts on the world (search, calc, APIs) | No deliberation between/around actions |

ReAct combines them: **reason about what to do → do it → observe the result → reason again.**

---

## 2. The ReAct loop

```
Question
  ▼
Thought:     "I need the current weather in Bangalore."
Action:      get_weather("Bangalore")
Observation: "32°C, sunny"
Thought:     "Now I can answer."
Answer:      "It's 32°C and sunny in Bangalore."
   (loop Thought→Action→Observation until the model is ready to answer)
```

> [!IMPORTANT]
> **You've already built ReAct**
> The weather agent and CLI coding assistant in §7 are ReAct agents: the LLM **reasons** about which tool to call, **calls** it, reads the **result**, and continues. Naming it matters because it's the vocabulary the whole field uses — "an agent" almost always means "a ReAct-style loop."

---

## 3. Why interleaving wins

- **Grounding**: actions fetch **real** data (search, DB, calculator), so reasoning isn't limited to (possibly stale/hallucinated) parametric knowledge — directly fights hallucination (§19).
- **Adaptivity**: each observation informs the next thought — the model can change course based on what it finds.
- **Decomposition**: complex tasks become a sequence of think-act steps instead of one giant leap.

```
pure CoT:   "I think the population is ~8 million"   (guess, maybe wrong)
ReAct:      Action: search("population of X") → Observation: "8.4M" → grounded answer
```

---

## 4. How it's implemented

Two common implementations:

| Style | How | Where |
|---|---|---|
| **Prompted ReAct** | A prompt instructs the model to output `Thought:/Action:/Observation:`; you parse the Action, run the tool, append the Observation, re-prompt | classic, model-agnostic |
| **Native tool-calling** | The model emits a structured **tool call** (function calling, §7); the runtime executes and returns the result | modern default (OpenAI/Anthropic) |

Modern apps mostly use **native tool-calling** — it's ReAct with the Thought/Action/Observation handled structurally by the API rather than parsed from text. Same loop, cleaner mechanics.

```python
# native tool-calling = ReAct loop (conceptual, from §7)
while True:
    resp = llm(messages, tools=tools)        # Thought + maybe Action
    if resp.tool_calls:
        result = run_tool(resp.tool_calls)    # Observation
        messages += [resp, result]
    else:
        return resp.content                   # Answer
```

---

## 5. ReAct vs the alternatives

```
Standard prompt:  Q → A                          (no reasoning shown, no acting)
Chain-of-thought: Q → reason → A                 (reasoning, no acting)
Tool calling:     Q → act → A                    (acting, little reasoning)
ReAct:            Q → (think → act → observe)* → A  (both, looped)
```

ReAct is the foundation; the rest of this section adds **self-correction** (reflection, note 02) and **search over multiple paths** (note 03) on top of it.

---

## 6. Limits and caveats

- **Loops/cost**: like any agent loop, it can spiral — needs a step cap (§22/§20).
- **Error compounding**: a bad observation or tool error can derail subsequent reasoning — handle tool failures gracefully.
- **Latency**: each step is a round-trip (§20).
- **Tool reliability**: ReAct is only as good as its tools and their outputs.

These are the same agent concerns from §7/§22 — ReAct is the loop they all sit inside.

---

## 7. Main takeaways

- **ReAct = Reasoning + Acting**, interleaved: **Thought → Action → Observation → ...** until an answer.
- It marries **chain-of-thought** (reason) with **tool calling** (act).
- The §7 agents you built **are ReAct agents** — this just names the pattern.
- Beats pure CoT (grounds reasoning in real data, fights hallucination) and pure tool-calling (adds deliberation).
- Implemented via **prompted** Thought/Action/Observation or **native tool-calling** (modern default).
- Caveats: loops/cost, error compounding, latency, tool reliability — cap the loop.
- It's the **foundation** for reflection (note 02) and search-based reasoning (note 03).

---

## 8. Things I still want to figure out

- Prompted ReAct vs native tool-calling — any quality difference, or just mechanics?
- Best way to handle a **tool error** mid-loop without derailing?
- How many steps before capping for typical tasks?

---

## 9. Things to dig into

- **ReAct** paper ("Synergizing Reasoning and Acting").
- Native **tool/function calling** docs (§7).
- Next: [[02 - Reflection and Self-Critique]].

---

## 10. Next up in this section

- [ ] [[02 - Reflection and Self-Critique]] — let the model check and improve its own work.

---

## Related
- [[06 - Chain of Thought Prompting]] — the "reasoning" half.
- [[02 - What are AI Agents]] — the agent loop ReAct formalizes.

## Sources
- [ReAct paper](https://arxiv.org/abs/2210.03629)
- [OpenAI function calling](https://platform.openai.com/docs/guides/function-calling)
