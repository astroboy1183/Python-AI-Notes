---
title: Section Intro - Voice Agents
date: 2026-05-29
source: "Section 15 / Lecture 1"
type: lecture-notes
status: in-progress
section: "Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns"
tags:
  - voice-agents
  - conversational-ai
  - section-intro
related:
  - "[[02 - What is a Voice Agent]]"
---

# Section Intro — Voice Agents

> [!NOTE]
> **TL;DR**
> This section builds **conversational voice agents** — agents you *talk to* and that *talk back*, instead of typing text. Voice removes the friction of typing (think hands-free, driving, multitasking) and unlocks a huge class of products: sales execs, customer support, persona clones. The plan: understand **voice-to-voice agents**, the two architectures for building them — **speech-to-speech (S2S)** and the **chained architecture** — and code an agent using the chained pattern (plus a look at S2S). Voice agents are positioned as the next big thing for freelance/startup work.

> [!NOTE]
> **Where this fits**
> First note of **Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns**. It frames the section. The concept of a voice agent is unpacked in [[02 - What is a Voice Agent]], and the two architectures follow.

---

## 1. Why voice

Everything so far has been **text in, text out**. That works, but typing is friction — it keeps your hands and eyes busy. A voice agent lets you **speak a command and hear a reply**, which is far more natural for many situations (driving, cooking, walking, accessibility).

```
text agent:   type  ──►  [agent]  ──►  read
voice agent:  speak ──►  [agent]  ──►  listen
```

---

## 2. Why it matters (the opportunity)

Voice agents map onto real, monetizable problems:

| Use case | What the voice agent does |
|---|---|
| Sales executive | Qualifies leads, pitches, books calls — by voice |
| Customer support | Answers questions, resolves issues over a call |
| Persona clone | A voice that sounds and responds like a specific person |
| Hands-free assistant | Command-and-control while doing something else |

The ideas are open-ended — strong territory for freelance projects and startups.

---

## 3. What the section covers

| Topic | Note |
|---|---|
| What a voice/conversational agent is | [[02 - What is a Voice Agent]] |
| Why voice can't go straight into an LLM; the two patterns | [[03 - Why You Can't Feed Voice to an LLM]] |
| Speech-to-speech (S2S) architecture | [[04 - Speech-to-Speech (S2S) Architecture]] |
| Chained architecture (STT → LLM → TTS) | [[05 - Chained Architecture]] |
| Coding STT | [[06 - Coding STT]] |
| Adding the LLM step | [[07 - Adding the LLM Completion]] |
| Adding TTS + the conversation loop | [[08 - TTS and the Conversational Loop]] |
| Turning a tool-calling agent into a voice agent | [[09 - Voice-Enabling the Cursor Agent]] |

---

## 4. What I want to remember

- This section is about **voice agents** — speak to them, they speak back.
- Voice removes typing friction → **hands-free, natural** interaction.
- Big real-world scope: **sales, support, persona clones, assistants**.
- Two architectures: **S2S** (voice-native) and **chained** (STT → LLM → TTS).
- The build focuses on the **chained** pattern (more flexible, more common).

---

## 5. Things to dig into

- **OpenAI voice agents guide**: https://platform.openai.com/docs/guides/voice-agents
- Where voice beats text UX — and where it doesn't.

---

## 6. Next up in this section

- [ ] [[02 - What is a Voice Agent]] — what "voice in, voice out" actually means.

---

## Related
- [[02 - What is a Voice Agent]] — the concept.

## Sources
- [OpenAI voice agents](https://platform.openai.com/docs/guides/voice-agents)
