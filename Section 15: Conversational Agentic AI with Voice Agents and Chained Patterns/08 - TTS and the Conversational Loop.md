---
title: TTS and the Conversational Loop
date: 2026-05-29
source: "Section 15 / Lecture 8"
type: lecture-notes
status: in-progress
section: "Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns"
tags:
  - voice-agents
  - tts
  - openai
  - async
  - conversational-ai
  - hands-on
related:
  - "[[07 - Adding the LLM Completion]]"
  - "[[09 - Voice-Enabling the Cursor Agent]]"
---

# TTS and the Conversational Loop

> [!NOTE]
> **TL;DR**
> The final stage — turn the LLM's text into speech and play it. Use OpenAI's **TTS** model via the **`AsyncOpenAI`** client with **streaming**: `async with async_client.audio.speech.with_streaming_response.create(model="gpt-4o-mini-tts", voice="coral", instructions="speak cheerfully", input=text, response_format="pcm")` → stream into a **`LocalAudioPlayer`** (from `openai.helpers`) that plays it on the machine. Run it with `asyncio.run(tts(ai_response))`. Two install gotchas: the **`openai[voice_helpers]`** extra for `LocalAudioPlayer`. Finally, wrap everything in a **`while True`** loop and keep a **`messages` array** (with the system prompt seeded once, each turn appended) — and it becomes a real, memory-carrying **conversational AI** you can talk to continuously.

> [!NOTE]
> **Where this fits**
> Eighth note of **Section 15** — stage 3 of the chain plus the loop that makes it conversational. Completes the chained voice agent from [[05 - Chained Architecture]]. [[09 - Voice-Enabling the Cursor Agent]] reuses this to voice-enable a tool-calling agent.

---

## 1. TTS — the model

Text-to-speech needs a dedicated model. OpenAI offers TTS voices (and tools like ElevenLabs let you *clone* a voice). OpenAI's **openai.fm** playground lets you preview voices (Alloy, Coral, Nova, …) and tones (chill, professional, cowboy) — the voices sound natural and the **`instructions`** field controls tone.

```
reply text ─►[ TTS model + voice + instructions ]─► audio ─► 🔊
```

---

## 2. Async streaming client

For playback, use the **async** client and **stream** the audio as it's generated:

```python
from openai import AsyncOpenAI
from openai.helpers import LocalAudioPlayer
import asyncio

async_client = AsyncOpenAI()       # NOTE: AsyncOpenAI, not OpenAI
```

> [!IMPORTANT]
> **`AsyncOpenAI` is a different client**
> This is **not** the same `OpenAI()` used for the chat completion — it's the **asynchronous** client, needed for streaming audio playback. Both can coexist in one script (sync for chat, async for TTS).

---

## 3. The TTS utility function

```python
async def tts(speech: str):
    async with async_client.audio.speech.with_streaming_response.create(
        model="gpt-4o-mini-tts",
        voice="coral",
        instructions="Always speak in a cheerful manner, full of delight and happiness.",
        input=speech,
        response_format="pcm",
    ) as response:
        await LocalAudioPlayer().play(response)
```

| Param | Purpose |
|---|---|
| `model` | The TTS model |
| `voice` | Which voice (e.g. `coral`, `alloy`, `nova`) |
| `instructions` | **Tone** guidance (cheerful, professional, …) |
| `input` | The text to speak |
| `response_format` | Audio format — `pcm` (also `opus`, `aac`, `flac`, `wav`) |
| `with_streaming_response` | Stream chunks as they're generated |
| `LocalAudioPlayer().play(...)` | Plays the streamed audio on the machine |

`LocalAudioPlayer` comes from **`openai.helpers`** — a small helper that takes any audio response and plays it locally.

---

## 4. Running the TTS

```python
asyncio.run(tts(ai_response))
```

> [!WARNING]
> **Install the voice helpers extra**
> First run errors asking for a package. Install:
> ```bash
> pip install openai[voice_helpers]
> ```
> `LocalAudioPlayer` lives behind this extra. After installing, the agent actually **speaks** its reply.

Now the full chain works end to end:

