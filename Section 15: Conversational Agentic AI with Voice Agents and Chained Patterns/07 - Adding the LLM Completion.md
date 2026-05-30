---
title: Adding the LLM Completion
date: 2026-05-29
source: "Section 15 / Lecture 7"
type: lecture-notes
status: in-progress
section: "Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns"
tags:
  - voice-agents
  - chained
  - openai
  - system-prompt
  - python
  - hands-on
related:
  - "[[06 - Coding STT]]"
  - "[[08 - TTS and the Conversational Loop]]"
---

# Adding the LLM Completion

> [!NOTE]
> **TL;DR**
> Stage 2 of the chain: take the STT transcript and run a normal OpenAI chat completion. Build a `client = OpenAI()`, `load_dotenv()`, then call `client.chat.completions.create(model="gpt-4.1-mini", messages=[...])` with the **STT text as the user message**. The key touch is a **system prompt** that tells the model it's a **voice agent**: it's given a transcript of what the user *said*, and its reply will be **converted back to audio and played**, so it should respond as a voice agent (not a wall of text). Since this is a plain text-to-text call, any model works (Gemini, Claude, …) — exactly the flexibility the chained architecture promised. Copy the `.env` over for `OPENAI_API_KEY`. Output: a sensible spoken-style reply, ready for TTS.

> [!NOTE]
> **Where this fits**
> Seventh note of **Section 15** — the middle stage of the chain. STT (from [[06 - Coding STT]]) produces text; this turns it into a reply. [[08 - TTS and the Conversational Loop]] speaks that reply and loops it.

---

## 1. Stage 2: text in, text out

STT gave a transcript. Now feed it to a regular LLM — the same `chat.completions.create` from earlier sections:

```python
from dotenv import load_dotenv
load_dotenv()

from openai import OpenAI
client = OpenAI()
```

```
STT text ─►[ LLM (gpt-4.1-mini) ]─► reply text
```

> [!IMPORTANT]
> **This is just a normal completion — so any model works**
> Stage 2 is plain text-to-text. The flexibility from [[05 - Chained Architecture]] is real here: swap `gpt-4.1-mini` for Gemini or Claude and nothing else changes.

---

## 2. The system prompt — make it behave like a voice agent

The crucial addition is a **system prompt** telling the model the context it's operating in:

```python
system_prompt = (
    "You are an expert voice agent. You are given the transcript of what "
    "the user said using their voice. Respond as a voice agent — whatever "
    "you say will be converted back to audio using AI and played to the user."
)
```

> [!TIP]
> **Why this matters**
> Without it, the model replies like a text chatbot — long, with markdown, lists, code fences — which sounds terrible read aloud. Telling it "you are a voice agent and your words will be spoken" nudges it toward **short, natural, speakable** replies. The reply is destined for TTS, so it should *sound* right, not *look* right.

---

## 3. The completion call

```python
response = client.chat.completions.create(
    model="gpt-4.1-mini",
    messages=[
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": stt},      # the transcript from STT
    ],
)

ai_response = response.choices[0].message.content
print("AI response:", ai_response)
```

| Message | Content |
|---|---|
| `system` | The "you are a voice agent" prompt |
| `user` | `stt` — what the user actually said |

---

## 4. The chain so far

```
🎙️ ─►[STT]─► "Hi agent, how are you? My name is Jayanth"
                     │
                     ▼  + system prompt ("you are a voice agent")
              [ gpt-4.1-mini ]
                     │
                     ▼
        "Hello Jayanth, I'm doing great — how can I assist you today?"
                     │
                     ▼  (next: TTS → audio)
```

---

## 5. The `.env`

The LLM call needs `OPENAI_API_KEY`. Reuse the `.env` from a previous project:

```bash
cp ../langgraph_learning/.env ./.env
```

Then run:

```bash
cd voice_agent
python main.py
```

```
(speak: "Hi agent, how are you? My name is Jayanth.")
Processing audio...
AI response: Hello Jayanth, I'm doing great. Thank you for asking. How can I assist you today?
```

Two of three stages now work: **voice → text → reply text**. The reply is still printed, not spoken — TTS is next.

---

## 6. Common gotchas

> [!WARNING]
> **LLM-stage issues**

| Symptom | Cause | Fix |
|---|---|---|
| `AuthenticationError` | `.env` missing / not loaded | Copy `.env`, `load_dotenv()` early |
| Reply sounds robotic / too long | No voice-agent system prompt | Add the system prompt |
| Markdown/code in spoken reply | Model defaulting to text style | Instruct "respond as a voice agent" |
| Empty `stt` | STT failed upstream | Fix STT first ([[06 - Coding STT]]) |

---

## 7. Main takeaways

- Stage 2 is a **normal** `chat.completions.create` with the **STT text as the user message**.
- Add a **system prompt**: "you are a voice agent; your reply will be spoken" → keeps replies short and natural.
- It's plain text-to-text, so **any model** works (Gemini, Claude, GPT).
- Needs `OPENAI_API_KEY` via a copied `.env` + `load_dotenv()`.
- Now the chain does **voice → text → reply text**; TTS completes it.

---

## 8. Things I still want to figure out

- How to keep replies **concise** reliably (length limits, style rules)?
- Where to add **tool calling** in this stage (foreshadows [[09 - Voice-Enabling the Cursor Agent]])?
- Should the system prompt forbid **markdown** explicitly?
- Streaming the LLM output into TTS to cut latency?

---

## 9. Things to dig into

- **OpenAI chat completions**: https://platform.openai.com/docs/api-reference/chat
- **Prompting for spoken output** (brevity, no markdown).
- Cross-link: system prompts (Section 3).

---

## 10. Next up in this section

- [ ] [[08 - TTS and the Conversational Loop]] — speak the reply and loop the whole thing into a conversation.

---

## Related
- [[06 - Coding STT]] — stage 1 (produces the transcript).
- [[08 - TTS and the Conversational Loop]] — stage 3 + the loop.

## Sources
- [OpenAI chat completions](https://platform.openai.com/docs/api-reference/chat)
