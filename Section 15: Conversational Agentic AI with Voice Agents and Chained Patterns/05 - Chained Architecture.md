---
title: Chained Architecture
date: 2026-05-29
source: "Section 15 / Lecture 5"
type: lecture-notes
status: in-progress
section: "Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns"
tags:
  - voice-agents
  - chained
  - stt
  - tts
  - architecture
related:
  - "[[04 - Speech-to-Speech (S2S) Architecture]]"
  - "[[06 - Coding STT]]"
---

# Chained Architecture

> [!NOTE]
> **TL;DR**
> The **chained architecture** builds a voice agent from three off-the-shelf stages: **STT** (speech→text) transcribes the user's audio, a normal **text-to-text LLM** (any model — GPT, Gemini, Claude) reasons over it, and **TTS** (text→speech) turns the reply into audio. Because the middle is a plain text LLM, you get **total flexibility**: pick any model, do tool calling, even drop in LangGraph/LangChain for orchestration — it's everything the course already taught, with an STT step bolted on the front and a TTS step on the back. The one cost is **higher latency** (three steps vs one), so replies take a beat longer than S2S. But the flexibility and access to **high-intelligence** models make it the more widely used, default choice.

> [!NOTE]
> **Where this fits**
> Fifth note of **Section 15** and the architecture the rest of the section codes. Contrast with [[04 - Speech-to-Speech (S2S) Architecture]]. The hands-on build starts at [[06 - Coding STT]].

---

## 1. The three-stage chain

"Chained" = transform audio→text and back, reusing existing models:

```
user audio ─►[ STT ]─► text ─►[ LLM ]─► text ─►[ TTS ]─► agent audio
            speech-to-text   text-to-text   text-to-speech
```

| Stage | Name | Does |
|---|---|---|
| 1 | **STT** (speech-to-text) | Transcribe the user's voice into text (like live captions) |
| 2 | **LLM** (text-to-text) | Reason over the text, produce a text reply (GPT-4.1, Gemini, …) |
| 3 | **TTS** (text-to-speech) | Convert the reply text into spoken audio |

Take the user's voice → STT → feed text to the LLM → take its text reply → TTS → play it back. That's the whole pattern.

---

## 2. The big win: flexibility

> [!IMPORTANT]
> **The middle is a normal text LLM — so anything goes**
> Because stage 2 is just text-to-text, you are **not locked** to a special voice model. **Every** model supports text-to-text, so you can use GPT-4.1, Gemini, Claude — whatever is best/cheapest/smartest. And since it's a regular LLM call, you keep **all** your existing tools: function/tool calling, RAG, and full orchestration with **LangGraph / LangChain**.

```
                       ┌─────────────────────────────┐
user audio ─►[STT]─► text │  LLM step — your playground │ text ─►[TTS]─► audio
                       │  • any model (GPT/Gemini/…)  │
                       │  • tool calling              │
                       │  • LangGraph / LangChain     │
                       └─────────────────────────────┘
```

Everything the course was about (orchestrating an LLM) plugs straight into the middle. Voice is just **STT in front + TTS behind**.

---

## 3. Chained vs S2S

| Dimension | Chained | S2S |
|---|---|---|
| Model choice | **Any** text LLM | Locked to S2S models |
| Intelligence | **High** (use big models) | Lower (realtime models) |
| Tooling / orchestration | Full (tools, LangGraph) | Limited |
| Cost | Cheaper / flexible | Expensive |
| Latency | **Higher** (3 steps) | Low (real-time) |
| Best for | Flexible, capable agents | Single-purpose, low-latency chat |

---

## 4. The trade-off: latency

> [!WARNING]
> **More steps = more latency**
> The chain has **three** stages, so there's a noticeable delay before the agent speaks (STT, then the LLM call, then TTS). S2S feels snappier. For most use cases the latency is acceptable, and it's the price for flexibility + access to smarter models. It's the **only real downside** of the chained pattern.

```
S2S:      [████] fast
chained:  [STT][███ LLM ███][TTS]  ← longer, but flexible & smart
```

---

## 5. Why chained is the default

- **Flexibility** — any model, any tools, any orchestration framework.
- **Intelligence** — use a big, capable model in the middle (S2S can't).
- **Ubiquity** — every text model supports text-to-text, so it always works.
- **S2S is OpenAI-only-ish today**, whereas chained works with anything.

So the build uses **chained**, and S2S is shown mainly via documentation.

---

## 6. Main takeaways

- **Chained** = **STT → LLM (text-to-text) → TTS**.
- STT transcribes voice; the LLM reasons; TTS speaks the reply.
- The middle is a **normal text LLM** → use **any** model + **tools** + **LangGraph/LangChain**.
- It reuses everything already learned; voice is just **STT front + TTS back**.
- Trade-off: **higher latency** (three steps) vs S2S.
- It's the **more flexible, more common** default; S2S is niche/realtime.

---

## 7. Things I still want to figure out

- How much **latency** does each stage add — can STT/TTS be **streamed** to hide it?
- Best **STT** and **TTS** providers for quality vs speed?
- How to handle **interruptions** in a chained loop?
- Where to slot **LangGraph** for a multi-step voice agent?

---

## 8. Things to dig into

- **OpenAI chained architecture**: https://platform.openai.com/docs/guides/voice-agents
- **Streaming TTS** to reduce perceived latency.
- Cross-links: [[06 - Coding STT]], [[07 - Adding the LLM Completion]], [[08 - TTS and the Conversational Loop]].

---

## 9. Next up in this section

- [ ] [[06 - Coding STT]] — build the first stage: capture the user's voice and transcribe it.

---

## Related
- [[04 - Speech-to-Speech (S2S) Architecture]] — the alternative pattern.
- [[06 - Coding STT]] — stage 1 of the chain.

## Sources
- [OpenAI voice agents (chained)](https://platform.openai.com/docs/guides/voice-agents)
