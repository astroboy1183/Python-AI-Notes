---
title: Speech-to-Speech (S2S) Architecture
date: 2026-05-29
source: "Section 15 / Lecture 4"
type: lecture-notes
status: in-progress
section: "Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns"
tags:
  - voice-agents
  - s2s
  - real-time
  - architecture
related:
  - "[[03 - Why You Can't Feed Voice to an LLM]]"
  - "[[05 - Chained Architecture]]"
---

# Speech-to-Speech (S2S) Architecture

> [!NOTE]
> **TL;DR**
> **Speech-to-speech (S2S)** = the model handles audio **natively**: voice in → voice out, with no explicit text step. You take the user's audio, send it straight to an S2S model (which can still do tool calling, search, handoffs), and get audio back. It's a **real-time, low-latency** architecture — great for natural, free-flowing conversation. The trade-offs: it's **very expensive**, **locked to a specific model** (e.g. OpenAI's realtime `4o`), best suited to a **single scoped agent** (one customer-support bot, one sales bot), and those realtime models are strong talkers but **lower in raw intelligence**. Under the hood, S2S does essentially what the chained pattern does — just optimized for latency.

> [!NOTE]
> **Where this fits**
> Fourth note of **Section 15**, the first of the two architectures from [[03 - Why You Can't Feed Voice to an LLM]]. [[05 - Chained Architecture]] covers the more flexible alternative that the build uses.

---

## 1. What S2S means

Per OpenAI's "choosing an architecture" guide, the first option is **speech-to-speech: native audio handling by the model**. Input is a **speech**; output is a **speech** — no text in between.

```
audio (user) ──►  [ S2S model ]  ──►  audio (agent)
                  native audio
                  (no text step)
```

You're dealing **only** with voice — no transcription, no text generation surfaced to you.

---

## 2. How it flows

```
┌──────────────┐     user audio     ┌─────────────────────┐   audio out
│ user speaks  │ ─────────────────► │ Agent (S2S model)   │ ───────────►  🔊
└──────────────┘                    │  • tool calling      │
                                    │  • search / handoff  │
                                    └─────────────────────┘
```

The agent can still bind **tools**, do **search**, and **hand off** — all the agentic behaviour — but the I/O is audio, end to end, sent via API.

---

## 3. The upside: real-time and natural

> [!TIP]
> **Low latency is the headline feature**
> S2S is a **real-time, low-latency** system. Because there's no multi-step pipeline to traverse, replies come back fast, making the conversation feel natural and immediate — closest to talking to a human.

---

## 4. The trade-offs

| Limitation | Detail |
|---|---|
| **Expensive** | S2S/realtime APIs cost significantly more |
| **Model-locked** | You must use a model that supports S2S (e.g. OpenAI realtime `4o`) — no Gemini/Claude swap |
| **Narrowly scoped** | Best for **one specific agent** (e.g. one support bot), not complex multi-step structured flows |
| **Unstructured** | Natural free-flowing chat, but no structured conversation control |
| **Lower intelligence** | Realtime voice models are good *talkers* but weaker in raw reasoning |

> [!WARNING]
> **You're tied to the S2S model's intelligence**
> If you need a very capable reasoning model, S2S limits you — you can only pick from models that support speech-to-speech, and those tend to prioritize fast, natural speech over deep intelligence. (The chained pattern removes this constraint — [[05 - Chained Architecture]].)

---

## 5. Under the hood

> [!IMPORTANT]
> **S2S internally resembles the chained pattern**
> Even a speech-to-speech model is, conceptually, doing something like: take the voice → understand it → produce a response → render it as audio — just fused and tuned for **low latency**. That's why understanding the chained architecture (next note) makes S2S easy to reason about.

```
S2S (what you see):   voice ─────────────────► voice
S2S (conceptually):   voice → [understand → respond → synthesize] → voice
                                  (similar to STT → LLM → TTS, fused + fast)
```

---

## 6. When to choose S2S

- You want the **most natural, lowest-latency** conversation.
- The agent is **single-purpose** (support, sales) and doesn't need deep reasoning or complex orchestration.
- **Cost** and **model lock-in** are acceptable.

Otherwise, the chained architecture is usually the better default.

---

## 7. Main takeaways

- **S2S** = native audio: **voice in → voice out**, no text step.
- It's **real-time and low-latency** → very natural conversation.
- Can still do **tool calling, search, handoff**.
- Downsides: **expensive**, **model-locked** (e.g. realtime `4o`), **single-scoped**, **lower intelligence**.
- Internally it's **similar to the chained pattern**, optimized for latency.
- Choose it for natural, single-purpose, latency-critical agents.

---

## 8. Things I still want to figure out

- How much **more expensive** is S2S vs a chained setup in practice?
- Which providers offer **true S2S** today besides OpenAI realtime?
- How does S2S handle **interruptions** / barge-in (talking over the agent)?
- Can S2S agents do **multi-tool** workflows reliably?

---

## 9. Things to dig into

- **OpenAI realtime / S2S**: https://platform.openai.com/docs/guides/realtime
- **Voice agent architectures**: https://platform.openai.com/docs/guides/voice-agents
- Compare latency: S2S vs chained.

---

## 10. Next up in this section

- [ ] [[05 - Chained Architecture]] — the flexible STT → LLM → TTS pattern used for the build.

---

## Related
- [[03 - Why You Can't Feed Voice to an LLM]] — why the two patterns exist.
- [[05 - Chained Architecture]] — the alternative (and what S2S resembles internally).

## Sources
- [OpenAI realtime](https://platform.openai.com/docs/guides/realtime)
- [OpenAI voice agents](https://platform.openai.com/docs/guides/voice-agents)
