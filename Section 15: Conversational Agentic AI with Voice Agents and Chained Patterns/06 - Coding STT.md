---
title: Coding STT
date: 2026-05-29
source: "Section 15 / Lecture 6"
type: lecture-notes
status: in-progress
section: "Section 15: Conversational Agentic AI with Voice Agents and Chained Patterns"
tags:
  - voice-agents
  - stt
  - speech-recognition
  - pyaudio
  - python
  - hands-on
related:
  - "[[05 - Chained Architecture]]"
  - "[[07 - Adding the LLM Completion]]"
---

# Coding STT

> [!NOTE]
> **TL;DR**
> Build stage 1 of the chain — capture the mic and transcribe it. Install the **`SpeechRecognition`** package, make a `Recognizer`, open the **microphone as the source**, call `adjust_for_ambient_noise` (noise cancellation), then `listen` for audio (pausing ~2s of silence ends a phrase). Transcribe with `r.recognize_google(audio)` and print it. On macOS the first run errors with **"Could not find PyAudio"** — fix by installing PortAudio (`brew install portaudio`) then `pip install pyaudio` (the docs flag this exact error). After that, whatever you speak comes back as text — STT works.

> [!NOTE]
> **Where this fits**
> Sixth note of **Section 15** — the first hands-on stage of the chained architecture from [[05 - Chained Architecture]]. [[07 - Adding the LLM Completion]] feeds this transcript to an LLM.

---

## 1. The package

STT is handled by the **`SpeechRecognition`** library — it converts speech into text and wraps several backends (Google, etc.).

```bash
pip install SpeechRecognition
pip freeze > requirements.txt
```

Project: a new `voice_agent/` folder with `main.py`.

---

## 2. The recognizer + microphone

```python
import speech_recognition as sr

def main():
    r = sr.Recognizer()                       # the thing that does STT

    with sr.Microphone() as source:           # access the mic
        r.adjust_for_ambient_noise(source)    # noise cancellation
        r.pause_threshold = 2                  # 2s silence = end of phrase

        print("Speak something...")
        audio = r.listen(source)              # capture audio

        print("Processing audio...")
        stt = r.recognize_google(audio)       # transcribe → text
        print("User said:", stt)

main()
```

| Piece | Purpose |
|---|---|
| `sr.Recognizer()` | The recognizer object (does the STT) |
| `with sr.Microphone() as source` | Grabs the system microphone as the input source |
| `adjust_for_ambient_noise(source)` | Calibrates out background noise |
| `pause_threshold = 2` | After ~2s of silence, treat the phrase as finished |
| `r.listen(source)` | Records the spoken audio |
| `r.recognize_google(audio)` | Transcribes audio → text (Google backend) |

> [!TIP]
> **Multiple STT backends**
> `recognize_google` is the easy default, but the library exposes other providers too. `adjust_for_ambient_noise` + a sensible `pause_threshold` matter a lot for clean transcripts — too short and it cuts you off, too long and it lags.

---

## 3. The flow

```
🎙️ mic ─► listen() ─► audio ─► recognize_google() ─► "hey there agent, how are you?"
            │
       (ends after ~2s silence)
```

---

## 4. The PyAudio gotcha (expected on first run)

The first run fails:

```
Could not find PyAudio; check installation
```

This is **expected** — `SpeechRecognition` needs **PyAudio** for microphone access, and PyAudio needs the **PortAudio** system library. The docs call out this exact error.

> [!WARNING]
> **Fix: install PortAudio, then PyAudio (macOS)**
> ```bash
> brew install portaudio
> pip install pyaudio
> ```
> On macOS, PortAudio must be present *before* PyAudio will build/install. (On Linux it's `sudo apt install portaudio19-dev` then `pip install pyaudio`; on Windows `pip install pyaudio` usually suffices.) After installing both, re-run — the mic works.

---

## 5. It works

After fixing PyAudio, run it:

```bash
cd voice_agent
python main.py
```

```
Speak something...
(speak: "hey there agent, how are you doing?")
Processing audio...
User said: hey there agent how are you doing
```

Whatever is spoken comes back as text → **STT is successful**. Stage 1 of the chain is done.

---

## 6. Common gotchas

> [!WARNING]
> **STT issues**

| Symptom | Cause | Fix |
|---|---|---|
| `Could not find PyAudio` | PyAudio/PortAudio missing | `brew install portaudio` → `pip install pyaudio` |
| Cuts off mid-sentence | `pause_threshold` too low | Raise it (e.g. 2s) |
| Picks up background noise | No ambient calibration | `adjust_for_ambient_noise(source)` |
| `recognize_google` errors | No internet (Google backend) | Check connection / use another backend |
| Mic not detected | Wrong/again-busy input device | Check OS mic permissions / device |

---

## 7. Main takeaways

- STT uses the **`SpeechRecognition`** package.
- Pattern: `Recognizer()` → `with sr.Microphone() as source` → `adjust_for_ambient_noise` → `listen` → `recognize_google`.
- `pause_threshold` (~2s) marks the end of a phrase.
- First run errors with **"Could not find PyAudio"** — install **PortAudio** then **PyAudio**.
- After that, spoken audio transcribes to text — **stage 1 done**.

---

## 8. Things I still want to figure out

- Can STT **stream** partial transcripts instead of waiting for the full phrase?
- How accurate is `recognize_google` vs **Whisper** for accents/noise?
- How to do **continuous** listening (wake word) rather than one-shot?
- Offline STT options (Whisper local, Vosk)?

---

## 9. Things to dig into

- **SpeechRecognition docs**: https://pypi.org/project/SpeechRecognition/
- **OpenAI Whisper** as an STT backend.
- **PyAudio / PortAudio** install per-OS.

---

## 10. Next up in this section

- [ ] [[07 - Adding the LLM Completion]] — feed the transcript to an LLM (the chain's middle stage).

---

## Related
- [[05 - Chained Architecture]] — where STT fits in the chain.
- [[07 - Adding the LLM Completion]] — the next stage.

## Sources
- [SpeechRecognition (PyPI)](https://pypi.org/project/SpeechRecognition/)
