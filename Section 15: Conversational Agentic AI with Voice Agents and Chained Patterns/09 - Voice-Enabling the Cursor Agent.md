---
title: Voice-Enabling the Cursor Agent
date: 2026-05-29
source: "Section 15 / Lecture 9"
type: lecture-notes
status: in-progress
section: "Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns"
tags:
  - voice-agents
  - chained
  - tool-calling
  - coding-agent
  - hands-on
related:
  - "[[08 - TTS and the Conversational Loop]]"
  - "[[05 - Building a CLI Coding Assistant]]"
---

# Voice-Enabling the Cursor Agent

> [!NOTE]
> **TL;DR**
> The chained pattern's real power: wrap **any existing tool-calling agent** with STT + TTS. Take the earlier Cursor-like coding agent (the one with file-creating tools that scaffolds projects) and make two swaps — its **input** stops being a typed `user_query` and instead comes from **STT** (`r.recognize_google(audio)`), and its **final output** is spoken via **`asyncio.run(tts(...))`** instead of printed. Everything in the middle — the agent loop, tool calls, file creation — is untouched. The result: *speak* "create a black-themed todo app in HTML/CSS/JS using all available tools," and the agent builds the files (`index.html`, `style.css`, `script.js`) and **talks back** about what it did. That's a chained voice-to-voice agent doing real work — the whole course, now hands-free.

> [!NOTE]
> **Where this fits**
> Ninth and final note of **Section 15**. It composes the voice loop from [[08 - TTS and the Conversational Loop]] with the tool-calling coding agent from [[05 - Building a CLI Coding Assistant]] (Section 7). The capstone of the section.

---

## 1. The idea: voice is just a wrapper

A tool-calling agent already does the hard part — reasoning and acting. To make it a *voice* agent, only the **edges** change:

```
BEFORE (text):  typed query ─►[ agent + tools ]─► printed output
AFTER (voice):  🎙️ STT ─────►[ agent + tools ]─► TTS 🔊
                              (unchanged middle)
```

> [!IMPORTANT]
> **The agent's brain doesn't change — only input and output**
> This is the chained architecture's payoff ([[05 - Chained Architecture]]): because the middle is a normal text LLM (with tools), bolting STT on the front and TTS on the back is all it takes. The user query "ultimately comes from an input" and the final output "gets converted back to audio" — swap those two and the existing agent becomes a voice agent.

---

## 2. Starting point — the existing coding agent

Reuse the Cursor-like agent from [[05 - Building a CLI Coding Assistant]]: a `while`-loop agent with **tools** (create file, run commands, etc.) that can scaffold projects. Copy it into the voice folder as `cursor.py`, keeping a backup of the original so it isn't disturbed.

What it has already:
- The tool definitions (file operations, etc.).
- The agent loop (LLM ↔ tool calls until done).
- A `messages` history.

---

## 3. Bring in the voice pieces

Pull the voice building blocks into `cursor.py` from the earlier `main.py`:

```python
import speech_recognition as sr
from openai import OpenAI, AsyncOpenAI
from openai.helpers import LocalAudioPlayer
import asyncio

client = OpenAI()              # for the agent's completions
async_client = AsyncOpenAI()   # for TTS

# the same tts() utility from note 08
async def tts(speech: str):
    async with async_client.audio.speech.with_streaming_response.create(
        model="gpt-4o-mini-tts",
        voice="coral",
        instructions="Speak clearly and helpfully.",
        input=speech,
        response_format="pcm",
    ) as response:
        await LocalAudioPlayer().play(response)
```

---

## 4. Swap 1 — input comes from STT

Where the agent used to read a typed `user_query`, capture and transcribe speech instead:

```python
r = sr.Recognizer()

with sr.Microphone() as source:
    r.adjust_for_ambient_noise(source)
    r.pause_threshold = 2

    while True:
        print("Speak something...")
        audio = r.listen(source)
        print("Processing audio...")
        user_query = r.recognize_google(audio)    # ← was a typed input
        # ... feed user_query into the existing agent loop ...
```

The `while True` agent loop now lives **inside** the microphone `source` block, so it keeps listening turn after turn.

---

## 5. Swap 2 — final output is spoken

