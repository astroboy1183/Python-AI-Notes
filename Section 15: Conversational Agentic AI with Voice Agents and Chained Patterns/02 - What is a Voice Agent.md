---
title: What is a Voice Agent
date: 2026-05-29
source: "Section 15 / Lecture 2"
type: lecture-notes
status: in-progress
section: "Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns"
tags:
  - voice-agents
  - conversational-ai
  - foundations
related:
  - "[[01 - Section Intro - Voice Agents]]"
  - "[[03 - Why You Can't Feed Voice to an LLM]]"
---

# What is a Voice Agent

> [!NOTE]
> **TL;DR**
> So far the loop has been **text tokens in → text tokens out** (GPT-4.1, Gemini), wrapped with tool calling to make agents. A **voice agent** swaps the modality: the user **speaks** (audio in), and the agent **speaks back** (audio out). The intelligence in the middle is still an LLM — what changes is the interface around it. The payoff is a **hands-free, frictionless** experience: instead of typing to ChatGPT, you just talk, and it replies in a natural voice. That's a **conversational voice AI agent**.

> [!NOTE]
> **Where this fits**
> Second note of **Section 15**. It defines the goal; [[03 - Why You Can't Feed Voice to an LLM]] explains why you can't just pipe audio into an LLM directly.

---

## 1. Where we've been: text in, text out

Every agent so far has used a **text** interface to the model:

```
text tokens ──►  [ LLM: GPT-4.1 / Gemini ]  ──►  text tokens
                    + tool calling
```

Input some text, get back some text, layer tool calls on top → that's how the weather agent, the coding assistant, and the RAG bots worked.

---

## 2. The voice agent: voice in, voice out

A voice agent keeps the LLM intelligence but changes both ends to **audio**:

```
audio (user speaks) ──►  [ intelligence / LLM ]  ──►  audio (agent speaks)
```

> [!IMPORTANT]
> **The brain is still an LLM**
> "Voice agent" doesn't mean a fundamentally different model — it means an LLM with **audio at the input and output edges**. The reasoning, tool calling, and orchestration are the same skills from the rest of the course; voice is the new wrapper. (Exactly *how* audio connects to a text model is the subject of [[03 - Why You Can't Feed Voice to an LLM]].)

---

## 3. Why voice — the friction argument

People gravitate to whatever is **easiest**. Even typing a prompt takes time and keeps your hands busy. Voice removes that:

| Situation | Typing | Speaking |
|---|---|---|
| Driving | ❌ unsafe / impossible | ✅ hands-free |
| Cooking / busy hands | ❌ | ✅ |
| Quick command | slower | instant |
| Accessibility | barrier for some | natural |

The vision: talk to the AI like you'd talk to a person ("hey, go do this") and it acts and replies in voice — a **complete hands-free experience**.

```
"Hey agent, add milk to my list."   ──►   🔊 "Done — milk added."
```

---

## 4. The scope is enormous

Because voice is just a new interface over capable agents, the application space is wide open — sales, support, assistants, persona clones (from [[01 - Section Intro - Voice Agents]]). If you can build a text agent for a task, you can give it a voice.

---

## 5. Main takeaways

- Past agents: **text tokens in → text tokens out** + tool calling.
- A **voice agent**: **audio in → audio out**, with an LLM still doing the thinking.
- Voice is an **interface change**, not a different kind of intelligence.
- The driver is **friction**: speaking is faster and **hands-free** vs typing.
- Scope is huge — any text agent can become a voice agent.

---

## 6. Things I still want to figure out

- How does audio actually reach a **text-based** LLM? (Next note.)
- What's the **latency** of a voice round-trip, and does it feel natural?
- How is **tool calling** preserved when the interface is voice?
- How to capture **tone/emotion** in the agent's spoken reply?

---

## 7. Things to dig into

- **OpenAI voice agents guide**: https://platform.openai.com/docs/guides/voice-agents
- Real products built as voice agents (support bots, voice assistants).

---

## 8. Next up in this section

- [ ] [[03 - Why You Can't Feed Voice to an LLM]] — why audio needs converting, and the two patterns.

---

## Related
- [[01 - Section Intro - Voice Agents]] — the section framing.
- [[03 - Why You Can't Feed Voice to an LLM]] — the technical reality.

## Sources
- [OpenAI voice agents](https://platform.openai.com/docs/guides/voice-agents)
