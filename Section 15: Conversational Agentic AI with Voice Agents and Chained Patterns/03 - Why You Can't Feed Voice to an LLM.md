---
title: Why You Can't Feed Voice to an LLM
date: 2026-05-29
source: "Section 15 / Lecture 3"
type: lecture-notes
status: in-progress
section: "Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns"
tags:
  - voice-agents
  - transformers
  - architecture
  - s2s
  - chained
  - foundations
related:
  - "[[02 - What is a Voice Agent]]"
  - "[[04 - Speech-to-Speech (S2S) Architecture]]"
  - "[[05 - Chained Architecture]]"
---

# Why You Can't Feed Voice to an LLM

> [!NOTE]
> **TL;DR**
> A transformer takes **tokens** (numbers) and predicts the **next tokens** — that's all it does. Voice is a **continuous waveform / spectrum**, and everyone's accent, pitch, pace, and timbre differ, so you can't just hand a wave to a transformer and expect sensible "voice probabilities" out. (And even if you got probabilities, stitching them into natural, expressive speech with varying pitch is its own hard problem.) So today there are **two patterns** for building voice agents: **speech-to-speech (S2S)** and the **chained architecture** (STT → LLM → TTS). The chained pattern is the workhorse — it's the most common, and S2S internally does much the same thing under the hood. Master chained, and S2S becomes easy.

> [!NOTE]
> **Where this fits**
> Third note of **Section 15**. It explains the core constraint and names the two architectures, each detailed next: [[04 - Speech-to-Speech (S2S) Architecture]] and [[05 - Chained Architecture]].

---

## 1. What a transformer actually consumes

Recall from Section 1: a transformer's input is **tokens** — numbers — and its job is to **predict the next set of tokens**.

```
tokens (numbers) ──►  [ transformer ]  ──►  probabilities over next tokens
```

It's a next-token predictor over a **discrete vocabulary**. That's the whole machine.

---

## 2. Why voice doesn't fit

Voice isn't tokens — it's a **continuous waveform** (a spectrum / wave over time).

```
text:   "hello"  → discrete tokens [15496]
voice:  ∿∿∿∿∿∿∿   → a continuous analog wave
```

Why you can't just feed the wave in:

- **Everyone sounds different** — accent, pitch, pace, timbre, speech length. The same word is a different wave for every speaker.
- **No natural "voice vocabulary"** — there's no clean discrete token set for "all possible sounds" the way there is for text.
- **Expressiveness** — even if a model output sound probabilities, making them flow into natural speech (pitch rising when excited, dropping when serious) is a separate, hard problem.

> [!WARNING]
> **"Voice in → voice probabilities out" doesn't work on a text transformer**
> You can't feed a waveform to a vanilla LLM and expect meaningful spoken output. The architecture is built for discrete tokens, not analog audio. Some end-to-end audio models exist (and are improving), but the practical, flexible approach today is to **convert** audio ↔ text around the LLM.

---

## 3. The two patterns

Given that constraint, there are **two ways** to build a voice agent today:

| Pattern | Idea | Note |
|---|---|---|
| **Speech-to-Speech (S2S)** | A model handles audio **natively** — voice in, voice out | [[04 - Speech-to-Speech (S2S) Architecture]] |
| **Chained architecture** | Convert audio→text, run a normal LLM, convert text→audio | [[05 - Chained Architecture]] |

```
S2S:      voice ─────────►[ audio-native model ]─────────► voice
chained:  voice ─►[STT]─► text ─►[ LLM ]─► text ─►[TTS]─► voice
```

---

## 4. Why chained is "the meat"

> [!IMPORTANT]
> **Chained is the core skill — and S2S uses it under the hood**
> The chained architecture is the **commonly used** one, and even speech-to-speech systems internally do something very similar (transcribe → reason → synthesize). So the chained pattern is the foundational piece. **Learn chained well, and S2S becomes easy** — it's largely the same flow, optimized for low latency and wrapped behind a single model/API.

---

## 5. Main takeaways

- A transformer consumes **tokens** and predicts **next tokens** — nothing else.
- Voice is a **continuous waveform**; accents/pitch/pace make it unfit for direct token input.
- Even with sound probabilities, producing **natural, expressive** speech is hard.
- Two patterns today: **S2S** (audio-native) and **chained** (STT → LLM → TTS).
- **Chained is the workhorse**; S2S internally resembles it.
- Mastering chained makes S2S straightforward.

---

## 6. Things I still want to figure out

- How do **end-to-end audio models** (true S2S) actually tokenize sound?
- What's the **latency** difference between S2S and chained in practice?
- Where does S2S genuinely beat chained (and vice versa)?
- How do STT/TTS models handle **accents** and noisy input?

---

## 7. Things to dig into

- **OpenAI: choosing a voice agent architecture**: https://platform.openai.com/docs/guides/voice-agents
- **Audio tokenization** in speech models (codec-based tokens).
- Cross-links: [[04 - Speech-to-Speech (S2S) Architecture]], [[05 - Chained Architecture]].

---

## 8. Next up in this section

- [ ] [[04 - Speech-to-Speech (S2S) Architecture]] — the audio-native, low-latency pattern.

---

## Related
- [[02 - What is a Voice Agent]] — the goal this constrains.
- [[04 - Speech-to-Speech (S2S) Architecture]] / [[05 - Chained Architecture]] — the two patterns.

## Sources
- [OpenAI voice agent architectures](https://platform.openai.com/docs/guides/voice-agents)