Where the agent used to **print** its final answer, speak it:

```python
# instead of: print(result_content)
asyncio.run(tts(result_content))
```

That's the only output change. All the intermediate tool-calling and file creation stays exactly as it was.

---

## 6. The full shape

```
🎙️ "create a black-themed todo app..."
        │ STT
        ▼
┌─────────────────────────────────────┐
│  coding agent (unchanged):           │
│   • LLM decides actions              │
│   • calls tools → writes index.html, │
│     style.css, script.js             │
│   • loops until done                 │
└─────────────────────────────────────┘
        │ final reply text
        ▼ TTS
🔊 "Your black-theme todo app is ready — index.html, style.css, script.js created."
```

---

## 7. It works — building an app by voice

Run it and **speak** the request:

```bash
cd voice_agent
python cursor.py
```

```
You (spoken): Create a black-themed todo application using HTML, CSS and
              JavaScript, using all the available tools.
🔊 Agent: Your black-theme todo app is ready. I created index.html,
          style.css, and script.js — open index.html in your browser.
```

The agent actually **creates the files** via its tools, then speaks a summary. If something's missing (e.g. a file didn't get created), you can just **say** "I can't see index.html" and it fixes it — a fully conversational, hands-free coding session. It makes mistakes sometimes, like any agent, but the voice loop handles the back-and-forth naturally.

---

## 8. Common gotchas

> [!WARNING]
> **Voice-agent composition issues**

| Symptom | Cause | Fix |
|---|---|---|
| Edited the wrong file | Copied into the original agent by mistake | Keep a backup; work in `cursor.py` |
| Agent loop runs once | Loop placed outside the mic `source` block | Put `while True` inside `with sr.Microphone()` |
| No audio reply | Still `print`-ing the output | Replace with `asyncio.run(tts(...))` |
| STT/PyAudio errors | Mic deps missing | See [[06 - Coding STT]] (PortAudio + PyAudio) |
| TTS package error | `voice_helpers` not installed | `pip install openai[voice_helpers]` |
| Tools stop working | Accidentally removed tool wiring while editing | Keep the agent's middle untouched |

---

## 9. Main takeaways

- A tool-calling agent becomes a **voice agent** by changing only **input (STT)** and **output (TTS)**.
- The agent's **middle is untouched** — loop, tools, file creation all stay.
- Input: `r.recognize_google(audio)` replaces a typed query.
- Output: `asyncio.run(tts(result))` replaces `print`.
- Put the agent loop **inside** the microphone `source` block to keep listening.
- Result: build real projects (a todo app) **by voice**, with spoken responses.
- This is the chained architecture proving its flexibility — any agent → voice agent.

---

## 10. Things I still want to figure out

- How to **announce tool actions** aloud as they happen ("creating index.html…")?
- Handling **long agent outputs** in speech (summarize before TTS)?
- Adding **persistent memory** (Mem0) so the voice agent remembers across sessions?
- Wrapping a **LangGraph** workflow in the same voice shell?
- **Barge-in** so I can interrupt mid-response?

---

## 11. Things to dig into

- Cross-links: [[05 - Building a CLI Coding Assistant]] (the agent), [[08 - TTS and the Conversational Loop]] (the voice loop).
- **Streaming** STT/TTS to reduce latency in a long agent session.
- **Hands-on**: voice-enable the weather agent or a RAG bot the same way.

---

## 12. Section wrap-up

Section 15 built **conversational voice agents** end to end: why voice can't go straight into an LLM → the two architectures (S2S vs chained) → the three chained stages (STT → LLM → TTS) → a looping conversational AI → and finally **wrapping a real tool-calling agent in voice**. The takeaway: voice is an **interface layer** over the agentic skills from the whole course — master the chained pattern and any agent can speak and listen.

---

## Related
- [[08 - TTS and the Conversational Loop]] — the voice loop reused here.
- [[05 - Building a CLI Coding Assistant]] — the agent being voice-enabled.
- [[05 - Chained Architecture]] — the pattern this demonstrates.

## Sources
- [OpenAI voice agents](https://platform.openai.com/docs/guides/voice-agents)
- [OpenAI text-to-speech](https://platform.openai.com/docs/guides/text-to-speech)