```
🎙️ ─►[STT]─► text ─►[LLM]─► reply ─►[TTS + LocalAudioPlayer]─► 🔊 spoken reply
```

---

## 5. Making it conversational — the loop + history

A single round exits after speaking. Two changes make it a real conversation:

### a) Loop forever
```python
while True:
    # listen → STT → LLM → TTS, repeat
    ...
```

### b) Keep a `messages` history
Seed the **system prompt once**, then **append every turn** so the agent remembers context:

```python
messages = [
    {"role": "system", "content": system_prompt},   # seeded once
]

while True:
    # ... get stt ...
    messages.append({"role": "user", "content": stt})

    response = client.chat.completions.create(
        model="gpt-4.1-mini",
        messages=messages,                            # full history
    )
    ai_response = response.choices[0].message.content
    messages.append({"role": "assistant", "content": ai_response})

    await_tts = asyncio.run(tts(ai_response))
```

> [!TIP]
> **History gives memory within the conversation**
> By appending each user + assistant turn to `messages`, the agent recalls earlier context — ask "what is my name?" after introducing yourself and it answers correctly. (This is short-term, in-memory history — the Section 13 memory layer would add persistence across sessions.)

---

## 6. The result

```
You: Hi agent, how are you? My name is Jayanth.
🔊  Hello Jayanth, I'm doing great — how can I assist you today?
You: Can you tell me what my name is?
🔊  Your name is Jayanth.
```

A working **chained conversational voice AI**: speak → it transcribes → reasons (with history) → speaks back, in a loop.

---

## 7. Common gotchas

> [!WARNING]
> **TTS / loop issues**

| Symptom | Cause | Fix |
|---|---|---|
| Missing-package error on play | `voice_helpers` extra not installed | `pip install openai[voice_helpers]` |
| `LocalAudioPlayer` import fails | Wrong import path | `from openai.helpers import LocalAudioPlayer` |
| Used `OpenAI` for streaming | Need the async client | Use `AsyncOpenAI` for TTS |
| Agent forgets context | No `messages` history | Append each turn to `messages` |
| Program exits after one reply | No loop | Wrap in `while True` |
| Robotic / wrong tone | Default voice/instructions | Set `voice` + `instructions` |

---

## 8. Main takeaways

- TTS uses an OpenAI **TTS model** with a **`voice`** and tone **`instructions`**.
- Use the **`AsyncOpenAI`** client with **`with_streaming_response`** for playback.
- Play streamed audio via **`LocalAudioPlayer`** from `openai.helpers`.
- Install the **`openai[voice_helpers]`** extra for the player.
- Run with `asyncio.run(tts(text))`.
- Wrap in **`while True`** + a seeded **`messages`** history → a real conversational AI.
- History gives **in-conversation memory**; full chain = STT → LLM → TTS, looped.

---

## 9. Things I still want to figure out

- Can TTS **start speaking before** the full LLM reply is ready (stream both)?
- How to handle **barge-in** (user interrupts the agent mid-speech)?
- Best **voice/format** for latency vs quality (`pcm` vs `opus`)?
- Adding **persistent** memory (Mem0) so it remembers across sessions?
- Voice **cloning** (e.g. ElevenLabs) for a custom persona?

---

## 10. Things to dig into

- **OpenAI TTS**: https://platform.openai.com/docs/guides/text-to-speech
- **openai.fm** voice playground: https://www.openai.fm/
- **ElevenLabs** for voice cloning.
- Cross-link: Section 13 (persistent memory) to extend the in-loop history.

---

## 11. Next up in this section

- [ ] [[09 - Voice-Enabling the Cursor Agent]] — give a tool-calling coding agent a voice interface.

---

## Related
- [[07 - Adding the LLM Completion]] — the stage feeding TTS.
- [[05 - Chained Architecture]] — the pattern now fully built.
- [[09 - Voice-Enabling the Cursor Agent]] — reusing this loop with tools.

## Sources
- [OpenAI text-to-speech](https://platform.openai.com/docs/guides/text-to-speech)
- [openai.fm voice playground](https://www.openai.fm/)
